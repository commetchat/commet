#ifndef AUDIO_VISUALIZER_H
#define AUDIO_VISUALIZER_H

#include "fft_processor.h"

#include <complex>
#include <iostream>
#include <vector>

class AudioVisualizer {
public:
  static constexpr double kDefaultSmoothingTimeConstant = 0.5;
  static constexpr int kDefaultBandsCount = 7;
  static constexpr float kDefaultMinFrequency = 10.0f;   // Hz
  static constexpr float kDefaultMaxFrequency = 8000.0f; // Hz
  static constexpr float kDefaultMinDb = -100.0f;
  static constexpr float kDefaultMaxDb = -30.0f;

public:
  AudioVisualizer(
      int bands_count = kDefaultBandsCount, bool is_centered = false,
      double smoothing_time_constant = kDefaultSmoothingTimeConstant,
      float min_frequency = kDefaultMinFrequency,
      float max_frequency = kDefaultMaxFrequency, float min_db = kDefaultMinDb,
      float max_db = kDefaultMaxDb);

  ~AudioVisualizer();

  bool Process(const int16_t *audioData, unsigned int numSamples,
               float sampleRate, std::vector<float> &output);

private:
  int bands_count_;
  bool is_centered_;
  float min_frequency_;
  float max_frequency_;
  float min_db_;
  float max_db_;
  double smoothing_time_constant_;
  std::vector<float> bands_;
  std::unique_ptr<FFTProcessor> fft_processor_;
};

#endif // AUDIO_VISUALIZER_H