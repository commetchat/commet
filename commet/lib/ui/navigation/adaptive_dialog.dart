import 'package:commet/client/client.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class AdaptiveDialog {
  static Future<T?> pickOne<T extends Object?>(
    BuildContext context, {
    required List<T> items,
    required Widget Function(BuildContext context, T item, Function() callback)
        itemBuilder,
    String? title,
    bool scrollable = true,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) {
    return AdaptiveDialog.show<T>(context, title: title, builder: (context) {
      return Column(
        children: items
            .map((i) =>
                itemBuilder(context, i, () => Navigator.of(context).pop(i)))
            .toList(),
      );
    });
  }

  static Future<List<T>?> pickMultiple<T extends Object?>(
    BuildContext context, {
    required List<T> items,
    List<T> selected = const [],
    required Widget Function(BuildContext context, T item) itemBuilder,
    String? title,
    bool scrollable = true,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) async {
    // I had to do this weird thing to make it happy with the type cast
    // Dont know why
    var builder = (BuildContext context, dynamic i) {
      var item = i as T;
      return itemBuilder(context, item);
    };

    var result = await AdaptiveDialog.show<List<dynamic>>(
      context,
      title: title,
      dismissible: dismissible,
      scrollable: scrollable,
      builder: (context) {
        return _SelectMultipleView<T>(
          itemBuilder: builder,
          items: items,
          initialSelection: selected,
        );
      },
    );

    print("Got result:");
    print(result);

    if (result != null) {
      return result.map((i) => i as T).toList();
    }

    return null;
  }

  static Future<Client?> pickClient(
    BuildContext context, {
    String? title,
    bool scrollable = true,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) async {
    if (clientManager?.clients.length == 1) {
      return clientManager!.clients.first;
    }

    return AdaptiveDialog.pickOne(
      context,
      title: "Pick Account",
      items: clientManager!.clients,
      itemBuilder: (context, item, callback) {
        return SizedBox(
          child: UserPanelView(
            avatar: item.self!.avatar,
            nameColor: item.self!.defaultColor,
            avatarColor: item.self!.defaultColor,
            displayName: item.self!.displayName,
            detail: item.self!.identifier,
            onClicked: callback,
          ),
        );
      },
    );
  }

  static Future<void> showError(
      BuildContext context, Object exception, StackTrace trace) {
    return show(context, builder: (context) {
      return Column(
        children: [
          tiamat.Text.body(exception.toString()),
        ],
      );
    }, title: "Error");
  }

  static Future<T?> show<T extends Object?>(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    String? title,
    bool scrollable = true,
    bool dismissible = true,
    double contentPadding = 8,
    double initialHeightMobile = 0.5,
  }) async {
    if (Layout.desktop) {
      return PopupDialog.show<T>(context,
          content: scrollable
              ? SingleChildScrollView(child: builder(context))
              : builder(context),
          title: title,
          contentPadding: contentPadding,
          barrierDismissible: dismissible);
    }

    return m.showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      elevation: 0,
      isDismissible: dismissible,
      backgroundColor: m.Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (context) {
        return SingleChildScrollView(
            child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ScaledSafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: tiamat.Text(
                        title,
                        type: TextType.largeTitle,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  Center(child: builder(context)),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  static Future<bool?> confirmation(BuildContext context,
      {String prompt = "Are you sure?",
      String title = "Confirmation",
      String confirmationText = "Yes",
      String cancelText = "No",
      bool dangerous = false}) {
    return show<bool?>(context, builder: (context) {
      return SizedBox(
        width: Layout.desktop ? 500 : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: Markdown(
                  shrinkWrap: true,
                  data: prompt,
                ),
              ),
              SizedBox(
                height: 40,
                child: tiamat.Button(
                  type: dangerous ? ButtonType.danger : ButtonType.primary,
                  text: confirmationText,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              tiamat.Button.secondary(
                text: cancelText,
                onTap: () => Navigator.pop(context, false),
              )
            ],
          ),
        ),
      );
    }, title: title);
  }

  static Future<String?> textPrompt(BuildContext context,
      {String title = "Enter Text",
      String submitText = "Submit",
      String? hintText,
      String? initialText,
      bool multiline = false,
      bool dangerous = false}) {
    return show<String?>(context, builder: (context) {
      String result = "";
      TextEditingController controller =
          TextEditingController(text: initialText);

      return SizedBox(
        width: Layout.desktop ? 500 : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: multiline ? null : 1,
                decoration: InputDecoration(hintText: hintText),
                onChanged: (value) => result = value,
              ),
              SizedBox(
                height: 10,
              ),
              tiamat.Button(
                text: submitText,
                onTap: () {
                  print(result);
                  Navigator.of(context).pop(result);
                },
              )
            ],
          ),
        ),
      );
    }, title: title);
  }
}

class _SelectMultipleView<T> extends StatefulWidget {
  const _SelectMultipleView(
      {required this.itemBuilder,
      required this.items,
      this.initialSelection = const [],
      super.key});
  final List<T> items;
  final List<T> initialSelection;
  final Widget Function(BuildContext context, T item) itemBuilder;
  @override
  State<_SelectMultipleView> createState() => __SelectMultipleViewState();
}

class __SelectMultipleViewState<T> extends State<_SelectMultipleView<T>> {
  List<T> selection = List.empty(growable: true);

  @override
  void initState() {
    selection.addAll(widget.initialSelection);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.items
              .map((i) => Material(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (selection.contains(i)) {
                            selection.remove(i);
                          } else {
                            selection.add(i);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Checkbox(
                                value: selection.contains(i),
                                onChanged: (v) {
                                  if (v == true) {
                                    setState(() {
                                      selection.add(i);
                                    });
                                  } else {
                                    setState(() {
                                      selection.remove(i);
                                    });
                                  }

                                  print(selection);
                                }),
                            widget.itemBuilder(context, i)
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
          tiamat.Button(
            text: "Submit",
            onTap: () => Navigator.of(context).pop(selection),
          )
        ]);
  }
}
