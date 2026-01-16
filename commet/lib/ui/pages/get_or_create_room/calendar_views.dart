import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/event_view.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class FakeCalendarConfig extends MatrixCalendarConfig {
  @override
  Color getColorFromUser(String userId) {
    if (userId == "@pluto:commet.chat") {
      return const Color.fromARGB(255, 255, 168, 197);
    }

    if (userId == "@luna:commet.chat") {
      return const Color.fromARGB(255, 82, 255, 255);
    }

    return Colors.red;
  }

  @override
  ImageProvider<Object>? getUserAvatar(String userId) {
    if (userId == "@pluto:commet.chat") {
      return AssetImage("assets/images/placeholders/avatar1.jpg");
    }

    if (userId == "@luna:commet.chat") {
      return AssetImage("assets/images/placeholders/avatar2.jpg");
    }

    return null;
  }

  @override
  String? getUserDisplayname(String userId) {
    if (userId == "@pluto:commet.chat") {
      return "Pluto";
    }

    if (userId == "@luna:commet.chat") {
      return "luna";
    }

    return "";
  }
}

class CalendarCreatorDescription extends StatelessWidget {
  const CalendarCreatorDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        tiamat.Text.labelLow(
            "Create a shared calendar to keep track of your plans, and import your schedule from other calendars to let your friends know when you are busy."),
        SizedBox(
          height: 10,
        ),
        LayoutBuilder(builder: (context, constraints) {
          double width = (constraints.maxWidth / 4) - (10);
          return Container(
            decoration: BoxDecoration(
                color: ColorScheme.of(context).surfaceContainerLow,
                borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: EdgeInsetsGeometry.all(8),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          buildFakeEvent(
                            width: width,
                            height: 100,
                            text: "Movies",
                            senderId: "@luna:commet.chat",
                          ),
                          SizedBox(
                            height: 40,
                          ),
                          buildFakeEvent(
                            width: width,
                            height: 100,
                            text: "Unavailable",
                            type: "unavailability",
                            senderId: "@pluto:commet.chat",
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          buildFakeEvent(
                            width: width,
                            height: 50,
                            text: "Dinner",
                            senderId: "@pluto:commet.chat",
                          )
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: 50,
                        ),
                        buildFakeEvent(
                            width: width,
                            height: 250,
                            type: "unavailability",
                            text: "Work",
                            senderId: "@luna:commet.chat"),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: 30,
                        ),
                        buildFakeEvent(
                            width: width,
                            height: 150,
                            type: "unavailability",
                            text: "work",
                            senderId: "@pluto:commet.chat"),
                        SizedBox(
                          height: 40,
                        ),
                        buildFakeEvent(
                            width: width,
                            height: 70,
                            text: "Gaminggg",
                            senderId: "@pluto:commet.chat"),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: 170,
                        ),
                        buildFakeEvent(
                            width: width,
                            height: 100,
                            text: "Beach Night",
                            senderId: "@luna:commet.chat"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  SizedBox buildFakeEvent({
    required double width,
    required double height,
    required String text,
    required String senderId,
    String? type,
  }) {
    var event = MatrixCalendarEventState(
        senderId: senderId,
        type: type,
        data: RFC8984CalendarEvent(
            uid: "12312312",
            updated: DateTime.now(),
            title: text,
            start: DateTime.now(),
            duration: Duration(seconds: 5)));
    event.loaded = true;

    var config = FakeCalendarConfig();

    return SizedBox(
      height: height,
      width: width,
      child: EventViewBox(event, config,
          color: Colors.blue, boundary: Rect.fromLTWH(0, 0, width, height)),
    );
  }
}

class CalendarCreatorForm extends StatefulWidget {
  const CalendarCreatorForm({super.key});

  @override
  State<CalendarCreatorForm> createState() => _CalendarCreatorFormState();
}

class _CalendarCreatorFormState extends State<CalendarCreatorForm> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
