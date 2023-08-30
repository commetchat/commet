#!/usr/bin/env bash
mkdir lib/generated/l10n
flutter pub run intl_translation:generate_from_arb $(find lib/ -name '*.dart') assets/l10n/*.arb --output-dir=lib/generated/l10n