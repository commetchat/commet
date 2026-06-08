import 'package:commet/client/client.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class DialogResult<T> {
  T value;
  bool remember;

  DialogResult(this.value, {this.remember = false});
}

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

  static String get labelDialogConfirmation => Intl.message("Confirmation",
      name: "labelDialogConfirmation",
      desc: "label for the dialog which asks the user to confirm some action");

  static Future<bool?> confirmation(BuildContext context,
      {String prompt = "Are you sure?",
      String title = "Confirmation",
      String confirmationText = "Yes",
      String cancelText = "No",
      Widget Function(BuildContext)? customBuilder,
      bool dangerous = false}) async {
    var value = await show<DialogResult<bool>?>(context, builder: (context) {
      return ConfirmationDialogWidget(
        prompt: prompt,
        title: title,
        confirmationText: confirmationText,
        cancelText: cancelText,
        customBuilder: customBuilder,
        dangerous: dangerous,
      );
    }, title: title == "Confirmation" ? labelDialogConfirmation : title);

    return value?.value;
  }

  static Future<DialogResult<bool>?> confirmationWithOptions(
      BuildContext context,
      {String prompt = "Are you sure?",
      String title = "Confirmation",
      String confirmationText = "Yes",
      String cancelText = "No",
      Widget Function(BuildContext)? customBuilder,
      bool showRememberChoice = false,
      bool defaultRememberSetting = false,
      bool dangerous = false}) {
    var value = show<DialogResult<bool>?>(context, builder: (context) {
      return ConfirmationDialogWidget(
        prompt: prompt,
        title: title,
        confirmationText: confirmationText,
        cancelText: cancelText,
        customBuilder: customBuilder,
        showRememberChoice: showRememberChoice,
        defaultRememberSetting: defaultRememberSetting,
        dangerous: dangerous,
      );
    }, title: title == "Confirmation" ? labelDialogConfirmation : title);

    return value;
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
                text: submitText == "Submit"
                    ? CommonStrings.promptSubmit
                    : submitText,
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

class ConfirmationDialogWidget extends StatefulWidget {
  final String prompt;
  final String title;
  final String confirmationText;
  final String cancelText;
  final Widget Function(BuildContext)? customBuilder;
  final bool showRememberChoice;
  final bool defaultRememberSetting;
  final bool dangerous;

  const ConfirmationDialogWidget({
    super.key,
    this.prompt = "Are you sure?",
    this.title = "Confirmation",
    this.confirmationText = "Yes",
    this.cancelText = "No",
    this.customBuilder,
    this.showRememberChoice = false,
    this.defaultRememberSetting = false,
    this.dangerous = false,
  });

  @override
  State<ConfirmationDialogWidget> createState() =>
      _ConfirmationDialogWidgetState();
}

class _ConfirmationDialogWidgetState extends State<ConfirmationDialogWidget> {
  bool rememberChoice = false;

  @override
  void initState() {
    rememberChoice = widget.defaultRememberSetting;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                        codeblockPadding: EdgeInsets.all(8),
                        code: TextTheme.of(context).bodySmall!.copyWith(
                            fontFamily: "Code",
                            backgroundColor: ColorScheme.of(context)
                                .surfaceContainerLowest)),
                data: widget.prompt,
              ),
            ),
            if (widget.customBuilder != null) widget.customBuilder!(context),
            if (widget.showRememberChoice)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    tiamat.Text.labelLow("Remember choice: "),
                    tiamat.Switch(
                      state: rememberChoice,
                      onChanged: (value) {
                        setState(() {
                          rememberChoice = value;
                        });
                      },
                    ),
                  ],
                )),
              ),
            SizedBox(
              height: 40,
              child: tiamat.Button(
                type: widget.dangerous ? ButtonType.danger : ButtonType.primary,
                text: widget.confirmationText == "Yes"
                    ? CommonStrings.promptYes
                    : widget.confirmationText,
                onTap: () => Navigator.pop(
                    context, DialogResult(true, remember: rememberChoice)),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            tiamat.Button.secondary(
              text: widget.cancelText == "No"
                  ? CommonStrings.promptNo
                  : widget.cancelText,
              onTap: () => Navigator.pop(
                  context, DialogResult(false, remember: rememberChoice)),
            )
          ],
        ),
      ),
    );
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
            text: CommonStrings.promptSubmit,
            onTap: () => Navigator.of(context).pop(selection),
          )
        ]);
  }
}
