import 'package:calendar_view/calendar_view.dart';
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
import 'package:timezone/data/latest.dart' as tzData;
import 'package:url_launcher/url_launcher.dart';

void main() {
  tzData.initializeTimeZones();
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
    this.autoDisposeCalendar = true,
  });
  final MatrixCalendar calendar;

  final bool watermark;
  final bool useMobileLayout;
  final bool autoDisposeCalendar;
  @override
  State<CalendarWidgetView> createState() => _CalendarWidgetViewState();
}

class _CalendarWidgetViewState extends State<CalendarWidgetView> {
  var mode = CalendarViewMode.week;
  DateTime? currentDate;
  @override
  void initState() {
    widget.calendar.widgetApi.start();
    super.initState();
  }

  @override
  void dispose() {
    if (widget.autoDisposeCalendar) {
      widget.calendar.widgetApi.stop();
    }
    super.dispose();
  }

  Future<void> editEvent(MatrixCalendarEventState event) async {
    var result = await widget.calendar.config.dialog<bool?>(
      context: context,
      builder: (context) => CalendarEventEditor(
        config: widget.calendar.config,
        submitEvent: (event, {String? eventType}) async {
          try {
            return widget.calendar.createEvent(event, eventType: eventType);
          } catch (e, _) {
            return false;
          }
        },
        deleteEvent: (event) => widget.calendar.deleteEvent(event),
        eventType: event.type,
        initialEvent: event.data,
        editingExistingEvent: true,
      ),
    );

    if (result != true) {
      widget.calendar.updateFromRoomState();
    }
  }

  Future<void> viewEvent(MatrixCalendarEventState event) async {
    await widget.calendar.config.dialog<bool?>(
      context: context,
      builder: (context) => CalendarEventEditor(
        config: widget.calendar.config,
        editable: false,
        submitEvent: (event, {String? eventType}) async {
          try {
            return widget.calendar.createEvent(event, eventType: eventType);
          } catch (e, _) {
            return false;
          }
        },
        deleteEvent: (event) => widget.calendar.deleteEvent(event),
        eventType: event.type,
        initialEvent: event.data,
        editingExistingEvent: true,
      ),
    );
  }

  Future<void> createEvent(DateTime time) async {
    var result = await widget.calendar.config.dialog<bool?>(
      context: context,
      builder: (context) => CalendarEventEditor(
        config: widget.calendar.config,
        submitEvent: (event, {String? eventType}) async {
          try {
            return widget.calendar.createEvent(event, eventType: eventType);
          } catch (e, _) {
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
        editingExistingEvent: false,
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

  void onEventTapped(MatrixCalendarEventState event) {
    if (widget.calendar.canEditEvent(event)) {
      editEvent(event);
    } else {
      viewEvent(event);
    }
  }

  onPageChanged(DateTime pageDate) {
    currentDate = pageDate;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var extensions = theme.extensions.values.toList();

    extensions.addAll(
      [
        WeekViewThemeData(
          weekDayTileColor: theme.colorScheme.surfaceContainerLow,
          weekDayTextColor: Colors.red,
          hourLineColor: Colors.red,
          halfHourLineColor: Colors.red,
          quarterHourLineColor: Colors.red,
          liveIndicatorColor: Colors.red,
          pageBackgroundColor: Colors.red,
          headerIconColor: Colors.red,
          headerTextColor: Colors.red,
          headerBackgroundColor: Colors.red,
          timelineTextColor: theme.colorScheme.onSurface,
          borderColor: Colors.transparent,
          verticalLinesColor: theme.colorScheme.surfaceContainerLow,
        ),
        DayViewThemeData(
            hourLineColor: Colors.red,
            halfHourLineColor: Colors.red,
            quarterHourLineColor: Colors.red,
            pageBackgroundColor: Colors.red,
            liveIndicatorColor: Colors.red,
            headerIconColor: Colors.red,
            headerTextColor: Colors.red,
            headerBackgroundColor: Colors.red,
            timelineTextColor: theme.colorScheme.onSurface),
      ],
    );

    return Theme(
      data: theme.copyWith(extensions: extensions),
      child: Material(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (mode == CalendarViewMode.month)
              CalendarViewMonth(
                calendar: widget.calendar,
                useMobileLayout: widget.useMobileLayout,
                createEvent: createEvent,
                setViewMode: setViewMode,
                onEventTapped: onEventTapped,
                onPageChanged: onPageChanged,
                initialDate: currentDate,
              ),
            if (mode == CalendarViewMode.week)
              CalendarViewWeek(
                calendar: widget.calendar,
                useMobileLayout: widget.useMobileLayout,
                createEvent: createEvent,
                setViewMode: setViewMode,
                onEventTapped: onEventTapped,
                onPageChanged: onPageChanged,
                initialDate: currentDate,
              ),
            if (mode == CalendarViewMode.day)
              CalendarViewDay(
                calendar: widget.calendar,
                useMobileLayout: widget.useMobileLayout,
                createEvent: createEvent,
                setViewMode: setViewMode,
                onEventTapped: onEventTapped,
                onPageChanged: onPageChanged,
                initialDate: currentDate,
              ),
            if (widget.watermark)
              Align(
                alignment: AlignmentGeometry.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            launchUrl(Uri.parse("https://commet.chat")),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: appIcon(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
