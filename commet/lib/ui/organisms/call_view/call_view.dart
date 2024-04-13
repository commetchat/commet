import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/layout/bento.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CallView extends StatefulWidget {
  const CallView(this.currentSession, {super.key});
  final VoipSession currentSession;

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  Timer? statTimer;
  StreamSubscription? sub;

  VoipStream? mainStream;

  @override
  void initState() {
    super.initState();
    sub = widget.currentSession.onStateChanged.listen((event) {
      setState(() {});
    });

    //mainStream = widget.currentSession.remoteUserMediaStream;

    statTimer = Timer.periodic(const Duration(milliseconds: 200), timer);
  }

  @override
  void dispose() {
    statTimer?.cancel();
    sub?.cancel();
    super.dispose();
  }

  void timer(Timer timer) async {
    await widget.currentSession.updateStats();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.currentSession.state) {
      case VoipState.connected:
        return callConnectedView();

      default:
        return const Placeholder();
    }
  }

  // Widget incomingCallView() {
  //   // return LayoutBuilder(builder:(context, constraints) {
  //   //   constraints.
  //   // },);
  // }

  Widget callConnectedView() {
    return tiamat.Tile.low4(
      child: Row(
        children: [
          if (mainStream != null)
            Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        mainStream = null;
                      });
                    },
                    child: VoipStreamView(
                      mainStream!,
                      widget.currentSession,
                      borderColor: Colors.white,
                      onFullscreen: () {
                        Lightbox.show(context,
                            aspectRatio: mainStream!.aspectRatio,
                            customWidget: VoipStreamView(
                                mainStream!, widget.currentSession));
                      },
                      fit: BoxFit.contain,
                      key: ValueKey(
                          "callView_mainStreamView_${mainStream!.streamId}"),
                    ),
                  ),
                ),
              ),
            ),

          Flexible(
            fit: FlexFit.tight,
            child: Center(
              child: BentoLayout(widget.currentSession.streams
                  .where((element) => element != mainStream)
                  .map((e) => GestureDetector(
                      onTap: () {
                        setState(() {
                          mainStream = e;
                        });
                      },
                      child: VoipStreamView(
                        key: ValueKey("callView__${e.streamId}"),
                        e,
                        widget.currentSession,
                        onFullscreen: () {
                          Lightbox.show(context,
                              aspectRatio: e.aspectRatio,
                              customWidget:
                                  VoipStreamView(e, widget.currentSession));
                        },
                      )))
                  .toList()),
            ),
          )

          // child: Column(
          //     children: widget.currentSession.streams
          //         .where((element) => element != mainStream)
          //         .map((e) => Expanded(
          //               child: GestureDetector(
          //                 onTap: () {
          //                   setState(() {
          //                     mainStream = e;
          //                   });
          //                 },
          //                 child: Padding(
          //                   padding: const EdgeInsets.all(2.0),
          //                   child: VoipStreamView(e, widget.currentSession,
          //                       onFullscreen: () {
          //                     Lightbox.show(context,
          //                         aspectRatio: e.aspectRatio,
          //                         customWidget: VoipStreamView(
          //                             e, widget.currentSession));
          //                   },
          //                       fit: BoxFit.cover,
          //                       key: ValueKey(
          //                           "callView__${mainStream!.streamId}")),
          //                 ),
          //               ),
          //             ))
          //         .toList()),
        ],
      ),
    );

    // return Wrap(
    //   children: widget.currentSession.streams
    //       .map((e) => SizedBox(
    //           width: 200,
    //           height: 200,
    //           child: VoipStreamView(e, widget.currentSession)))
    //       .toList(),
    // );
    // return GridView.builder(
    //   gridDelegate:
    //       const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    //   itemBuilder: (context, index) {
    //     var stream = widget.currentSession.streams[index];

    //     return tiamat.Tile.low3(
    //         child: VoipStreamView(stream, widget.currentSession));
    //   },
    //   itemCount: widget.currentSession.streams.length,
    // );
  }
}
