import 'package:flutter/material.dart';

class MatrixWidgetCapabilityString {
  final String raw;
  final String capability;
  final String? eventType;
  final String? eventKey;

  MatrixWidgetCapabilityString(this.capability,
      {this.eventType, this.eventKey, required this.raw});

  static MatrixWidgetCapabilityString parse(String name) {
    var split = name.split((":"));
    var parsedName = split.first;

    String? eventType;
    String? eventKey;

    if (split.length == 1) {
      return MatrixWidgetCapabilityString(parsedName, raw: name);
    }

    var splitRemainder = split.sublist(1).join(":");

    var eventTypeSplit = splitRemainder.split("#");

    eventType = eventTypeSplit.first;

    if (eventType.endsWith("#")) {
      eventKey = "";
    }

    if (eventTypeSplit.length >= 2) {
      eventKey = eventTypeSplit.sublist(1).join("#");
    }

    return MatrixWidgetCapabilityString(parsedName,
        eventType: eventType, eventKey: eventKey, raw: name);
  }
}

enum WidgetPermissionSeverity {
  low,
  mild,
  high,
  critical,
}

class MatrixWidgetPermissionGroup {
  List<MatrixWidgetCapabilityString> permissions;

  String name;

  String description;

  WidgetPermissionSeverity severity;

  bool defaultValue;

  IconData icon;

  MatrixWidgetPermissionGroup({
    required this.name,
    required this.permissions,
    required this.severity,
    required this.defaultValue,
    required this.description,
    required this.icon,
  });

  static List<MatrixWidgetPermissionGroup> permissionGroups() {
    return [
      adminPowers(),
      modifyChats(),
      callPermissions(),
      readRoomInformation(),
      media(),
    ];
  }

  static (List<MatrixWidgetPermissionGroup>, List<MatrixWidgetCapabilityString>)
      groupPermissions(List<String> capabilities) {
    final templateGroups = permissionGroups();

    Map<String, MatrixWidgetPermissionGroup> groups = {};

    for (var template in templateGroups) {
      groups[template.name] = MatrixWidgetPermissionGroup(
          name: template.name,
          defaultValue: template.defaultValue,
          permissions: List.empty(growable: true),
          severity: template.severity,
          icon: template.icon,
          description: template.description);
    }

    groups["custom_events"] = MatrixWidgetPermissionGroup(
        name: "Custom Events",
        defaultValue: true,
        permissions: List.empty(growable: true),
        icon: Icons.code,
        severity: WidgetPermissionSeverity.low,
        description: "Send and receive custom event data");

    List<MatrixWidgetCapabilityString> ungrouped = List.empty(growable: true);

    for (var capability in capabilities) {
      var parsed = MatrixWidgetCapabilityString.parse(capability);

      bool grouped = false;

      for (var template in templateGroups) {
        if (template.permissions.any((i) =>
            i.capability == parsed.capability &&
            (i.eventType == null || i.eventType == parsed.eventType))) {
          groups[template.name]!.permissions.add(parsed);
          grouped = true;
          break;
        }
      }

      if (grouped == false) {
        if ([
          "org.matrix.msc2762.send.event",
          "org.matrix.msc2762.receive.event",
          "org.matrix.msc2762.send.state_event",
          "org.matrix.msc2762.receive.state_event",
          "org.matrix.msc3819.send.to_device",
          "org.matrix.msc3819.receive.to_device",
        ].contains(parsed.capability)) {
          if (parsed.eventType != null &&
              parsed.eventType!.startsWith("m.") == false) {
            groups["custom_events"]!.permissions.add(parsed);
            grouped = true;
          }
        }
      }

      if (!grouped) {
        ungrouped.add(parsed);
      }
    }

    return (
      groups.values.where((i) => i.permissions.isNotEmpty).toList(),
      ungrouped
    );
  }

  static MatrixWidgetPermissionGroup media() {
    return MatrixWidgetPermissionGroup(
        name: "Media",
        description: "Upload and download files from your homeserver",
        severity: WidgetPermissionSeverity.low,
        defaultValue: true,
        icon: Icons.file_copy_rounded,
        permissions: [
          "org.matrix.msc4039.upload_file",
          "org.matrix.msc4039.download_file"
        ].map((i) => MatrixWidgetCapabilityString.parse(i)).toList());
  }

  static MatrixWidgetPermissionGroup readRoomInformation() {
    return MatrixWidgetPermissionGroup(
        name: "Read Room Information",
        description:
            "Read information about the current room state, such as name and members",
        severity: WidgetPermissionSeverity.low,
        defaultValue: true,
        icon: Icons.tag,
        permissions: [
          "org.matrix.msc2762.receive.state_event:m.room.create",
          "org.matrix.msc2762.receive.state_event:m.room.name",
          "org.matrix.msc2762.receive.state_event:m.room.member",
          "org.matrix.msc2762.receive.state_event:m.room.encryption",
          "org.matrix.msc2762.receive.state_event:m.room.power_levels",
        ].map((i) => MatrixWidgetCapabilityString.parse(i)).toList());
  }

  static MatrixWidgetPermissionGroup modifyChats() {
    return MatrixWidgetPermissionGroup(
        name: "Manage Chat",
        description: "Read, send and delete messages in this room",
        defaultValue: false,
        icon: Icons.message_rounded,
        severity: WidgetPermissionSeverity.high,
        permissions: [
          "org.matrix.msc2762.send.event:m.room.redaction",
          "org.matrix.msc2762.receive.event:m.room.redaction",
          "org.matrix.msc2762.send.event:m.reaction",
          "org.matrix.msc2762.receive.event:m.reaction",
          "org.matrix.msc2762.send.event:m.room.message",
          "org.matrix.msc2762.timeline",
        ].map((i) => MatrixWidgetCapabilityString.parse(i)).toList());
  }

  static MatrixWidgetPermissionGroup adminPowers() {
    return MatrixWidgetPermissionGroup(
        name: "Admin Powers",
        description:
            "Change permissions and user roles / power levels.\nAdditional confirmation will be asked later, when the widget attempts to make changes",
        defaultValue: true,
        icon: Icons.security,
        severity: WidgetPermissionSeverity.mild,
        permissions: [
          "org.matrix.msc2762.send.state_event:m.room.power_levels",
        ].map((i) => MatrixWidgetCapabilityString.parse(i)).toList());
  }

  static MatrixWidgetPermissionGroup callPermissions() {
    return MatrixWidgetPermissionGroup(
        name: "Call Permissions",
        description: "Make, manage and join calls",
        icon: Icons.call_rounded,
        defaultValue: true,
        severity: WidgetPermissionSeverity.mild,
        permissions: [
          "org.matrix.msc2762.send.event:io.element.call.encryption_keys",
          "org.matrix.msc3819.receive.to_device:io.element.call.encryption_keys",
          "org.matrix.msc2762.send.event:io.element.call.reaction",
          "org.matrix.msc2762.send.event:org.matrix.msc4310.rtc.decline",
          "org.matrix.msc2762.send.event:org.matrix.msc4143.rtc.member",
          "org.matrix.msc2762.receive.event:io.element.call.encryption_keys",
          "org.matrix.msc2762.receive.event:io.element.call.reaction",
          "org.matrix.msc2762.receive.event:org.matrix.msc4310.rtc.decline",
          "org.matrix.msc2762.receive.event:org.matrix.msc4143.rtc.member",
          "org.matrix.msc2762.send.state_event:org.matrix.msc3401.call.member",
          "org.matrix.msc2762.receive.state_event:org.matrix.msc3401.call.member",
          "org.matrix.msc3819.send.to_device:m.call.invite",
          "org.matrix.msc3819.send.to_device:m.call.candidates",
          "org.matrix.msc3819.send.to_device:m.call.answer",
          "org.matrix.msc3819.send.to_device:m.call.hangup",
          "org.matrix.msc3819.send.to_device:m.call.reject",
          "org.matrix.msc3819.send.to_device:m.call.select_answer",
          "org.matrix.msc3819.send.to_device:m.call.negotiate",
          "org.matrix.msc3819.send.to_device:m.call.sdp_stream_metadata_changed",
          "org.matrix.msc3819.send.to_device:org.matrix.call.sdp_stream_metadata_changed",
          "org.matrix.msc3819.send.to_device:m.call.replaces",
          "org.matrix.msc3819.send.to_device:io.element.call.encryption_keys",
          "org.matrix.msc3819.receive.to_device:m.call.invite",
          "org.matrix.msc3819.receive.to_device:m.call.candidates",
          "org.matrix.msc3819.receive.to_device:m.call.answer",
          "org.matrix.msc3819.receive.to_device:m.call.hangup",
          "org.matrix.msc3819.receive.to_device:m.call.reject",
          "org.matrix.msc3819.receive.to_device:m.call.select_answer",
          "org.matrix.msc3819.receive.to_device:m.call.negotiate",
          "org.matrix.msc3819.receive.to_device:m.call.sdp_stream_metadata_changed",
          "org.matrix.msc3819.receive.to_device:org.matrix.call.sdp_stream_metadata_changed",
          "org.matrix.msc3819.receive.to_device:m.call.replaces",
          "org.matrix.msc2762.send.event:org.matrix.msc4075.call.notify",
          "org.matrix.msc2762.send.event:org.matrix.msc4075.rtc.notification",
          // Maybe these dont need to be in this category?
          "org.matrix.msc4157.send.delayed_event",
          "org.matrix.msc4157.update_delayed_event",
          "org.matrix.msc4407.send.sticky_event",
          "org.matrix.msc4407.receive.sticky_event",
        ].map((i) => MatrixWidgetCapabilityString.parse(i)).toList());
  }
}
