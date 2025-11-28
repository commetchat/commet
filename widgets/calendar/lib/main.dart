import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_day.dart';
import 'package:commet_calendar_widget/calendar_view_month.dart';
import 'package:commet_calendar_widget/calendar_view_week.dart';
import 'package:commet_calendar_widget/event_editor.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:tiamat/config/config.dart';
import 'package:uuid/v4.dart';

void main() {
  runApp(const CalendarWidgetApp());
}

class CalendarWidgetApp extends StatelessWidget {
  const CalendarWidgetApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var parameters = Uri.parse(Uri.base.fragment).queryParameters;

    Brightness? themeBrightness = null;
    if (parameters["theme"] == "dark") themeBrightness = Brightness.dark;
    if (parameters["theme"] == "light") themeBrightness = Brightness.light;

    DynamicSchemeVariant themeVariant = DynamicSchemeVariant.tonalSpot;

    if (parameters["themeVariant"] == "monochrome")
      themeVariant = DynamicSchemeVariant.monochrome;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeBrightness == Brightness.dark
          ? ThemeDark.theme
          : ThemeLight.theme,
      home: IframeCalendarWidgetView(parameters: parameters),
    );
  }
}

class IframeCalendarWidgetView extends StatefulWidget {
  const IframeCalendarWidgetView({required this.parameters, super.key});

  final Map<String, dynamic> parameters;

  @override
  State<IframeCalendarWidgetView> createState() =>
      _IframeCalendarWidgetViewState();
}

class _IframeCalendarWidgetViewState extends State<IframeCalendarWidgetView> {
  late MatrixCalendar calendar;
  late MatrixWidgetApi api;

  @override
  void initState() {
    super.initState();

    var parameters = widget.parameters;
    var userId = parameters["userId"];

    api = MatrixWidgetApiWeb(
      parameters["widgetId"] ?? "unknown_widget_id",
      userId: userId ?? "unknown_user",
    );

    calendar = MatrixCalendar(api);
  }

  @override
  Widget build(BuildContext context) {
    var hideWatermark = widget.parameters["hideWatermark"] == "1";
    return CalendarWidgetView(
      calendar: calendar,
      watermark: !hideWatermark,
      useMobileLayout: false,
    );
  }
}

enum CalendarViewMode { month, week, day }

class CalendarWidgetView extends StatefulWidget {
  const CalendarWidgetView({
    required this.calendar,
    super.key,
    this.watermark = true,
    this.useMobileLayout = true,
  });
  final MatrixCalendar calendar;

  final bool watermark;
  final bool useMobileLayout;
  @override
  State<CalendarWidgetView> createState() => _CalendarWidgetViewState();
}

class _CalendarWidgetViewState extends State<CalendarWidgetView> {
  var mode = CalendarViewMode.week;

  @override
  void initState() {
    widget.calendar.widgetApi.start();

    super.initState();
  }

  @override
  void dispose() {
    widget.calendar.widgetApi.stop();
    super.dispose();
  }

  Future<void> createEvent(DateTime time) async {
    var result = await widget.calendar.config.dialog<bool?>(
      context: context,
      builder: (context) => CalendarEventEditor(
        createEvent: (event) async {
          try {
            return widget.calendar.createEvent(event);
          } catch (e, s) {
            return false;
          }
        },
        initialEvent: RFC8984CalendarEvent(
          uid: "",
          updated: DateTime.now().toUtc(),
          title: "",
          start: time,
          duration: Duration(hours: 1),
        ),
      ),
    );

    if (result != true) {
      widget.calendar.updateFromRoomState();
    }
  }

  void setViewMode(CalendarViewMode viewMode) {
    print("Setting view mode");
    setState(() {
      mode = viewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mode == CalendarViewMode.month)
            CalendarViewMonth(
              calendar: widget.calendar,
              useMobileLayout: widget.useMobileLayout,
              createEvent: createEvent,
              setViewMode: setViewMode,
            ),
          if (mode == CalendarViewMode.week)
            CalendarViewWeek(
              calendar: widget.calendar,
              useMobileLayout: widget.useMobileLayout,
              createEvent: createEvent,
              setViewMode: setViewMode,
            ),
          if (mode == CalendarViewMode.day)
            CalendarViewDay(
              calendar: widget.calendar,
              useMobileLayout: widget.useMobileLayout,
              createEvent: createEvent,
              setViewMode: setViewMode,
            ),
          if (widget.watermark)
            Align(
              alignment: AlignmentGeometry.bottomRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: appIcon(context),
              ),
            ),
        ],
      ),
    ); // CalendarViewMonth(calendar: calendar);
  }
}

Widget appIcon(BuildContext context) {
  return Opacity(
    opacity: 0.5,
    child: SizedBox(
      width: 30,
      height: 30,
      child: SvgPicture.asset(
        "assets/app_icon/icon.svg",
        theme: SvgTheme(currentColor: Theme.of(context).colorScheme.onSurface),
      ),
    ),
  );
}
