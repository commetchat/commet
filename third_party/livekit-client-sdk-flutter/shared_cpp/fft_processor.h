#ifndef FFT_PROCESSOR_H
#define FFT_PROCESSOR_H

#include <atomic>
#include <complex>
#include <map>
#include <memory>
#include <unordered_map>
#include <vector>

#include "pffft.h"


class FFTProcessor {
protected:
  class FFTSetup {
  public:
    FFTSetup(unsigned fft_size) {
      setup_ = pffft_new_setup(fft_size, PFFFT_REAL);
    }

    ~FFTSetup() { pffft_destroy_setup(setup_); }

    PFFFT_Setup *GetSetup() const { return setup_; }

  private:
    PFFFT_Setup *setup_;
  };

public:
  static constexpr double kDefaultSmoothingTimeConstant = 0.5;
  static constexpr unsigned kDefaultFFTSize = 2048;
  // All FFT implementations are expected to handle power-of-two sizes
  // MinFFTSize <= size <= MaxFFTSize.
  static constexpr unsigned kMinFFTSize = 32;
  static constexpr unsigned kMaxFFTSize = 32768;
  static constexpr unsigned kInputBufferSize = kMaxFFTSize * 2;

public:
  FFTProcessor(int fftSize,
               double moothing_time_constant = kDefaultSmoothingTimeConstant);
  ~FFTProcessor();

  void WriteInput(const int16_t *, unsigned int frames_to_process);

  void GetFloatFrequencyData(std::vector<float> &destination_array,
                             double current_time);
private:
  void ConvertFloatToDb(std::vector<float> &destination_array);

  void DoFFTAnalysis();

  bool ComputeFFT(const float *input, size_t num_samples);

  unsigned GetWriteIndex() const {
    return write_index_.load(std::memory_order_acquire);
  }
  void SetWriteIndex(unsigned new_index) {
    write_index_.store(new_index, std::memory_order_release);
  }

private:
  unsigned int fft_size_;
  std::unique_ptr<std::vector<float>> pffft_work_;
  std::unique_ptr<std::vector<float>> complex_data_;
  std::unique_ptr<std::vector<float>> real_data_;
  std::unique_ptr<std::vector<float>> imag_data_;
  std::unique_ptr<std::vector<float>> magnitude_buffer_;
  std::unique_ptr<FFTSetup> setup_;
  // Time at which the FFT was last computed.
  double last_analysis_time_ = -1;

  // The audio thread writes the input audio here.
  std::unique_ptr<std::vector<float>> input_buffer_;
  std::atomic_uint write_index_{0};

  // A value between 0 and 1 which averages the previous version of
  // m_magnitudeBuffer with the current analysis magnitude data.
  double smoothing_time_constant_;

};

#endif // FFT_PROCESSOR_H