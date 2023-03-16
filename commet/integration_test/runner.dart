// This file is a workaround for the issue: https://github.com/flutter/flutter/issues/101031

import 'package:integration_test/integration_test.dart';
import 'matrix/login_test.dart' as login_test;
import 'matrix/key_verification_test.dart' as key_verification_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  login_test.main();
  key_verification_test.main();
}
