import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
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
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_theme.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_timeline.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_turn_servers.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/mx_capability_upload_file.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_permission_groups.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_permissions_view.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
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
      {required this.runner, required this.context}) {
    runner.onClosed.listen((_) {
      dispose();
    });
  }

  static const List<String> defaultCapabilities = const [
    // It is safe to allow this by default, as the implementation will only return events
    // for which the corresponding capability has already been granted
    MatrixCapabilityReadEventRelations.name,
    MatrixCapabilityGetMediaConfig.name,

    MatrixCapabilityTheme.name,

    // Usages of this capability present their own permission prompt, so its fine to allow by default
    MatrixCapabilityOIDC.name,
  ];

  @override
  Future<List<String>> requestCapabilities(List<String> capabilities) async {
    var needsPermission = List<String>.from(capabilities, growable: true);

    List<String> allowed = List.empty(growable: true);

    var rejected = await preferences.getRejectedWidgetCapabilities(
        runner.client.identifier, runner.info.namespace);
    var accepted = await preferences.getAcceptedWidgetCapabilities(
        runner.client.identifier, runner.info.namespace);

    for (var c in rejected) {
      needsPermission.remove(c);
    }

    for (var c in accepted) {
      needsPermission.remove(c);
      allowed.add(c);
    }

    for (var defaultcapability in defaultCapabilities) {
      Log.i(
        "Allowing capability by default: $defaultcapability",
      );

      allowed.add(defaultcapability);
      needsPermission.remove(defaultcapability);
    }

    for (var capability in needsPermission.toList()) {
      if (canCreateCapability(capability) == false) {
        needsPermission.remove(capability);

        runner.logs.add(LogEntry(LogType.error,
            "Cannot handle capability: $capability, rejecting by default"));

        Log.w("Cannot handle capability: $capability, rejecting by default");
        if (rejectedCapabilities.contains(capability) == false) {
          rejectedCapabilities.add(capability);
        }
      }
    }

    if (needsPermission.isNotEmpty) {
      var groups =
          MatrixWidgetPermissionGroup.groupPermissions(needsPermission);

      var picked = await AdaptiveDialog.show<DialogResult<List<String>>>(
        context,
        title: "Widget Permissions",
        builder: (context) => MatrixWidgetPermissionsView(
            runner: runner,
            groupedPermissions: groups.$1,
            ungrouped: groups.$2),
      );

      if (picked != null) {
        Log.i("User allowed permissions: ${picked}");
        allowed.addAll(picked.value);
        var rejected = needsPermission
            .where((i) => picked.value.contains(i) == false)
            .toList();

        if (picked.remember) {
          preferences.allowWidgetCapabilityPermissions(
              runner.client.identifier, runner.info.namespace, picked.value);

          preferences.rejectWidgetCapabilityPermissions(
              runner.client.identifier, runner.info.namespace, rejected);
        }
      }
    }

    for (var i in capabilities) {
      if (allowed.contains(i) == false &&
          rejectedCapabilities.contains(i) == false) {
        rejectedCapabilities.add(i);
      }
    }

    var granted = grantCapabilities(allowed);

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

  static Map<String,
          MatrixWidgetCapability Function(MatrixWidgetRunner, String?, String?)>
      capabilityBuilders = Map.fromEntries([
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
    MatrixCapabilityTheme.entry,
    // MatrixCapabilityAlwaysOnScreen.entry,
    // MatrixCapabilitySendDelayedEvent.entry,
    // MatrixCapabilityUpdateDelayedEvent.entry,
    // MatrixCapabilitySendStickyEvent.entry,
    // MatrixCapabilityReceiveStickyEvent.entry,
  ]);

  static bool canCreateCapability(String capability) {
    var parsed = MatrixWidgetCapabilityString.parse(capability);

    if (capabilityBuilders.containsKey(parsed.capability)) {
      return true;
    }

    return false;
  }

  List<String> grantCapabilities(List<String> capabilities) {
    Log.i("Granting capabilities: $capabilities");
    List<String> granted = List.empty(growable: true);

    var builders = capabilityBuilders;

    for (var name in capabilities) {
      if (grantedCapabilities.containsKey(name)) continue;

      var parsed = MatrixWidgetCapabilityString.parse(name);

      if (builders.containsKey(parsed.capability)) {
        var created = builders[parsed.capability]!(
            runner, parsed.eventType, parsed.eventKey);
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
