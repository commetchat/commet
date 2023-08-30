#!/usr/bin/env bash
flutter pub run intl_translation:generate_from_arb $(find lib/ -name '*.dart') assets/l10n/*.arb --output-dir=lib/l10n