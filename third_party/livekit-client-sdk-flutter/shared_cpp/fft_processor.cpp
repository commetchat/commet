#include "fft_processor.h"
#include "math_extras.h"

#include <climits>
#include <string.h>

float LinearToDecibels(float linear) { return 20 * log10f(linear); }

void ApplyWindow(float *p, size_t n) {

  // Blackman window
  double alpha = 0.16;
  double a0 = 0.5 * (1 - alpha);
  double a1 = 0.5;
  double a2 = 0.5 * alpha;

  for (unsigned i = 0; i < n; ++i) {
    double x = static_cast<double>(i) / static_cast<double>(n);
    double window =
        a0 - a1 * cos(kTwoPiDouble * x) + a2 * cos(kTwoPiDouble * 2.0 * x);
    p[i] *= static_cast<float>(window);
  }
}

// Returns x if x is finite (not NaN or infinite), otherwise returns
// default_value
float EnsureFinite(float x, float default_value) {
  return std::isfinite(x) ? x : default_value;
}

float S16ToFloatV(int16_t v) {
  constexpr float kScaling = 1.f / 32768.f;
  return v * kScaling;
}

void S16ToFloat(const int16_t *src, size_t size, float *dest) {
  for (size_t i = 0; i < size; ++i)
    dest[i] = S16ToFloatV(src[i]);
}

FFTProcessor::FFTProcessor(int fftSize, double smoothing_time_constant)
    : fft_size_(kDefaultFFTSize),
      smoothing_time_constant_(kDefaultSmoothingTimeConstant) {
  fft_size_ = fftSize;
  if (smoothing_time_constant > 0.0 && smoothing_time_constant < 1.0) {
    smoothing_time_constant_ = smoothing_time_constant;
  }
  setup_ = std::make_unique<FFTSetup>(fft_size_);
  input_buffer_ = std::make_unique<std::vector<float>>(kInputBufferSize, 0.0f);
  pffft_work_ = std::make_unique<std::vector<float>>(fft_size_, 0.0f);
  complex_data_ = std::make_unique<std::vector<float>>(fft_size_, 0.0f);
  real_data_ = std::make_unique<std::vector<float>>(fft_size_ / 2, 0.0f);
  imag_data_ = std::make_unique<std::vector<float>>(fft_size_ / 2, 0.0f);
  magnitude_buffer_ = std::make_unique<std::vector<float>>(fft_size_ / 2, 0.0f);
}

FFTProcessor::~FFTProcessor() {}

void FFTProcessor::GetFloatFrequencyData(std::vector<float> &destination_array,
                                         double current_time) {

  if (current_time <= last_analysis_time_) {
    ConvertFloatToDb(destination_array);
    return;
  }

  // Time has advanced since the last call; update the FFT data.
  last_analysis_time_ = current_time;

  DoFFTAnalysis();

  ConvertFloatToDb(destination_array);
}

void FFTProcessor::WriteInput(const int16_t *input,
                              unsigned int frames_to_process) {
  // The audio thread writes input data here.
  std::vector<float> input_buffer(frames_to_process, 0.0f);
  S16ToFloat(input, frames_to_process, input_buffer.data());

  unsigned int write_index = GetWriteIndex();
  if (write_index + frames_to_process >= kInputBufferSize) {
    write_index = 0;
  }
  // Perform real-time analysis
  float *dest = input_buffer_->data() + write_index;
  memcpy(dest, input_buffer.data(), frames_to_process * sizeof(*dest));
  write_index += frames_to_process;

  SetWriteIndex(write_index);
}

void FFTProcessor::DoFFTAnalysis() {
  // Perform the FFT analysis here
  // This is a placeholder for the actual FFT analysis logic

  std::vector<float> temporary_buffer(fft_size_, 0.0f);
  float *input_buffer = input_buffer_->data();
  float *temp_p = temporary_buffer.data();

  // Take the previous fftSize values from the input buffer and copy into the
  // temporary buffer.
  unsigned write_index = GetWriteIndex();
  if (write_index < fft_size_) {
    memcpy(temp_p, input_buffer + write_index - fft_size_ + kInputBufferSize,
           sizeof(*temp_p) * (fft_size_ - write_index));
    memcpy(temp_p + fft_size_ - write_index, input_buffer,
           sizeof(*temp_p) * write_index);
  } else {
    memcpy(temp_p, input_buffer + write_index - fft_size_,
           sizeof(*temp_p) * fft_size_);
  }

  // Window the input samples.
  ApplyWindow(temp_p, fft_size_);

  // Do the analysis.
  ComputeFFT(temp_p, fft_size_);

  // Blow away the packed nyquist component.
  (*imag_data_)[0] = 0;

  // Normalize so than an input sine wave at 0dBfs registers as 0dBfs (undo FFT
  // scaling factor).
  const double magnitude_scale = 1.0 / fft_size_;

  // A value of 0 does no averaging with the previous result.  Larger values
  // produce slower, but smoother changes.
  const double k = ClampTo(smoothing_time_constant_, 0.0, 1.0);

  // Convert the analysis data from complex to magnitude and average with the
  // previous result.
  float *destination = magnitude_buffer_->data();
  size_t n = magnitude_buffer_->size();

  const float *real_p_data = real_data_->data();
  const float *imag_p_data = imag_data_->data();
  for (size_t i = 0; i < n; ++i) {
    std::complex<double> c(real_p_data[i], imag_p_data[i]);
    double scalar_magnitude = abs(c) * magnitude_scale;
    destination[i] = EnsureFinite(
        static_cast<float>(k * destination[i] + (1 - k) * scalar_magnitude), 0);
  }
}

bool FFTProcessor::ComputeFFT(const float *input, size_t numSamples) {

  if (pffft_work_->size() != fft_size_) {
    // Handle error
    return false;
  }

  pffft_transform_ordered(setup_->GetSetup(), input, complex_data_->data(),
                          pffft_work_->data(), PFFFT_FORWARD);

  unsigned len = fft_size_ / 2;

  // Split FFT data into real and imaginary arrays.  PFFFT transform already
  // uses the desired format; we just need to split out the real and imaginary
  // parts.

  const float *c = complex_data_->data();
  float *real = real_data_->data();
  float *imag = imag_data_->data();
  for (unsigned k = 0; k < len; ++k) {
    int index = 2 * k;
    real[k] = c[index];
    imag[k] = c[index + 1];
  }

  return true;
}

void FFTProcessor::ConvertFloatToDb(std::vector<float> &destination_array) {
  // Convert from linear magnitude to floating-point decibels.
  size_t source_length = magnitude_buffer_->size();
  size_t len = std::min(source_length, destination_array.size());
  if (len > 0) {
    const float *source = magnitude_buffer_->data();
    float *destination = destination_array.data();

    for (unsigned i = 0; i < len; ++i) {
      float linear_value = source[i];
      double db_mag = LinearToDecibels(linear_value);
      destination[i] = static_cast<float>(db_mag);
    }
  }
}
