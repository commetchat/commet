#!/usr/bin/env bash
flutter pub get

# This generated type safe string binding for use in integration test
flutter pub run intl_utils:generate

# Generate translation files for use in actual code
mkdir lib/generated/l10n
flutter pub run intl_translation:generate_from_arb $(find lib/ -name '*.dart') assets/l10n/*.arb --output-dir=lib/generated/l10n

flutter pub run build_runner build