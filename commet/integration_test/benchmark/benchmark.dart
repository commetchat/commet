import 'package:integration_test/integration_test.dart';
import 'benchmarks/timeline_viewer_benchmark.dart' as timeline;

main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  timeline.main();
}
