import 'package:commet/client/client.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/matrix/components/calendar_room_component/matrix_calendar_room_component.dart';
import 'package:commet/client/space_child.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class ExistingRoomPicker extends StatefulWidget {
  const ExistingRoomPicker(
      {required this.client, this.filter, this.onPicked, super.key});

  final Client client;
  final bool Function(SpaceChild room)? filter;
  final Function(SpaceChild child)? onPicked;

  @override
  State<ExistingRoomPicker> createState() => _ExistingRoomPickerState();
}

class _ExistingRoomPickerState extends State<ExistingRoomPicker> {
  List<SpaceChild> allChildren = List.empty(growable: true);
  List<SpaceChild> filteredChildren = List.empty();
  Set<RoomType> selectedTypes = {};

  @override
  void initState() {
    for (var room in widget.client.rooms) {
      allChildren.add(SpaceChildRoom(room));
    }

    for (var space in widget.client.spaces) {
      allChildren.add(SpaceChildSpace(space));
    }

    if (widget.filter != null) {
      allChildren.removeWhere(widget.filter!);
    }

    setSelectedTypes(selectedTypes);

    super.initState();
  }

  void setSelectedTypes(Set<RoomType> types) {
    List<SpaceChild> filtered = List.empty(growable: true);

    if (types.isEmpty) {
      filtered = allChildren;
    } else {
      if (types.contains(RoomType.space))
        filtered.addAll(allChildren.where((i) => i is SpaceChildSpace));

      if (types.contains(RoomType.voipRoom))
        filtered.addAll(allChildren.where((i) {
          if (i case SpaceChildRoom r) {
            return r.child.getComponent<VoipRoomComponent>() != null;
          }
          return false;
        }));

      if (types.contains(RoomType.calendar))
        filtered.addAll(allChildren.where((i) {
          if (i case SpaceChildRoom r) {
            return r.child
                    .getComponent<MatrixCalendarRoomComponent>()
                    ?.isCalendarRoom ==
                true;
          }
          return false;
        }));

      if (types.contains(RoomType.photoAlbum))
        filtered.addAll(allChildren.where((i) {
          if (i case SpaceChildRoom r) {
            return r.child.getComponent<PhotoAlbumRoom>() != null;
          }
          return false;
        }));

      if (types.contains(RoomType.defaultRoom))
        filtered.addAll(allChildren.where((i) {
          if (i case SpaceChildRoom r) {
            return r.child.isSpecialRoomType == false;
          }
          return false;
        }));
    }

    setState(() {
      selectedTypes = types;
      filteredChildren = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.all(8),
          child: SegmentedButton(
              emptySelectionAllowed: true,
              multiSelectionEnabled: false,
              segments: [
                ButtonSegment(
                  tooltip: "Space",
                  value: RoomType.space,
                  icon: Icon(Icons.spoke),
                ),
                ButtonSegment(
                  tooltip: "Text Chat",
                  value: RoomType.defaultRoom,
                  icon: Icon(Icons.tag),
                ),
                ButtonSegment(
                  tooltip: "Voice Chat",
                  value: RoomType.voipRoom,
                  icon: Icon(Icons.volume_up),
                ),
                ButtonSegment(
                  tooltip: "Photo Album",
                  value: RoomType.photoAlbum,
                  icon: Icon(Icons.photo),
                ),
                ButtonSegment(
                  tooltip: "Calendar",
                  value: RoomType.calendar,
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              onSelectionChanged: setSelectedTypes,
              selected: selectedTypes),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredChildren.length,
            itemBuilder: (context, index) {
              var child = filteredChildren[index];

              String displayName = "";
              Color color = Colors.white;
              ImageProvider? avatar;

              switch (child) {
                case SpaceChildRoom r:
                  displayName = r.child.displayName;
                  color = r.child.defaultColor;
                  avatar = r.child.avatar;
                  break;

                case SpaceChildSpace s:
                  displayName = s.child.displayName;
                  color = s.child.color;
                  avatar = s.child.avatar;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Material(
                  child: InkWell(
                    onTap: () {
                      print(child);
                      widget.onPicked?.call(child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tiamat.Avatar(
                              image: avatar,
                              placeholderText: displayName,
                              placeholderColor: color),
                          SizedBox(
                            width: 8,
                          ),
                          Column(
                            children: [tiamat.Text.label(displayName)],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
