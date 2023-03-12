#!/usr/bin/env bash
flutter test unit_test -d linux --dart-define=HOMESERVER=$HOMESERVER --dart-define=BUILD_MODE=release --dart-define=USER1_NAME=$USER1_NAME --dart-define=USER1_PW=$USER1_PW