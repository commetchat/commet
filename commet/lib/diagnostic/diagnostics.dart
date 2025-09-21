import 'package:commet/main.dart';

class CumulativeMeasurement {
  int numCalls = 0;
  Duration totalDuration = Duration.zero;
  String name = "";
}

class CumulativeDiagnostics {
  CumulativeDiagnostics(this.name);

  String name;
  Map<String, CumulativeMeasurement> measurements = {};

  T time<T>(String name, T Function() func) {
    if (!preferences.developerMode) return func();
    Stopwatch s = Stopwatch();

    s.start();

    var result = func();

    s.stop();

    addResult(name, s.elapsed);
    return result;
  }

  Future<T> timeAsync<T>(String name, Future<T> Function() func) async {
    if (!preferences.developerMode) return func();

    Stopwatch s = Stopwatch();
    s.start();

    var result = await func();

    s.stop();
    addResult(name, s.elapsed);
    return result;
  }

  void addResult(String name, Duration elapsed) {
    var m = measurements[name] ?? CumulativeMeasurement();
    m.numCalls += 1;
    m.totalDuration += elapsed;
    m.name = name;
    measurements[name] = m;
  }
}

class Diagnostics {
  static bool _isPostInit = false;

  static void setPostInit() {
    _isPostInit = true;
  }

  static CumulativeDiagnostics initialLoadDatabaseDiagnostics =
      CumulativeDiagnostics("Initial Load Database Diagnostics");

  static CumulativeDiagnostics postLoadDatabaseDiagnostics =
      CumulativeDiagnostics("Post Load Database Diagnostics");

  static CumulativeDiagnostics general = CumulativeDiagnostics("General");

  static CumulativeDiagnostics get databaseDiagnostics => _isPostInit
      ? postLoadDatabaseDiagnostics
      : initialLoadDatabaseDiagnostics;
}
