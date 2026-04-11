import 'dart:ui';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/user_color/user_color_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/utils/color_utils.dart';

class MatrixUserColorComponent
    implements UserColorComponent<MatrixClient>, NeedsPostLoginInit {
  static const String key = "im.vector.setting.override_colors";

  @override
  MatrixClient client;

  MatrixUserColorComponent(this.client);

  Map<String, dynamic> overrides = {};

  @override
  Color? getColor(String identifier) {
    var override = overrides[identifier];

    if (override is String) {
      return ColorUtils.fromHexCode(override);
    }

    return null;
  }

  @override
  Future<void> setColor(String identifier, Color? color) async {
    if (color == null) {
      overrides.remove(identifier);
    } else {
      overrides[identifier] = color.toHexCode();
    }

    await client.matrixClient
        .setAccountData(client.matrixClient.userID!, key, overrides);
  }

  @override
  void postLoginInit() {
    var data = client.matrixClient.accountData[key];
    overrides = data?.content ?? {};
  }
}
