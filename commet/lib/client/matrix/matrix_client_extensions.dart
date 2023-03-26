import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/cache/file_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension MatrixExtensions on Client {
  CacheFileProvider getMxcThumbnail(String mxc, double width, double height) {
    var uri = Uri.parse(mxc);
    return CacheFileProvider("thumbnail_${width}x${height}_${mxc.toString()}", () async {
      return (await httpClient.get(uri.getThumbnail(this, width: width, height: height))).bodyBytes;
    });
  }

  CacheFileProvider getMxcFile(String mxc) {
    var uri = Uri.parse(mxc);
    return CacheFileProvider(mxc.toString(), () async {
      return (await httpClient.get(uri.getDownloadLink(this))).bodyBytes;
    });
  }

  ImageProvider getMxcImage(String mxc) {
    return FileImageProvider(getMxcFile(mxc));
  }
}
