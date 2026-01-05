import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

const _darkTheme = {
  'root':
      TextStyle(color: Color(0xffabb2bf), backgroundColor: Colors.transparent),
  'comment': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Color(0xffc678dd)),
  'keyword': TextStyle(color: Color(0xffc678dd)),
  'formula': TextStyle(color: Color(0xffc678dd)),
  'section': TextStyle(color: Color(0xffe06c75)),
  'name': TextStyle(color: Color(0xffe06c75)),
  'selector-tag': TextStyle(color: Color(0xffe06c75)),
  'deletion': TextStyle(color: Color(0xffe06c75)),
  'subst': TextStyle(color: Color(0xffe06c75)),
  'literal': TextStyle(color: Color(0xff56b6c2)),
  'string': TextStyle(color: Color(0xff98c379)),
  'regexp': TextStyle(color: Color(0xff98c379)),
  'addition': TextStyle(color: Color(0xff98c379)),
  'attribute': TextStyle(color: Color(0xff98c379)),
  'meta-string': TextStyle(color: Color(0xff98c379)),
  'built_in': TextStyle(color: Color(0xffe6c07b)),
  'attr': TextStyle(color: Color(0xffd19a66)),
  'variable': TextStyle(color: Color(0xffd19a66)),
  'template-variable': TextStyle(color: Color(0xffd19a66)),
  'type': TextStyle(color: Color(0xffd19a66)),
  'selector-class': TextStyle(color: Color(0xffd19a66)),
  'selector-attr': TextStyle(color: Color(0xffd19a66)),
  'selector-pseudo': TextStyle(color: Color(0xffd19a66)),
  'number': TextStyle(color: Color(0xffd19a66)),
  'symbol': TextStyle(color: Color(0xff61aeee)),
  'bullet': TextStyle(color: Color(0xff61aeee)),
  'link': TextStyle(color: Color(0xff61aeee)),
  'meta': TextStyle(color: Color(0xff61aeee)),
  'selector-id': TextStyle(color: Color(0xff61aeee)),
  'title': TextStyle(color: Color(0xff61aeee)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

const _lightTheme = {
  'root':
      TextStyle(color: Color(0xff383a42), backgroundColor: Colors.transparent),
  'comment': TextStyle(color: Color(0xffa0a1a7), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: Color(0xffa0a1a7), fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Color(0xffa626a4)),
  'keyword': TextStyle(color: Color(0xffa626a4)),
  'formula': TextStyle(color: Color(0xffa626a4)),
  'section': TextStyle(color: Color(0xffe45649)),
  'name': TextStyle(color: Color(0xffe45649)),
  'selector-tag': TextStyle(color: Color(0xffe45649)),
  'deletion': TextStyle(color: Color(0xffe45649)),
  'subst': TextStyle(color: Color(0xffe45649)),
  'literal': TextStyle(color: Color(0xff0184bb)),
  'string': TextStyle(color: Color(0xff50a14f)),
  'regexp': TextStyle(color: Color(0xff50a14f)),
  'addition': TextStyle(color: Color(0xff50a14f)),
  'attribute': TextStyle(color: Color(0xff50a14f)),
  'meta-string': TextStyle(color: Color(0xff50a14f)),
  'built_in': TextStyle(color: Color(0xffc18401)),
  'attr': TextStyle(color: Color(0xff986801)),
  'variable': TextStyle(color: Color(0xff986801)),
  'template-variable': TextStyle(color: Color(0xff986801)),
  'type': TextStyle(color: Color(0xff986801)),
  'selector-class': TextStyle(color: Color(0xff986801)),
  'selector-attr': TextStyle(color: Color(0xff986801)),
  'selector-pseudo': TextStyle(color: Color(0xff986801)),
  'number': TextStyle(color: Color(0xff986801)),
  'symbol': TextStyle(color: Color(0xff4078f2)),
  'bullet': TextStyle(color: Color(0xff4078f2)),
  'link': TextStyle(color: Color(0xff4078f2)),
  'meta': TextStyle(color: Color(0xff4078f2)),
  'selector-id': TextStyle(color: Color(0xff4078f2)),
  'title': TextStyle(color: Color(0xff4078f2)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

class Codeblock extends StatelessWidget {
  const Codeblock(
      {required this.text, this.clipboardText, this.language, super.key});

  final String? clipboardText;
  final String text;
  final String? language;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).brightness == Brightness.dark
        ? _darkTheme
        : _lightTheme;

    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
              child: clipboardText == null
                  ? SizedBox(
                      height: 0,
                      width: 0,
                    )
                  : SizedBox(
                      width: 20,
                      height: 20,
                      child: tiamat.IconButton(
                        icon: Icons.copy,
                        size: 12,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: clipboardText!),
                          );
                        },
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (language != null && language != "")
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                      child: tiamat.Text.labelLow(language!),
                    ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 8, 4),
                      child: language != null
                          ? SizedBox(
                              child: HighlightView(
                                text.trim(),
                                language: language,
                                theme: theme,
                                textStyle: const TextStyle(
                                    fontFamily: "Code",
                                    fontFeatures: [
                                      FontFeature.disable("calt")
                                    ]),
                              ),
                            )
                          : Text(
                              text.trim(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}

class ExpandableCodeBlock extends StatefulWidget {
  const ExpandableCodeBlock({required this.text, this.language, super.key});

  final String text;
  final String? language;

  @override
  State<ExpandableCodeBlock> createState() => _ExpandableCodeBlockState();
}

class _ExpandableCodeBlockState extends State<ExpandableCodeBlock> {
  bool expanded = false;

  late List<String> lines;

  ScrollController controller = ScrollController();

  bool get canExpand => lines.length > 5;

  @override
  void initState() {
    lines = widget.text.split("\n");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var text = (canExpand && !expanded)
        ? (lines.sublist(0, 5).join("\n"))
        : widget.text;

    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    end: Alignment.centerLeft,
                    begin: Alignment.bottomLeft,
                    colors: [
                      Colors.purple,
                      Colors.transparent,
                    ],
                    stops: [
                      0.0,
                      1.0,
                    ],
                  ).createShader(rect);
                },
                blendMode:
                    (canExpand && !expanded) ? BlendMode.dstOut : BlendMode.dst,
                child: Container(
                  child: Scrollbar(
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      child: Codeblock(
                        text: text,
                        clipboardText: widget.text,
                        language: widget.language,
                      ),
                    ),
                  ),
                )),
            if (canExpand)
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        tiamat.Text.labelLow(
                            expanded ? "Show Less" : "Show More")
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
