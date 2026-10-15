import 'package:commet/client/matrix/components/widgets/matrix_widget_permission_groups.dart';
import 'package:test/test.dart';

void main() async {
  test("org.matrix.msc4039.download_file", () async {
    var parsed =
        MatrixWidgetCapabilityString.parse("org.matrix.msc4039.download_file");

    expect(
      parsed.capability,
      "org.matrix.msc4039.download_file",
    );
    expect(parsed.eventType, null);
    expect(parsed.eventKey, null);
  });

  test("org.matrix.msc2762.send.event:io.element.call.encryption_keys",
      () async {
    var parsed = MatrixWidgetCapabilityString.parse(
        "org.matrix.msc2762.send.event:io.element.call.encryption_keys");

    expect(
      parsed.capability,
      "org.matrix.msc2762.send.event",
    );
    expect(
      parsed.eventType,
      "io.element.call.encryption_keys",
    );
    expect(parsed.eventKey, null);
  });

  test(
      "org.matrix.msc2762.send.state_event:org.matrix.msc3401.call.member#@user:example.com",
      () async {
    var parsed = MatrixWidgetCapabilityString.parse(
        "org.matrix.msc2762.send.state_event:org.matrix.msc3401.call.member#@user:example.com");

    expect(
      parsed.capability,
      "org.matrix.msc2762.send.state_event",
    );
    expect(
      parsed.eventType,
      "org.matrix.msc3401.call.member",
    );
    expect(
      parsed.eventKey,
      "@user:example.com",
    );
  });
}
