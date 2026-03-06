import 'dart:async';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo_album_room_component.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo_album_timeline.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu_dialog.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/photo_albums/photos_upload_view.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:desktop_drop/src/drop_target.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
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

  void onAdded(Photo event) {
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
              padding: EdgeInsets.all(0),
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

    var callback = Layout.desktop
        ? null
        : () {
            if (widget.component is MatrixPhotoAlbumRoomComponent) {
              var event = (item as MatrixPhoto).event;
              var tl = (timeline! as MatrixPhotoAlbumTimeline).matrixTimeline;

              showModalBottomSheet(
                  showDragHandle: true,
                  isScrollControlled: true,
                  elevation: 0,
                  context: context,
                  builder: (context) => TimelineEventMenuDialog(
                        event: event,
                        timeline: tl,
                        menu: TimelineEventMenu(
                          timeline: tl,
                          event: event,
                          onActionFinished: () => Navigator.of(context).pop(),
                        ),
                      ));
            }
          };

    if (attachment is ImageAttachment) {
      result = Stack(
        key: ValueKey("photo-album-image:${item.id}"),
        fit: StackFit.expand,
        children: [
          Image(
            fit: BoxFit.cover,
            image: attachment.image,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Lightbox.show(context, image: attachment.image);
              },
              onLongPress: callback,
            ),
          )
        ],
      );
    }

    if (attachment is VideoAttachment) {
      result = Stack(
        key: ValueKey("photo-album-video:${item.id}"),
        fit: StackFit.expand,
        children: [
          Image(
            fit: BoxFit.cover,
            image: attachment.thumbnail!,
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
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: callback,
              onTap: () {
                Lightbox.show(context,
                    video: attachment.file,
                    aspectRatio: attachment.aspectRatio,
                    thumbnail: attachment.thumbnail);
              },
            ),
          ),
        ],
      );
    }

    if (result != null) {
      if (widget.component is MatrixPhotoAlbumRoomComponent) {
        var menu = TimelineEventMenu(
            timeline: (timeline! as MatrixPhotoAlbumTimeline).matrixTimeline,
            event: (item as MatrixPhoto).event);

        if (Layout.desktop) {
          result = tiamat.ContextMenu(
            items: (menu.primaryActions + menu.secondaryActions)
                .map((e) => tiamat.ContextMenuItem(
                    text: e.name,
                    icon: e.icon,
                    onPressed: () => e.action?.call(context)))
                .toList(),
            child: result,
          );
        }
      }
    }

    if (result == null) {
      print("HOW!");
    }

    return AspectRatio(
      aspectRatio: width / height,
      child: result ?? Placeholder(),
    );
  }

  void uploadImages() async {
    late List<PickedPhoto> photos;

    if (PlatformUtils.isAndroid) {
      final usePhotoPicker = await AdaptiveDialog.pickOne(context,
          items: [true, false],
          itemBuilder: (context, item, onTapped) => SizedBox(
                height: 50,
                child: tiamat.TextButton(
                  item ? "Photos" : "Browse Files",
                  icon: item ? Icons.add_to_photos : Icons.file_open,
                  onTap: onTapped,
                ),
              ));
      if (usePhotoPicker == null) {
        return;
      }

      var picker = ImagePicker();
      late List<XFile> files;

      if (usePhotoPicker) {
        files = await picker.pickMultiImage();
      } else {
        files = await picker.pickMultipleMedia();
      }

      photos = files
          .map((f) => PickedPhoto(
              name: f.name,
              filepath: f.path,
              getBytes: () {
                return f.readAsBytes();
              }))
          .toList();
    } else {
      var files = await FilePicker.platform
          .pickFiles(allowMultiple: true, withReadStream: true);
      if (files == null) return;

      photos = files.files
          .map((e) => PickedPhoto(
                filepath: e.path,
                name: e.name,
                getBytes: () async {
                  var result = List<int>.empty(growable: true);
                  await for (final data in e.readStream!) {
                    print("Read ${data.length} bytes from file");
                    result.addAll(data);
                  }

                  print("Read all ${result.length} bytes");

                  return Uint8List.fromList(result);
                },
              ))
          .toList();
    }

    AdaptiveDialog.show(context,
        builder: (_) => PhotosAlbumUploadView(photos, widget.component));
  }

  void onFileDropped(DropDoneDetails event) {
    var f = event.files
        .map((e) => PickedPhoto(
            filepath: e.path, name: e.name, getBytes: () => e.readAsBytes()))
        .toList();
    AdaptiveDialog.show(context,
        builder: (_) => PhotosAlbumUploadView(f, widget.component));
  }

  void onChanged(Photo event) {
    setState(() {
      numItems = timeline!.photos.length;
    });
  }

  void onRemoved(Photo event) {
    setState(() {
      numItems = timeline!.photos.length;
    });
  }
}
