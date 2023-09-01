// This file is a workaround for the issue: https://github.com/flutter/flutter/issues/101031

import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'generated/l10n.dart';
import 'matrix/login_test.dart' as login_test;
import 'matrix/key_verification_test.dart' as key_verification_test;
import 'matrix/create_space_test.dart' as create_space_test;
import 'matrix/multi_account_test.dart' as multi_account_test;
import 'matrix/change_space_name_test.dart' as change_space_name_test;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await T.load(const Locale("en"));
  await preferences.init();

  login_test.main();
  key_verification_test.main();
  create_space_test.main();
  multi_account_test.main();
  change_space_name_test.main();
}
