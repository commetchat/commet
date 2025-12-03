import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:iso_duration/iso_duration.dart';
part 'rfc8984.g.dart';

class IsoDurationConverter extends JsonConverter<Duration, String> {
  const IsoDurationConverter();

  @override
  Duration fromJson(String json) {
    return tryParseIso8601Duration(json)!;
  }

  @override
  String toJson(Duration object) {
    return object.toIso8601String();
  }
}

class IsoDateTimeConverter extends JsonConverter<DateTime, String> {
  const IsoDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    if (object.isUtc) {
      DateFormat formatter = DateFormat("yyyy-MM-ddTHH:mm:ss");
      var result = formatter.format(object) + "Z";
      return result;
    } else {
      DateFormat formatter = DateFormat("yyyy-MM-ddTHH:mm:ss");
      return formatter.format(object);
    }
  }
}

@JsonSerializable(includeIfNull: false)
class RFC8984CalendarEvent {
  static const String type = "Event";
  String uid;

  @IsoDateTimeConverter()
  DateTime updated;
  String title;

  String? description;

  @IsoDateTimeConverter()
  DateTime start;
  String? timeZone;

  @IsoDurationConverter()
  Duration duration;

  String? locale;

  List<RFC8984RecurrenceRule>? recurrenceRules;
  Map<String, dynamic>? recurrenceOverrides;

  Map<String, RFC8984Location>? locations;
  Map<String, RFC8984VirtualLocation>? virtualLocations;

  Map<String, Map<String, String>>? localizations;

  RFC8984CalendarEvent({
    required this.uid,
    required this.updated,
    required this.title,
    this.description,
    required this.start,
    required this.duration,
    this.timeZone,
    this.recurrenceRules,
    this.locations,
    this.virtualLocations,
    this.localizations,
    this.recurrenceOverrides,
  });

  factory RFC8984CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$RFC8984CalendarEventFromJson(json);

  Map<String, dynamic> toJson() {
    var data = _$RFC8984CalendarEventToJson(this);
    data["@type"] = type;
    return data;
  }
}

@JsonSerializable(includeIfNull: false)
class RFC8984Location {
  static const String type = "Location";

  String? rel;
  String? name;
  String? title;
  String? timeZone;
  String? description;
  String? coordinates;

  RFC8984Location({
    this.rel,
    this.name,
    this.title,
    this.timeZone,
    this.description,
    this.coordinates,
  });

  factory RFC8984Location.fromJson(Map<String, dynamic> json) =>
      _$RFC8984LocationFromJson(json);

  Map<String, dynamic> toJson() {
    var data = _$RFC8984LocationToJson(this);
    data["@type"] = type;
    return data;
  }
}

@JsonSerializable(includeIfNull: false)
class RFC8984VirtualLocation {
  static const String type = "VirtualLocation";

  String? rel;
  String? name;
  String? timeZone;
  String? uri;

  RFC8984VirtualLocation({this.rel, this.name, this.timeZone});

  factory RFC8984VirtualLocation.fromJson(Map<String, dynamic> json) =>
      _$RFC8984VirtualLocationFromJson(json);

  Map<String, dynamic> toJson() {
    var data = _$RFC8984VirtualLocationToJson(this);
    data["@type"] = type;
    return data;
  }
}

@JsonSerializable(includeIfNull: false)
class Rfc8984NDay {
  static const String type = "NDay";
  String day;
  int? nthOfPeriod;

  Rfc8984NDay(this.day, {this.nthOfPeriod});

  factory Rfc8984NDay.fromJson(Map<String, dynamic> json) =>
      _$Rfc8984NDayFromJson(json);

  Map<String, dynamic> toJson() {
    var data = _$Rfc8984NDayToJson(this);
    data["@type"] = type;
    return data;
  }
}

@JsonSerializable(
  includeIfNull: false,
)
class RFC8984RecurrenceRule {
  static const String type = "RecurrenceRule";

  String frequency;

  int? interval;

  String? rscale;

  String? skip;

  String? firstDayOfWeek;

  List<Rfc8984NDay>? byDay;
  List<int>? byMonthDay;
  List<String>? byMonth;
  List<int>? byYearDay;
  List<int>? byWeekNo;
  List<int>? byHour;
  List<int>? byMinute;
  List<int>? bySecond;
  List<int>? bySetPos;

  int? count;

  @IsoDateTimeConverter()
  DateTime? until;

  RFC8984RecurrenceRule({
    required this.frequency,
    this.until,
    this.interval,
    this.rscale,
    this.skip,
    this.firstDayOfWeek,
    this.byDay,
    this.byMonthDay,
    this.byMonth,
    this.byYearDay,
    this.byWeekNo,
    this.byHour,
    this.byMinute,
    this.bySecond,
    this.bySetPos,
    this.count,
  });

  factory RFC8984RecurrenceRule.fromJson(Map<String, dynamic> json) =>
      _$RFC8984RecurrenceRuleFromJson(json);

  Map<String, dynamic> toJson() {
    var data = _$RFC8984RecurrenceRuleToJson(this);
    data["@type"] = type;
    return data;
  }

  @override
  String toString() {
    if (frequency == "monthly") {
      return "Repeats Monthly";
    }

    if (frequency == "daily") {
      return "Repeats Daily";
    }

    if (frequency == "weekly") {
      if (byDay == null) {
        return "Repeats Weekly";
      }
      var days = [
        if (byDay!.any((i) => i.day == "mo") == true) "Mon",
        if (byDay!.any((i) => i.day == "tu") == true) "Tue",
        if (byDay!.any((i) => i.day == "we") == true) "Wed",
        if (byDay!.any((i) => i.day == "th") == true) "Thur",
        if (byDay!.any((i) => i.day == "fr") == true) "Fri",
        if (byDay!.any((i) => i.day == "sa") == true) "Sat",
        if (byDay!.any((i) => i.day == "su") == true) "Sun",
      ];
      var weekdays = days.join(", ");

      return "Repeats Weekly on ${weekdays}";
    }

    if (frequency == "yearly") {
      return "Repeats Yearly";
    }

    return "Unknown Repeat Rule";
  }
}
