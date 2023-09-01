#!/usr/bin/env bash
flutter pub run intl_translation:extract_to_arb  --output-file=intl_en.arb --output-dir=./assets/l10n/ $(find lib/ -name '*.dart') 