import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/member.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixMember implements Member {
  matrix.User matrixUser;
  matrix.Client client;

  @override
  ImageProvider<Object>? get avatar => matrixUser.avatarUrl != null
      ? MatrixMxcImage(matrixUser.avatarUrl!, client)
      : null;

  @override
  String? get detail => matrixUser.id.domain;

  @override
  String get displayName => matrixUser.calcDisplayname();

  @override
  String get identifier => matrixUser.id;

  @override
  String get userName => matrixUser.id;

  MatrixMember(this.client, this.matrixUser);

  // Matching color calculation that other clients use. Element, Cinny, Etc.
  // https://github.com/cinnyapp/cinny/blob/dev/src/util/colorMXID.js
  static Color hashColor(String userId) {
    int hash = 0;

    const colors = [
      Color.fromRGBO(54, 139, 214, 1),
      Color.fromRGBO(172, 59, 168, 1),
      Color.fromRGBO(3, 179, 129, 1),
      Color.fromRGBO(230, 79, 122, 1),
      Color.fromRGBO(255, 129, 45, 1),
      Color.fromRGBO(45, 194, 197, 1),
      Color.fromRGBO(92, 86, 245, 1),
      Color.fromRGBO(116, 209, 44, 1),
    ];

    for (int i = 0; i < userId.length; i++) {
      var chr = userId.codeUnitAt(i);
      hash = ((hash << 5) - hash) + chr;
      hash |= 0;
      hash = BigInt.from(hash).toSigned(32).toInt();
    }

    var index = hash.abs() % 8;

    return colors[index];
  }

  @override
  Color get defaultColor => hashColor(identifier);

  @override
  bool operator ==(Object other) {
    if (other is! MatrixMember) return false;
    if (identical(this, other)) return true;
    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
