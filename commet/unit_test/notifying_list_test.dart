import 'package:commet/utils/notifying_list.dart';
import 'package:test/test.dart';

void main() async {
  NotifyingList<int> list = NotifyingList.empty(growable: true, sync: true);

  bool addedCalled = false;
  bool itemUpdatedCalled = false;
  bool removedCalled = false;
  bool listUpdatedCalled = false;

  void resetFlags() {
    addedCalled = false;
    itemUpdatedCalled = false;
    removedCalled = false;
    listUpdatedCalled = false;
  }

  list.onAdd.listen(
    (event) => addedCalled = true,
  );

  list.onItemUpdated.listen(
    (event) => itemUpdatedCalled = true,
  );

  list.onListUpdated.listen(
    (event) => listUpdatedCalled = true,
  );

  list.onRemove.listen(
    (event) => removedCalled = true,
  );

  test("Add", () {
    resetFlags();
    list.add(1);

    expect(addedCalled, isTrue);
    expect(removedCalled, isFalse);
    expect(itemUpdatedCalled, isFalse);
    expect(listUpdatedCalled, isTrue);
  });

  test("Remove", () {
    resetFlags();
    list.remove(1);

    expect(addedCalled, isFalse);
    expect(removedCalled, isTrue);
    expect(itemUpdatedCalled, isFalse);
    expect(listUpdatedCalled, isTrue);
  });

  test("Insert", () {
    resetFlags();
    list.insert(0, 2);

    expect(addedCalled, isTrue);
    expect(removedCalled, isFalse);
    expect(itemUpdatedCalled, isFalse);
    expect(listUpdatedCalled, isTrue);
  });

  test("Remove At", () {
    resetFlags();
    list.removeAt(0);

    expect(addedCalled, isFalse);
    expect(removedCalled, isTrue);
    expect(itemUpdatedCalled, isFalse);
    expect(listUpdatedCalled, isTrue);
  });

  test("Remove Where", () {
    list.add(1234);
    resetFlags();

    list.removeWhere((element) => element == 1234);

    expect(addedCalled, isFalse);
    expect(removedCalled, isTrue);
    expect(itemUpdatedCalled, isFalse);
    expect(listUpdatedCalled, isTrue);
  });

  test("Indexing", () {
    list.add(0);
    resetFlags();

    list[0] = 45;

    expect(addedCalled, isFalse);
    expect(removedCalled, isFalse);
    expect(itemUpdatedCalled, isTrue);
    expect(listUpdatedCalled, isTrue);
  });
}
