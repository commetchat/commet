import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:commet/ui/atoms/texture_coordinate_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();

    RenderBox? box = currentContext?.findRenderObject() as RenderBox?;
    Offset? position = box?.localToGlobal(Offset.zero);

    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}

class ShaderBackground extends StatefulWidget {
  const ShaderBackground({super.key});
  @override
  State<ShaderBackground> createState() => _ShaderBackgroundState();
}

class _ShaderBackgroundState extends State<ShaderBackground> {
  double delta = 0;
  static FragmentShader? shader;
  static ui.Image? image;
  late TextureCoordinatePainter painter;
  late Rect offset = Rect.zero;
  late GlobalKey key = GlobalKey();

  static bool loadingShader = false;

  void loadMyShader() async {
    loadingShader = true;

    var program = await FragmentProgram.fromAsset('assets/shader/texture_coordinate.frag');
    shader = program.fragmentShader();

    final imageData = await rootBundle.load('assets/images/placeholder/generic/checker_orange.png');
    image = await decodeImageFromList(imageData.buffer.asUint8List());
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      setState(() {
        if (key.globalPaintBounds != null) offset = key.globalPaintBounds!;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (!loadingShader) {
      loadMyShader();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        setState(() {
          if (key.globalPaintBounds != null) offset = key.globalPaintBounds!;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var window = MediaQuery.of(context).size;
    if (shader == null || image == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Container(
          key: key,
          child: CustomPaint(
            painter: TextureCoordinatePainter(shader!, image!, window.width, window.height, offset),
            child: Container(),
          ));
    }
  }
}
