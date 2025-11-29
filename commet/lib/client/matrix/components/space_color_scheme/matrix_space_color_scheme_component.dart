import 'package:commet/client/components/space_color_scheme/space_color_scheme_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:commet/utils/task_scheduler.dart';
import 'package:flutter/src/material/color_scheme.dart';

class MatrixSpaceColorSchemeComponent
    implements SpaceColorSchemeComponent<MatrixClient, MatrixSpace> {
  @override
  MatrixClient client;

  @override
  ColorScheme get scheme => _scheme;

  @override
  MatrixSpace space;

  static TaskScheduler scheduler = OneAtATimeScheduler();

  MatrixSpaceColorSchemeComponent(this.client, this.space) {
    _scheme = ColorScheme.fromSeed(seedColor: space.color);

    MatrixSpaceColorSchemeComponent.scheduler.enqueue(updateColorScheme);

    space.onUpdate.listen((_) {
      MatrixSpaceColorSchemeComponent.scheduler.enqueue(updateColorScheme);
    });
  }

  late ColorScheme _scheme;

  Future<void> updateColorScheme() async {
    if (space.avatar != null) {
      var scheme = await ColorScheme.fromImageProvider(
          provider: space.avatar!,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot);

      _scheme = scheme;
    }
  }
}
