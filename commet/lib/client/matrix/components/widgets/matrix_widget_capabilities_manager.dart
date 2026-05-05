import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_download_file.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_receive_event.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_send_event.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_upload_file.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixWidgetCapabilitiesManager
    implements WidgetCapabilityManager<MatrixWidgetMessage> {
  Map<String, MatrixWidgetCapability> grantedCapabilities = {};
  Set<String> rejectedCapabilities = {};
  MatrixWidgetRunner runner;

  MatrixWidgetCapabilitiesManager({required this.runner});

  @override
  Future<List<String>> requestCapabilities(List<String> capabilities) async {
    var picked = await AdaptiveDialog.pickMultiple(navigator.currentContext!,
        title: "Widget Permissions",
        items: capabilities,
        itemBuilder: (context, i) => tiamat.Text.label(i));

    if (picked == null) return [];

    for (var i in capabilities) {
      if (picked.contains(i) == false &&
          rejectedCapabilities.contains(i) == false) {
        rejectedCapabilities.add(i);
      }
    }

    var granted = grantCapabilities(picked);

    runner.messageTransport.send(runner.eventHandler.generateToWidgetEvent(
        action: "notify_capabilities",
        data: {
          "requested": capabilities,
          "approved": grantedCapabilities.keys.toList()
        }));

    return granted;
  }

  (String, String?, String?) parseCapability(String name) {
    var split = name.split((":"));
    var parsedName = split.first;

    String? eventType;
    String? eventKey;

    if (split.length >= 2) {
      var eventTypeSplit = split[1].split("#");

      eventType = eventTypeSplit.first;

      if (eventTypeSplit.length >= 2) {
        eventKey = eventTypeSplit.sublist(1).join("#");
      }
    }

    return (parsedName, eventType, eventKey);
  }

  List<String> grantCapabilities(List<String> capabilities) {
    Log.i("Granting capabilities: $capabilities");
    List<String> granted = List.empty(growable: true);

    var builders =
        <String, MatrixWidgetCapability Function(String? type, String? key)>{
      "org.matrix.msc4039.upload_file": (_, __) =>
          MatrixCapabilityUploadFile(runner),
      "org.matrix.msc4039.download_file": (_, __) =>
          MatrixCapabilityDownloadFile(runner),
      "org.matrix.msc2762.receive.event": (type, key) =>
          MatrixCapabilityReceiveEvent(
              runner: runner, eventType: type!, eventKey: key),
      "org.matrix.msc2762.send.event": (type, key) => MatrixCapabilitySendEvent(
          runner: runner, eventType: type!, eventKey: key),
    };

    for (var name in capabilities) {
      if (grantedCapabilities.containsKey(name)) continue;

      var (capability, eventType, eventKey) = parseCapability(name);

      if (builders.containsKey(capability)) {
        grantedCapabilities[name] = builders[capability]!(eventType, eventKey);
        granted.add(name);
        rejectedCapabilities.remove(name);
      }
    }

    Log.i("Successfully granted capabilities: $granted");

    Log.i("Capabilities: $grantedCapabilities");

    return granted;
  }

  String eventToCapabilityName(MatrixWidgetMessage event) {
    var key = event.action;

    if (event.action == "send_event") {
      var eventType = event.data.tryGet<String>("type");
      var content = event.data.tryGetMap<String, dynamic>("content");
      var msgtype = content?.tryGet<String>("msgtype");

      if (eventType != null) {
        key = MatrixCapabilitySendEvent.getNameForType(eventType, msgtype);
      }
    }

    return key;
  }

  @override
  void handleEvent(MatrixWidgetMessage event) {
    var key = eventToCapabilityName(event);

    if (rejectedCapabilities.contains(key)) {
      Log.e("Widget requested rejected capability: $key");
      return;
    }

    for (var capability in grantedCapabilities.values) {
      if (capability.canHandleRequest(event) == true) {
        capability.handleRequest(event);
        return;
      }
    }

    Log.e("Unhandled widget request $event");
  }
}
