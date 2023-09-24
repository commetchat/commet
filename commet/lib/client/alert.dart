import 'package:commet/utils/notifying_list.dart';

enum AlertType { info, warning, critical }

class Alert {
  late String Function() _messageGetter;
  late String Function() _titleGetter;
  AlertType type;

  String get title => _titleGetter();
  String get message => _messageGetter();

  Alert(this.type,
      {required String Function() messageGetter,
      required String Function() titleGetter}) {
    _messageGetter = messageGetter;
    _titleGetter = titleGetter;
  }
}

class AlertManager {
  final NotifyingList<Alert> _alerts = NotifyingList.empty(growable: true);

  Stream<int> get onAlertAdded => _alerts.onAdd;

  Stream<int> get onAlertRemoved => _alerts.onRemove;

  List<Alert> get alerts => _alerts;

  void addAlert(Alert alert) {
    _alerts.add(alert);
  }

  void clearAlert(Alert alert) {
    _alerts.remove(alert);
  }
}
