import 'dart:convert';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/notifying_list_builder.dart';
import 'package:commet/ui/pages/settings/categories/developer/log_page.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class WidgetDebugView extends StatelessWidget {
  const WidgetDebugView(this.runner, {super.key});
  final MatrixWidgetRunner runner;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyActions: false,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(
                text: "Messages",
              ),
              Tab(
                text: "Capabilities",
              ),
              Tab(
                text: "Logs",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            WidgetMessageDebugView(runner),
            WidgetCapabilitiesDebugView(runner),
            LogPage(runner.logs)
          ],
        ),
      ),
    );
  }
}

class WidgetCapabilitiesDebugView extends StatefulWidget {
  const WidgetCapabilitiesDebugView(this.runner, {super.key});
  final MatrixWidgetRunner runner;
  @override
  State<WidgetCapabilitiesDebugView> createState() =>
      _WidgetCapabilitiesDebugViewState();
}

class _WidgetCapabilitiesDebugViewState
    extends State<WidgetCapabilitiesDebugView> {
  @override
  Widget build(BuildContext context) {
    return NotifyingListBuilder(
      list: widget.runner.capabilities.grantedCapabilityNames,
      itemBuilder: (context, value) {
        return Padding(
            padding: EdgeInsetsGeometry.fromLTRB(0, 8, 0, 0),
            child: tiamat.Text.labelLow(value));
      },
    );
  }
}

class WidgetMessageDebugView extends StatefulWidget {
  const WidgetMessageDebugView(this.runner, {super.key});
  final MatrixWidgetRunner runner;

  @override
  State<WidgetMessageDebugView> createState() => _WidgetMessageDebugViewState();
}

class _WidgetMessageDebugViewState extends State<WidgetMessageDebugView> {
  final emoji =
      "😀😎🤖👻👽👹👺💀👾🎃🐶🐱🐸🐼🦄🐙🦋🦜🦚🦩🌵🌲🍀🍁🌻🌈☀️🌙⭐⚡🔥❄️🌊🍎🍋🍇🍉🥕🌽🍣🍩🍪🍰🍔🍟🌮🍕🍜🧋☕⚽🏀🎾🏈🎲🎯🎸🎺🥁🎻🚗🚕🚙🚌🚓🚑🚒🚜🚲🚀🏰🗼🗽⛩️🏕️🏝️🌋🗻🏜️🏟️💎🔮🧸🎁🕹️📸💡🧪🛸⏳❤️🧡💛💚💙💜🖤🤍🤎💖";

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return NotifyingListBuilder(
      list: widget.runner.messageTransport.messageLogs,
      itemBuilder: (context, item) {
        var data = item.$2.tryGetMap<String, dynamic>("data");
        var type =
            data?.tryGet<String>("type") ?? data?.tryGet<String>("event_type");

        var response = item.$2.tryGetMap<String, dynamic>("response");
        bool isError = response?.containsKey("error") == true;
        bool isResponse = response != null;

        var id = item.$2.tryGet<String>("requestId")!;

        var emote =
            emoji.characters.elementAt(id.hashCode % emoji.characters.length);

        return Container(
            color: (isError
                    ? m.Colors.red
                    : item.$1 == WidgetMessageDirection.incoming
                        ? m.Colors.blueAccent
                        : m.Colors.greenAccent)
                .withAlpha(20),
            child: m.ExpansionTile(
              title: Row(
                spacing: 8,
                children: [
                  Icon(item.$1 == WidgetMessageDirection.incoming
                      ? m.Icons.arrow_back
                      : m.Icons.arrow_forward),
                  tiamat.Text.tiny(emote),
                  if (isResponse) Icon(m.Icons.reply),
                  if (isError)
                    Icon(
                      m.Icons.error,
                      color: m.Colors.redAccent,
                    ),
                  tiamat.Text(item.$2["action"]),
                  if (type != null) tiamat.Text.labelLow(type)
                ],
              ),
              children: [
                Scrollbar(
                  controller: controller,
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    child: Codeblock(
                      text: JsonEncoder.withIndent("  ").convert(item.$2),
                      language: "json",
                    ),
                  ),
                )
              ],
            ));
      },
    );
  }
}
