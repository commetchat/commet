import 'package:flutter/widgets.dart';

class ImageOrIcon {
  ImageProvider? image;
  IconData icon;

  ImageOrIcon({this.image, required this.icon});

  Widget build(BuildContext context) {
    if (image != null) {
      return Image(image: image!);
    }

    return Icon(icon);
  }
}
