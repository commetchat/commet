import 'package:commet/client/components/polls/poll_component.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class PollCreator extends StatefulWidget {
  const PollCreator({super.key});

  @override
  State<PollCreator> createState() => _PollCreatorState();
}

class _PollCreatorState extends State<PollCreator> {
  TextEditingController questionController = TextEditingController();
  bool openPoll = true;
  bool multiAnswer = false;

  List<TextEditingController> options = List.from([
    TextEditingController(),
    TextEditingController(),
  ], growable: true);

  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: "Question",
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            tiamat.DropdownSelector(
              value: openPoll,
              items: [true, false],
              onItemSelected: (item) {
                if (item != null) {
                  setState(() {
                    openPoll = item;
                  });
                }
              },
              itemBuilder: (item) {
                var msg = item ? "Open Poll" : "Closed Poll";
                var descriptor = item
                    ? "Voters can see results as they come in"
                    : "Votes are hidden until the poll ends";
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tiamat.Text(msg),
                      tiamat.Text.labelLow(descriptor)
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              height: 12,
            ),
            SizedBox(
              height: 200,
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                    child: Column(
                      spacing: 8,
                      children: [
                        for (int i = 0; i < options.length; i++)
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: options[i],
                                  decoration: InputDecoration(
                                      suffixIcon: SizedBox(
                                          height: 34,
                                          width: 34,
                                          child: options.length > 2
                                              ? tiamat.IconButton(
                                                  icon: Icons.remove,
                                                  onPressed: () {
                                                    setState(() {
                                                      options.removeAt(i);
                                                    });
                                                  },
                                                )
                                              : null),
                                      border: const OutlineInputBorder(),
                                      labelText: "Option ${i + 1}"),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: CheckboxListTile(
                      dense: true,
                      title: tiamat.Text("Allow multiple answers"),
                      value: multiAnswer,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            multiAnswer = value;
                          });
                        }
                      }),
                ),
                TextButton.icon(
                  label: Text("Add Option"),
                  onPressed: () {
                    setState(() {
                      options.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            if (errorMessage != null) tiamat.Text.error(errorMessage!),
            SizedBox(
              height: 12,
            ),
            tiamat.Button(
                text: "Create",
                onTap: () async {
                  setState(() {
                    errorMessage = null;
                  });

                  String question = questionController.text;
                  if (question.isEmpty) {
                    setState(() {
                      errorMessage = "Poll must have a question";
                    });
                    return;
                  }

                  List<String> parsedOptions = List.empty(growable: true);

                  for (var controller in options) {
                    if (controller.text.trim().isEmpty) {
                      setState(() {
                        errorMessage = "Poll cannot have a blank option";
                      });
                      return;
                    }

                    parsedOptions.add(controller.text.trim());
                  }

                  Navigator.of(context).pop(PollCreateArgs(
                      question: question,
                      options: parsedOptions,
                      multiAnswer: multiAnswer,
                      publicAnswers: openPoll));
                })
          ],
        ),
      ),
    );
  }
}
