import 'package:reflectable/src/reflectable_builder_based.dart' as builder;

class ReflectableExtensions {
  static Object? invoke(dynamic object, String name) {
    var getter = builder.data.values.first.getters[name]!;
    var result = getter(object);
    return result;
  }
}
