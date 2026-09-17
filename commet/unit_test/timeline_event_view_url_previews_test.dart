import 'dart:async';

import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_url_previews.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/url_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class _FakeEvent implements TimelineEvent {
  _FakeEvent(this.status, {this.eventId = r'$event'});

  @override
  TimelineEventStatus status;

  @override
  final String eventId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTimeline extends Timeline {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeComponent implements UrlPreviewComponent {
  int getPreviewCalls = 0;
  final List<String> requested = [];
  Completer<UrlPreviewData?>? pending;
  UrlPreviewData? result = preview;
  Object? error;

  static final preview = UrlPreviewData(
    Uri.parse('https://example.com/page'),
    title: 'Resolved title',
    type: UrlDestinationType.page,
  );

  @override
  UrlPreviewData? getCachedPreview(Timeline timeline, TimelineEvent event) =>
      null;

  @override
  Future<UrlPreviewData?> getPreview(
      Timeline timeline, TimelineEvent event) async {
    getPreviewCalls++;
    requested.add(event.eventId);
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _testApp(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const [ThemeSettings()],
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  late _FakeEvent event;
  late _FakeTimeline timeline;
  late _FakeComponent component;
  final previewKey = GlobalKey();

  setUp(() {
    event = _FakeEvent(TimelineEventStatus.sending);
    timeline = _FakeTimeline()..events = [event];
    component = _FakeComponent();
  });

  Widget preview() => TimelineEventViewUrlPreviews(
        key: previewKey,
        event: event,
        timeline: timeline,
        component: component,
      );

  testWidgets('does not fetch while the event is still sending',
      (tester) async {
    await tester.pumpWidget(_testApp(preview()));
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 0);
    expect(find.text('Resolved title'), findsNothing);
  });

  testWidgets('fetches once the parent rebuilds with the event synced',
      (tester) async {
    late StateSetter rebuildParent;
    await tester.pumpWidget(_testApp(StatefulBuilder(builder: (_, setState) {
      rebuildParent = setState;
      return preview();
    })));
    await tester.pumpAndSettle();

    // TimelineEventViewMessage.update calls setState, rebuilding the preview
    // with the same key once the event's status has changed.
    event.status = TimelineEventStatus.synced;
    rebuildParent(() {});
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 1);
    expect(find.text('Resolved title'), findsOneWidget);
  });

  testWidgets('fetches when update is called with the event synced',
      (tester) async {
    await tester.pumpWidget(_testApp(preview()));
    await tester.pumpAndSettle();

    event.status = TimelineEventStatus.synced;
    (previewKey.currentState as TimelineEventViewWidget).update(0);
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 1);
    expect(find.text('Resolved title'), findsOneWidget);
  });

  testWidgets('does not refetch on rebuilds after the preview resolved',
      (tester) async {
    event.status = TimelineEventStatus.synced;
    late StateSetter rebuildParent;
    await tester.pumpWidget(_testApp(StatefulBuilder(builder: (_, setState) {
      rebuildParent = setState;
      return preview();
    })));
    await tester.pumpAndSettle();

    rebuildParent(() {});
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 1);
    expect(find.text('Resolved title'), findsOneWidget);
  });

  testWidgets('does not start a second fetch while one is in flight',
      (tester) async {
    component.pending = Completer();
    late StateSetter rebuildParent;
    await tester.pumpWidget(_testApp(StatefulBuilder(builder: (_, setState) {
      rebuildParent = setState;
      return preview();
    })));

    event.status = TimelineEventStatus.synced;
    rebuildParent(() {});
    await tester.pump();
    rebuildParent(() {});
    await tester.pump();

    component.pending!.complete(_FakeComponent.preview);
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 1);
    expect(find.text('Resolved title'), findsOneWidget);
  });

  testWidgets('only fetches its own message after newer messages arrive',
      (tester) async {
    // The message view hands the preview an index that is only refreshed by
    // update(), and an insertion at the bottom only updates its neighbours.
    late StateSetter rebuildParent;
    await tester.pumpWidget(_testApp(StatefulBuilder(builder: (_, setState) {
      rebuildParent = setState;
      return preview();
    })));
    await tester.pumpAndSettle();

    timeline.events
        .insert(0, _FakeEvent(TimelineEventStatus.synced, eventId: r'$newer'));
    rebuildParent(() {});
    await tester.pumpAndSettle();

    expect(component.requested, isNot(contains(r'$newer')));
    expect(find.text('Resolved title'), findsNothing);
  });

  Future<StateSetter> pumpSynced(WidgetTester tester) async {
    event.status = TimelineEventStatus.synced;
    late StateSetter rebuildParent;
    await tester.pumpWidget(_testApp(StatefulBuilder(builder: (_, setState) {
      rebuildParent = setState;
      return preview();
    })));
    await tester.pumpAndSettle();
    return rebuildParent;
  }

  testWidgets('a failed fetch leaves nothing on screen and is not retried',
      (tester) async {
    component.error = Exception('preview server is down');
    final rebuildParent = await pumpSynced(tester);

    rebuildParent(() {});
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 1);
    expect(find.byType(UrlPreviewWidget), findsNothing);
  });

  testWidgets('a link without a preview leaves nothing on screen',
      (tester) async {
    // e.g. an encrypted room with previews turned off
    component.result = null;
    final rebuildParent = await pumpSynced(tester);

    rebuildParent(() {});
    await tester.pumpAndSettle();

    expect(component.getPreviewCalls, 1);
    expect(find.byType(UrlPreviewWidget), findsNothing);
  });
}
