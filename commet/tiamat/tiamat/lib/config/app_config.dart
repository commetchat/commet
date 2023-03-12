library config;

import 'package:flutter/material.dart';

ValueNotifier<double> uiScale = ValueNotifier<double>(1);

double s(double value) {
  return value * uiScale.value;
}

void setUiScale(double value) {
  uiScale.value = value;
}

double getUiScale() {
  return uiScale.value;
}
