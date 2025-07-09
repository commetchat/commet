import 'dart:async';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_upload_photos_task.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:desktop_drop/src/drop_target.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class PhotoAlbumView extends StatefulWidget {
  const PhotoAlbumView(this.component, {super.key});
  final PhotoAlbumRoom component;

  @override
  State<PhotoAlbumView> createState() => _PhotoAlbumViewState();
}

class _PhotoAlbumViewState extends State<PhotoAlbumView> {
  PhotoAlbumTimeline? timeline;
  var numItems = 0;
  bool loadingMorePhotos = false;
  var controller = ScrollController();

  late List<StreamSubscription> subs;

  void onAdded(int event) {
    setState(() {
      numItems = timeline!.photos.length;
    });
  }

  @override
  void initState() {
    controller.addListener(onScroll);

    widget.component.getTimeline().then((t) {
      if (mounted) {
        setState(() {
          timeline = t;
          numItems = t.photos.length;
        });

        subs = [
          t.onAdded.listen(onAdded),
          t.onChanged.listen(onChanged),
          t.onRemoved.listen(onRemoved),
          EventBus.onFileDropped.stream.listen(onFileDropped),
        ];
        SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void postFrameCallback(Duration timeStamp) {
    pollLoadingMorePhotos();
  }

  void onScroll() {
    pollLoadingMorePhotos();
  }

  void pollLoadingMorePhotos() {
    if (loadingMorePhotos) return;
    if (timeline?.canLoadMorePhotos != true) return;

    if ((controller.position.maxScrollExtent - controller.position.pixels) <
        20) {
      setState(() {
        loadingMorePhotos = true;
        timeline?.loadMorePhotos().then((_) {
          if (mounted) {
            setState(() {
              loadingMorePhotos = false;
            });

            Future.delayed(Duration(seconds: 1)).then((_) {
              pollLoadingMorePhotos();
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (timeline == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(8),
            child: MasonryGridView.extent(
              crossAxisSpacing: 8,
              controller: controller,
              mainAxisSpacing: 8,
              maxCrossAxisExtent: 250,
              itemCount: numItems,
              itemBuilder: (context, index) {
                var item = timeline!.photos[index];
                return ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(8),
                  child: buildAttachment(item),
                );
              },
            ),
          ),
          if (loadingMorePhotos)
            ScaledSafeArea(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CircularProgressIndicator()),
            ),
          if (widget.component.canUpload)
            ScaledSafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: uploadImages,
                  child: Icon(Icons.add),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget buildAttachment(Photo item) {
    var width = 500.0;
    var height = 500.0;

    Widget? result;
    var attachment = item.attachment;
    width = item.width ?? 500;
    height = item.height ?? 500;

    var scheme = Theme.of(context).colorScheme;

    if (attachment == null) {
      if (item.status == TimelineEventStatus.sending) {
        result = Container(
          color: scheme.surfaceContainerLow,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (item.status == TimelineEventStatus.error) {
        result = Container(
          color: scheme.surfaceContainerLow,
          child: Center(
              child: Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.error,
          )),
        );
      }
    }

    if (attachment is ImageAttachment) {
      result = InkWell(
        onTap: () {
          Lightbox.show(context, image: attachment.image);
        },
        child: Image(
          fit: BoxFit.cover,
          image: attachment.image,
        ),
      );
    }

    if (attachment is VideoAttachment) {
      result = Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: () {
              Lightbox.show(context,
                  video: attachment.file,
                  aspectRatio: attachment.aspectRatio,
                  thumbnail: attachment.thumbnail);
            },
            child: Image(
              fit: BoxFit.cover,
              image: attachment.thumbnail!,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: scheme.secondaryContainer),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: scheme.onSecondaryContainer,
                        size: 12,
                      ),
                      tiamat.Text.tiny(
                        attachment.duration != null
                            ? TextUtils.formatDuration(attachment.duration!)
                            : "Video",
                        color: scheme.onSecondaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: width / height,
        child: result!,
      ),
    );
  }

  void uploadImages() {
    FilePicker.platform.pickFiles();
  }

  void onFileDropped(DropDoneDetails event) {
    var files = event.files.map((e) => Uri.parse(e.path)).toList();

    var task =
        MatrixUploadPhotosTask(files, widget.component.room as MatrixRoom);

    backgroundTaskManager.addTask(task);

    task.uploadImages();
  }

  void onChanged(int event) {
    setState(() {
      numItems = timeline!.photos.length;
    });
  }

  void onRemoved(int event) {
    setState(() {
      numItems = timeline!.photos.length;
    });
  }
}
