import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_always_on_screen.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_delayed_events.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_download_file.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_get_media_config.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_oidc.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_read_relations.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_receive_event.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_receive_state.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_receive_to_device.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_send_event.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_send_state.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_send_to_device.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_sticky_events.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_timeline.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_turn_servers.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_upload_file.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:matrix/matrix.dart' as matrix;

typedef MatrixWidgetCapability MatrixCapabilityConstructor(
    MatrixWidgetRunner runner, String? type, String? key);

typedef MatrixWidgetCapabilityConstructorEntry
    = MapEntry<String, MatrixCapabilityConstructor>;

class MatrixWidgetCapabilitiesManager
    implements WidgetCapabilityManager<MatrixWidgetMessage> {
  Map<String, MatrixWidgetCapability> grantedCapabilities = {};
  Set<String> rejectedCapabilities = {};

  @override
  NotifyingList<String> grantedCapabilityNames =
      NotifyingList.empty(growable: true);

  MatrixWidgetRunner runner;
  final BuildContext context;

  MatrixWidgetCapabilitiesManager(
      {required this.runner, required this.context});

  static const List<String> defaultCapabilities = const [
    // It is safe to allow this by default, as the implementation will only return events
    // for which the corresponding capability has already been granted
    MatrixCapabilityReadEventRelations.name,
    MatrixCapabilityGetMediaConfig.name,
    MatrixCapabilityOIDC.name,
  ];

  @override
  Future<List<String>> requestCapabilities(List<String> capabilities) async {
    var items = Set<String>.from(capabilities);

    var picked = await AdaptiveDialog.pickMultiple(navigator.currentContext!,
        title: "Widget Permissions",
        items: items.toList(),
        selected: items.toList(),
        itemBuilder: (context, i) => tiamat.Text.label(i));

    if (picked == null) return [];

    for (var defaultcapability in defaultCapabilities) {
      if (picked.contains(defaultcapability) == false) {
        picked.add(defaultcapability);
      }
    }

    for (var i in capabilities) {
      if (picked.contains(i) == false &&
          rejectedCapabilities.contains(i) == false) {
        rejectedCapabilities.add(i);
      }
    }

    var granted = grantCapabilities(picked);

    notifyCapabilities(capabilities);

    return granted;
  }

  void notifyCapabilities(List<String> requested) {
    List<String> approved =
        List.from(grantedCapabilities.keys.toList(), growable: true);
    if (approved.contains("io.element.requires_client") == false) {
      approved.add("io.element.requires_client");
    }

    runner.messageTransport.send(runner.eventHandler.generateToWidgetEvent(
        action: "notify_capabilities",
        data: {"requested": requested, "approved": approved}));
  }

  (String, String?, String?) parseCapability(String name) {
    var split = name.split((":"));
    var parsedName = split.first;

    String? eventType;
    String? eventKey;

    var splitRemainder = split.sublist(1).join(":");

    var eventTypeSplit = splitRemainder.split("#");

    eventType = eventTypeSplit.first;

    if (eventType.endsWith("#")) {
      eventKey = "";
    }

    if (eventTypeSplit.length >= 2) {
      eventKey = eventTypeSplit.sublist(1).join("#");
    }

    return (parsedName, eventType, eventKey);
  }

  List<String> grantCapabilities(List<String> capabilities) {
    Log.i("Granting capabilities: $capabilities");
    List<String> granted = List.empty(growable: true);

    var builders = Map.fromEntries([
      MatrixCapabilityReceiveEvent.entry,
      MatrixCapabilitySendEvent.entry,
      MatrixCapabilityUploadFile.entry,
      MatrixCapabilityDownloadFile.entry,
      MatrixCapabilitySendStateEvent.entry,
      MatrixCapabilityReceiveStateEvent.entry,
      MatrixCapabilitySendToDeviceEvent.entry,
      MatrixCapabilityReceiveToDeviceEvent.entry,
      MatrixCapabilityTurnServers.entry,
      MatrixCapabilityGetMediaConfig.entry,
      MatrixCapabilityOIDC.entry,
      MatrixCapabilityReadEventRelations.entry,
      MatrixCapabilityTimeline.entry,
      MatrixCapabilityAlwaysOnScreen.entry,
      // MatrixCapabilitySendDelayedEvent.entry,
      // MatrixCapabilityUpdateDelayedEvent.entry,
      // MatrixCapabilitySendStickyEvent.entry,
      // MatrixCapabilityReceiveStickyEvent.entry,
    ]);

    for (var name in capabilities) {
      if (grantedCapabilities.containsKey(name)) continue;

      var (capability, eventType, eventKey) = parseCapability(name);

      if (builders.containsKey(capability)) {
        var created = builders[capability]!(runner, eventType, eventKey);
        grantedCapabilities[name] = created;
        granted.add(name);

        grantedCapabilityNames.add(created.toString());

        rejectedCapabilities.remove(name);
      }
    }

    Log.i("Successfully granted capabilities:");
    for (var g in granted) {
      Log.i(g);
    }

    Log.w("Rejected Capabilities:");
    for (var g in rejectedCapabilities) {
      Log.i(g);
    }

    var unknown = capabilities.where((i) =>
        grantedCapabilities.containsKey(i) == false &&
        rejectedCapabilities.contains(i) == false);

    Log.w("Unhandled Capabilities");
    for (var g in unknown) {
      Log.i(g);
    }

    granted.addAll(unknown);

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

  bool canWidgetReadEvent(matrix.MatrixEvent event) {
    var msgType = event.content.tryGet<String>("msgtype");

    var mockAction = MatrixWidgetMessage(
      api: "fromWidget",
      action: "org.matrix.msc2876.read_events",
      widgetId: runner.widgetId,
      requestId: "fake",
      data: {
        "type": event.type,
        if (msgType != null) "msgtype": msgType,
        if (event.stateKey != null) "state_key": event.stateKey
      },
    );

    for (var capability in grantedCapabilities.values) {
      if (capability.canHandleRequest(mockAction) == true) {
        return true;
      }
    }

    return false;
  }

  bool canWidgetReadEventType(matrix.Event event) {
    return canWidgetReadEvent(event);
  }

  @override
  Future<MatrixWidgetMessage> handleEvent(MatrixWidgetMessage event) async {
    var key = eventToCapabilityName(event);

    if (rejectedCapabilities.contains(key)) {
      return event.createResponseError(message: "Rejected");
    }

    for (var capability in grantedCapabilities.values) {
      if (capability.canHandleRequest(event) == true) {
        try {
          var response = await capability.handleRequest(event);
          return response;
        } catch (e, s) {
          Log.onError(e, s, content: "Error handling widget message: $event");
          return event.createResponseError(message: "Unknown error occurred");
        }
      }
    }

    return event.createResponseError(
        message: "Unhandled widget request ${event.action}\n${event.data}");
  }

  @override
  void dispose() {
    for (var capability in grantedCapabilities.values) {
      capability.dispose();
    }

    grantedCapabilities.clear();
    grantedCapabilityNames.clear();
  }
}
