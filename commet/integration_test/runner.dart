// This file is a workaround for the issue: https://github.com/flutter/flutter/issues/101031

import 'package:integration_test/integration_test.dart';
import 'matrix/login_test.dart' as login_test;
import 'matrix/key_verification_test.dart' as key_verification_test;
import 'matrix/create_space_test.dart' as create_space_test;
import 'matrix/multi_account_test.dart' as multi_account_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  login_test.main();
  key_verification_test.main();
  create_space_test.main();
  multi_account_test.main();
}
