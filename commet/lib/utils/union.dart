import 'dart:collection';

class Union<T> {
  final HashSet<T> _items = HashSet<T>();
  final List<T> _ordered = List.empty(growable: true);

  void Function(int index)? _onChange;
  void Function(int index)? _onInsert;
  void Function(int index)? _onRemove;

  void addItems(List<T> items) {
    bool changed = false;

    for (var item in items) {
      if (!_items.contains(item)) {
        _items.add(item);
        _ordered.add(item);
        changed = true;
        _onInsert?.call(_items.length - 1);
      }
    }

    if (changed) {
      _onChange?.call(0);
    }
  }

  List<T> getItems({
    void Function(int index)? onChange,
    void Function(int index)? onRemove,
    void Function(int insertID)? onInsert,
  }) {
    addListeners(onChange: onChange, onRemove: onRemove, onInsert: onInsert);

    return _ordered;
  }

  void addListeners({
    void Function(int index)? onChange,
    void Function(int index)? onRemove,
    void Function(int insertID)? onInsert,
  }) {
    if (onChange != null) _onChange = onChange;
    if (onRemove != null) _onRemove = onRemove;
    if (onInsert != null) _onInsert = onInsert;
  }
}
