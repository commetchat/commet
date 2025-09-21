import 'package:commet/client/components/space_color_scheme/space_color_scheme_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:flutter/src/material/color_scheme.dart';

class MatrixSpaceColorSchemeComponent
    implements SpaceColorSchemeComponent<MatrixClient, MatrixSpace> {
  @override
  MatrixClient client;

  @override
  ColorScheme get scheme => _scheme;

  @override
  MatrixSpace space;

  MatrixSpaceColorSchemeComponent(this.client, this.space) {
    _scheme = ColorScheme.fromSeed(seedColor: space.color);
    updateColorScheme();
    space.onUpdate.listen((_) => updateColorScheme());
  }

  late ColorScheme _scheme;

  void updateColorScheme() {
    if (space.avatar != null) {
      ColorScheme.fromImageProvider(
              provider: space.avatar!,
              dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot)
          .then((result) {
        _scheme = result;
      });
    }
  }
}
