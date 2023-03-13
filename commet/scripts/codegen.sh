#!/usr/bin/env bash
flutter pub get
flutter pub run intl_utils:generate

cd ./tiamat/tiamat
flutter pub get
flutter pub run build_runner build