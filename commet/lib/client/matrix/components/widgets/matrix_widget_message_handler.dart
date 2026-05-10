import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixWidgetMessage {
  String requestId;
  String action;
  String widgetId;
  Map<String, dynamic> data;

  MatrixWidgetMessage(
      {required this.requestId,
      required this.action,
      required this.data,
      required this.widgetId});

  Map<String, dynamic> createResponse(
      {Map<String, dynamic> data = const {},
      Map<String, dynamic> response = const {}}) {
    return {
      "api": "fromWidget",
      "widgetId": widgetId,
      "requestId": requestId,
      "action": action,
      "data": data.isEmpty ? this.data : data,
      "response": response,
    };
  }
}

class MatrixWidgetMessageHandler implements WidgetEventHandler {
  WidgetRunner runner;

  late Map<String, Function(MatrixWidgetMessage msg)> defaultHandlers;

  MatrixWidgetMessageHandler({required this.runner}) {
    runner.messageTransport.onReceived.listen(onMessageReceived);

    defaultHandlers = {
      "supported_api_versions": handleSupportedApiVersions,
      "org.matrix.msc2974.request_capabilities": handleRequestCapabilities,
    };
  }

  void onMessageReceived(Map<String, dynamic> data) {
    String? requestId = data.tryGet("requestId");
    String? api = data.tryGet("api");
    String? action = data.tryGet("action");
    dynamic messageData = data.tryGet("data");

    if (requestId == null || action == null) return;

    // This is a request initiated by the widget, to us
    if (api == "fromWidget") {
      var request = MatrixWidgetMessage(
          requestId: requestId,
          action: action,
          data: messageData,
          widgetId: runner.widgetId);

      final handler = defaultHandlers[action];

      if (handler != null) {
        handler(request);
        return;
      }

      var c = runner.capabilities as MatrixWidgetCapabilitiesManager;

      c.handleEvent(request);
    }

    // this event is a response to a request initiated by us
    if (api == "toWidget") {
      Log.i("Received Response: $data");
    }
  }

  handleRequestCapabilities(MatrixWidgetMessage msg) async {
    var capabilities = msg.data.tryGetList<String>("capabilities");
    if (capabilities != null) {
      var allowed = await runner.capabilities.requestCapabilities(capabilities);

      var response = msg.createResponse(data: {
        "capabilities": allowed,
      });

      runner.messageTransport.send(response);
    }
  }

  handleSupportedApiVersions(MatrixWidgetMessage msg) {
    var response = msg.createResponse(response: {
      "supported_versions": [
        "0.0.1",
        "0.0.2",
        "org.matrix.msc2762", // Read / Send Events
        "org.matrix.msc2762_update_state",
        "org.matrix.msc2871", // Capabilities Notifications
        "org.matrix.msc2974", // Widgets: Capabilities re-exchange
        "org.matrix.msc4039", // Access the Content repository with the Widget API
        "town.robin.msc3846", // Allowing widgets to access TURN servers
        "org.matrix.msc3819", // Allowing widgets to send/receive to-device messages
        if (BuildConfig.DEBUG) ...[
          "org.matrix.msc2873", //  Identifying clients and user settings in widgets
          "org.matrix.msc2931", // Allow widgets to navigate with matrix.to URIs
          "org.matrix.msc2876", // Allowing widgets to read events in a room (Closed)
          "org.matrix.msc3869", // Read event relations with the Widget API
          "org.matrix.msc3973", // Search users in the user directory with the Widget API
        ]
      ]
    });

    runner.messageTransport.send(response);
  }

  int requestNum = 0;

  @override
  String generateRequestId() {
    requestNum += 1;
    return "widgetapi-$requestNum";
  }

  Map<String, dynamic> generateToWidgetEvent(
      {required String action, required Map<String, dynamic> data}) {
    return {
      "api": "toWidget",
      "widgetId": runner.widgetId,
      "requestId": generateRequestId(),
      "action": action,
      "data": data
    };
  }
}
