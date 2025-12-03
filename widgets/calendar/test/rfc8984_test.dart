import 'dart:convert';

import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:test/test.dart';

void main() {
  // This example illustrates a simple one-time event.
  // It specifies a one-time event that begins on January 15, 2020 at 1 pm New York local time and ends after 1 hour.
  test('Parse simple event', () {
    var eventData = {
      "@type": "Event",
      "uid": "a8df6573-0474-496d-8496-033ad45d7fea",
      "updated": "2020-01-02T18:23:04Z",
      "title": "Some event",
      "start": "2020-01-15T13:00:00",
      "timeZone": "America/New_York",
      "duration": "PT1H",
    };

    var event = RFC8984CalendarEvent.fromJson(eventData);
    expect(event.duration, equals(Duration(hours: 1)));

    var newData = jsonDecode(jsonEncode(event.toJson()));
    print(newData);
    for (var key in eventData.keys) {
      expect(newData[key], equals(eventData[key]));
    }
  });

  // This example illustrates the use of floating time.
  // Since January 1, 2020, a calendar user blocks 30 minutes every day
  // to practice yoga at 7 am local time in whatever time zone the user is located on that date.
  test('Parse floating time event', () {
    var eventData = {
      "@type": "Event",
      "uid": "yoga-daily-2020",
      "start": "2020-01-01T07:00:00",
      "updated": "2019-12-20T12:00:00Z",
      "title": "Yoga",
      "duration": "PT30M",
      "recurrenceRules": [
        {"@type": "RecurrenceRule", "frequency": "daily"},
      ],
    };

    var event = RFC8984CalendarEvent.fromJson(eventData);
    expect(event.duration, equals(Duration(minutes: 30)));

    var newData = jsonDecode(jsonEncode(event.toJson()));
    print(newData);
    for (var key in eventData.keys) {
      expect(newData[key], equals(eventData[key]));
    }
  });

  // This example illustrates the use of end time zones by use of an international flight.
  // The flight starts on April 1, 2020 at 9 am in Berlin local time.
  // The duration of the flight is scheduled at 10 hours 30 minutes.
  // The time at the flight's destination is in the same time zone as Tokyo.
  // Calendar clients could use the end time zone to display the arrival time in Tokyo local time and highlight the time zone difference of the flight.
  // The location names can serve as input for navigation systems.
  test('Parse event end timezone', () {
    var eventData = {
      "@type": "Event",
      "uid": "flight-xy51-2020",
      "updated": "2020-03-01T09:00:00Z",
      "title": "Flight XY51 to Tokyo",
      "start": "2020-04-01T09:00:00",
      "timeZone": "Europe/Berlin",
      "duration": "PT10H30M",
      "locations": {
        "1": {
          "@type": "Location",
          "rel": "start",
          "name": "Frankfurt Airport (FRA)",
        },
        "2": {
          "@type": "Location",
          "rel": "end",
          "name": "Narita International Airport (NRT)",
          "timeZone": "Asia/Tokyo",
        },
      },
    };

    var event = RFC8984CalendarEvent.fromJson(eventData);
    expect(event.duration, equals(Duration(hours: 10, minutes: 30)));

    var newData = jsonDecode(jsonEncode(event.toJson()));
    print(newData);

    for (var key in eventData.keys) {
      expect(newData[key], equals(eventData[key]));
    }
  });

  test('Parse event localizations', () {
    var eventData = {
      "@type": "Event",
      "uid": "music-bowl-concert-2020",
      "updated": "2020-06-01T14:00:00Z",
      "title": "Live from Music Bowl: The Band",
      "description": "Go see the biggest music event ever!",
      "locale": "en",
      "start": "2020-07-04T17:00:00",
      "timeZone": "America/New_York",
      "duration": "PT3H",
      "locations": {
        "c0503d30-8c50-4372-87b5-7657e8e0fedd": {
          "@type": "Location",
          "name": "The Music Bowl",
          "description": "Music Bowl, Central Park, New York",
          "coordinates": "geo:40.7829,-73.9654",
        },
      },
      "virtualLocations": {
        "vloc1": {
          "@type": "VirtualLocation",
          "name": "Free live Stream from Music Bowl",
          "uri": "https://stream.example.com/the_band_2020",
        },
      },
      "localizations": {
        "de": {
          "title": "Live von der Music Bowl: The Band!",
          "description": "Schau dir das größte Musikereignis an!",
          "virtualLocations/vloc1/name":
              "Gratis Live-Stream aus der Music Bowl",
        },
      },
    };

    var event = RFC8984CalendarEvent.fromJson(eventData);
    expect(event.duration, equals(Duration(hours: 3)));

    var newData = jsonDecode(jsonEncode(event.toJson()));
    print(newData);

    for (var key in eventData.keys) {
      expect(newData[key], equals(eventData[key]));
    }
  });

  test('Parse event recurrence overrides', () {
    var eventData = {
      "@type": "Event",
      "uid": "calculus-course-2020",
      "updated": "2020-01-05T09:00:00Z",
      "title": "Calculus I",
      "start": "2020-01-08T09:00:00",
      "timeZone": "Europe/London",
      "duration": "PT1H30M",
      "locations": {
        "mlab": {
          "@type": "Location",
          "title": "Math lab room 1",
          "description": "Math Lab I, Department of Mathematics",
        },
      },
      "recurrenceRules": [
        {
          "@type": "RecurrenceRule",
          "frequency": "weekly",
          "until": "2020-06-24T09:00:00",
        },
      ],
      "recurrenceOverrides": {
        "2020-01-07T14:00:00": {
          "title": "Introduction to Calculus I (optional)",
        },
        "2020-04-01T09:00:00": {"excluded": true},
        "2020-06-25T09:00:00": {
          "title": "Calculus I Exam",
          "start": "2020-06-25T10:00:00",
          "duration": "PT2H",
          "locations": {
            "auditorium": {
              "@type": "Location",
              "title": "Big Auditorium",
              "description": "Big Auditorium, Other Road",
            },
          },
        },
      },
    };

    var event = RFC8984CalendarEvent.fromJson(eventData);
    expect(event.duration, equals(Duration(hours: 1, minutes: 30)));

    var newData = jsonDecode(jsonEncode(event.toJson()));
    print(newData);

    for (var key in eventData.keys) {
      expect(newData[key], equals(eventData[key]));
    }
  });
}
