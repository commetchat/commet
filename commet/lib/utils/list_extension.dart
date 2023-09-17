extension ListExtension<T> on List<T> {
  T? tryFirstWhere(bool Function(T element) test) {
    try {
      return firstWhere(
        test,
      );
    } catch (exception) {
      return null;
    }
  }
}
