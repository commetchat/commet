import 'package:commet/cache/app_data.dart';
import 'package:commet/cache/error_log.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class ErrorPage extends StatefulWidget {
  const ErrorPage({super.key});

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  List<ErrorEntry>? entries;

  @override
  void initState() {
    super.initState();

    AppData.instance.errorLog?.getErrors().then((e) => setState(() {
          entries = e;
        }));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (entries == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return ListView.builder(
        itemCount: entries!.length,
        itemBuilder: (context, index) {
          var item = entries![index];
          return buildLog(item, index);
        },
      );
    }
  }

  Widget buildLog(ErrorEntry item, int index) {
    var background = index % 2 == 0
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5), color: background),
          child: InkWell(
            onTap: () => AdaptiveDialog.show(context,
                builder: (context) => logDetail(item), title: item.detail),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: TinyPill("${item.occurrences}"),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.error,
                          size: 15,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10, child: tiamat.Seperator()),
                      tiamat.Text.labelLow(TextUtils.timestampToLocalizedTime(
                          item.lastOccurred,
                          MediaQuery.of(context).alwaysUse24HourFormat)),
                    ],
                  ),
                  tiamat.Text(
                    item.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget logDetail(ErrorEntry entry) {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: tiamat.Button.secondary(
                text: "Report Issue",
                onTap: () => ErrorUtils.reportIssue(entry),
              ),
            ),
            Codeblock(text: entry.stackTrace),
          ],
        ),
      ),
    );
  }
}
