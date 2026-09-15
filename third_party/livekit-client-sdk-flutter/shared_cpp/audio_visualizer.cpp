#include "audio_visualizer.h"

#include <algorithm>
#include <chrono>

double CurrentTime() {
  return static_cast<double>(
             std::chrono::duration_cast<std::chrono::milliseconds>(
                 std::chrono::system_clock::now().time_since_epoch())
                 .count()) /
         1000.0;
}

int magnitudeIndex(std::vector<float> magnitudes, float frequency,
                   float sampleRate) {
  return static_cast<int>(float(magnitudes.size()) * frequency / sampleRate /
                          2);
}

std::vector<float> computeBands(std::vector<float> magnitudes,
                                float minFrequency, float maxFrequency,
                                int bandsCount, float sampleRate) {
  float actualMaxFrequency = std::min(sampleRate / 2, maxFrequency);
  std::vector<float> bandMagnitudes(bandsCount, 0.0f);

  int magLowerRange = magnitudeIndex(magnitudes, minFrequency, sampleRate);
  int magUpperRange =
      magnitudeIndex(magnitudes, actualMaxFrequency, sampleRate);
  float ratio = float(magUpperRange - magLowerRange) / float(bandsCount);

  for (int i = 0; i < bandsCount; ++i) {
    int magsStartIdx =
        static_cast<int>(floorf(float(i) * ratio)) + magLowerRange;
    int magsEndIdx =
        static_cast<int>(floorf(float(i + 1) * ratio)) + magLowerRange;

    int count = magsEndIdx - magsStartIdx;
    if (count > 0) {
      float sum = 0;
      for (int j = magsStartIdx; j < magsEndIdx; ++j) {
        sum += magnitudes[j];
      }
      bandMagnitudes[i] = sum / float(count);
    } else {
      bandMagnitudes[i] = magnitudes[magsStartIdx];
    }
  }

  return bandMagnitudes;
}

/// Centers the sorted bands by placing higher values in the middle.
std::vector<float> centerBands(const std::vector<float> &sortedBands) {
  std::vector<float> centeredBands(sortedBands.size(), 0);
  size_t leftIndex = sortedBands.size() / 2;
  size_t rightIndex = leftIndex;

  for (size_t index = 0; index < sortedBands.size(); ++index) {
    if (index % 2 == 0) {
      // Place value to the right
      centeredBands[rightIndex] = sortedBands[index];
      rightIndex += 1;
    } else {
      // Place value to the left
      leftIndex -= 1;
      centeredBands[leftIndex] = sortedBands[index];
    }
  }

  return centeredBands;
}

AudioVisualizer::AudioVisualizer(int bands_count, bool is_centered,
                                 double smoothing_time_constant,
                                 float min_frequency, float max_frequency,
                                 float min_db, float max_db)
    : bands_count_(bands_count), is_centered_(is_centered),
      min_frequency_(min_frequency), max_frequency_(max_frequency),
      min_db_(min_db), max_db_(max_db),
      smoothing_time_constant_(smoothing_time_constant),
      bands_(bands_count, 0.0f),
      fft_processor_(std::make_unique<FFTProcessor>(
          FFTProcessor::kDefaultFFTSize, smoothing_time_constant_)) {}

AudioVisualizer::~AudioVisualizer() {}

bool AudioVisualizer::Process(const int16_t *audioData, unsigned int numSamples,
                              float sampleRate, std::vector<float> &output) {

  fft_processor_->WriteInput(audioData, numSamples);
  std::vector<float> magnitudes(FFTProcessor::kDefaultFFTSize / 2, 0.0f);
  fft_processor_->GetFloatFrequencyData(magnitudes, CurrentTime());

  auto bands = computeBands(magnitudes, min_frequency_, max_frequency_,
                            bands_count_, sampleRate);

  for (int i = 0; i < bands.size(); ++i) {
    float db = 1.0f - (fmax(min_db_, fmin(max_db_, bands[i])) * -1.0f) / 100.0f;
    db = std::sqrt(db);
    bands_[i] = db;
  }

  if (is_centered_) {
    std::sort(bands_.begin(), bands_.end(), std::greater<float>());
    bands_ = centerBands(bands_);
  }

  output = bands_;

  return true;
}
