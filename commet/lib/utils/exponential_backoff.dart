import 'package:commet/debug/log.dart';

Future<T?> exponentialBackoff<T>(Future<T> Function() callback,
    {Duration maxDelay = const Duration(seconds: 30),
    int maxRetries = 20}) async {
  var delay = Duration(milliseconds: 500);

  Log.d("Starting exponential backoff");

  for (int i = 0; i < maxRetries; i++) {
    try {
      var result = await callback();
      Log.d("Success!");
      return result;
    } catch (e) {
      delay = delay * 2;

      Log.d("Waiting ${delay.inMilliseconds}ms then retrying");

      await Future.delayed(delay);

      if (delay.inMilliseconds > maxDelay.inMilliseconds) {
        delay = maxDelay;
      }
    }
  }

  return null;
}
