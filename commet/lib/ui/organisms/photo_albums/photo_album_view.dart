import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/utils/text_utils.dart';
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

        t.onAdded.listen(onAdded);
        SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
      }
    });

    super.initState();
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
            pollLoadingMorePhotos();
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
                  onPressed: () {},
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

    if (attachment is ImageAttachment) {
      width = attachment.width ?? 500;
      height = attachment.height ?? 500;
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

    var scheme = Theme.of(context).colorScheme;

    if (attachment is VideoAttachment) {
      width = attachment.width ?? 500;
      height = attachment.height ?? 500;

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
        child: result,
      ),
    );
  }
}
