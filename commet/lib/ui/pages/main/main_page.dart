import 'dart:async';
import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/donation_awards/donation_awards_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/voip/voip_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:commet/ui/pages/settings/donation_rewards_confirmation.dart';
import 'package:commet/ui/pages/setup/setup_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/main/main_page_view_desktop.dart';
import 'package:commet/ui/pages/main/main_page_view_mobile.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/utils/first_time_setup.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MainPage extends StatefulWidget {
  const MainPage(this.clientManager,
      {super.key, this.initialClientId, this.initialRoom});
  final ClientManager clientManager;
  final String? initialRoom;
  final String? initialClientId;

  @override
  State<MainPage> createState() => MainPageState();
}

enum MainPageSubView {
  space,
  home,
}

class MainPageState extends State<MainPage> {
  Space? _currentSpace;
  Room? _currentRoom;
  bool showAsTextRoom = false;
  Client? filterClient;

  MainPageSubView _currentView = MainPageSubView.home;

  StreamSubscription? onSpaceUpdateSubscription;
  StreamSubscription? onRoomUpdateSubscription;
  StreamSubscription? onCallStartedSubscription;

  MainPageSubView get currentView => _currentView;

  ClientManager get clientManager => widget.clientManager;

  Profile? get currentUser => getCurrentUser();
  Space? get currentSpace => _currentSpace;
  Room? get currentRoom => _currentRoom;

  VoipSession? get currentCall => currentRoom == null
      ? null
      : widget.clientManager.callManager
          .getCallInRoom(currentRoom!.client, currentRoom!.identifier);

  @override
  void initState() {
    super.initState();

    Client? client;
    if (preferences.filterClient != null) {
      filterClient = clientManager.clients
          .firstWhereOrNull((i) => i.identifier == preferences.filterClient);
    }

    if (widget.initialClientId != null) {
      client = clientManager.getClient(widget.initialClientId!);
    }

    if (client == null && widget.initialRoom != null) {
      client = clientManager.clients
          .where((element) => element.getRoom(widget.initialRoom!) != null)
          .firstOrNull;
    }

    if (client != null && widget.initialRoom != null) {
      var room = client.getRoom(widget.initialRoom!);

      if (filterClient == null || room?.client == filterClient) {
        if (room != null) {
          selectRoom(room);
        }
      }
    }

    // backgroundTaskManager.onListUpdate.listen((event) {
    //   setState(() {});
    // });

    onCallStartedSubscription =
        clientManager.callManager.currentSessions.onListUpdated.listen((event) {
      setState(() {});
    });

    EventBus.openRoom.stream.listen(onOpenRoomSignal);

    EventBus.setFilterClient.stream.listen(setFilterClient);

    EventBus.openUserProfile.stream.listen(onOpenUserProfileSignal);

    SchedulerBinding.instance.scheduleFrameCallback(onFirstFrame);

    checkDonationFlow();
  }

  void onFirstFrame(Duration timeStamp) {
    if (widget.clientManager.isLoggedIn()) {
      var menus = FirstTimeSetup.postLogin;
      if (menus.isNotEmpty) {
        NavigationUtils.navigateTo(context, SetupPage(menus));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Profile? getCurrentUser() {
    if (currentRoom != null) return currentRoom!.client.self!;

    if (currentSpace != null) return currentSpace!.client.self!;

    if (filterClient != null) return filterClient!.self!;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (Layout.mobile) {
      return MainPageViewMobile(this);
    } else {
      return MainPageViewDesktop(this);
    }
  }

  void selectSpace(Space? space) {
    if (space == currentSpace) return;

    if (space != null && !space.fullyLoaded) space.loadExtra();
    clearRoomSelection();

    if (space?.avatar is LODImageProvider) {
      (space!.avatar as LODImageProvider).fetchFullRes();
    }

    onSpaceUpdateSubscription?.cancel();
    setState(() {
      _currentSpace = space;
      _currentView = MainPageSubView.space;
    });

    EventBus.onSelectedSpaceChanged.add(space);
  }

  void selectRoom(Room room, {bool bypassSpecialRoomType = false}) {
    if (room == currentRoom && bypassSpecialRoomType == showAsTextRoom) return;

    onRoomUpdateSubscription?.cancel();

    setState(() {
      _currentRoom = room;
      showAsTextRoom = bypassSpecialRoomType;
    });

    EventBus.onSelectedRoomChanged.add(room);
    EventBus.onSelectedSpaceChanged.add(currentSpace);
  }

  void clearRoomSelection() {
    onRoomUpdateSubscription?.cancel();
    setState(() {
      _currentRoom = null;
    });

    EventBus.onSelectedRoomChanged.add(null);
  }

  void clearSpaceSelection() {
    setState(() {
      clearRoomSelection();

      _currentSpace = null;
      _currentView = MainPageSubView.home;
    });

    EventBus.onSelectedSpaceChanged.add(null);
  }

  void setFilterClient(Client? event) {
    setState(() {
      filterClient = event;

      if (event != null) {
        if (_currentRoom?.client != event) {
          clearRoomSelection();
        }

        if (_currentSpace != null && _currentSpace?.client != event) {
          clearSpaceSelection();
        }
      }
    });
  }

  void callRoom(Room room) {
    var component = room.client.getComponent<VoipComponent>();
    if (component == null) {
      return;
    }

    var direct = room.client.getComponent<DirectMessagesComponent>();
    if (direct == null) {
      Log.w("VOIP Only supports direct messages!!");
      return;
    }

    var partner = direct.getDirectMessagePartnerId(room);

    component.startCall(room.identifier, CallType.voice, userId: partner);
  }

  void selectHome() {
    setState(() {
      _currentView = MainPageSubView.home;
      clearSpaceSelection();
    });
  }

  void onOpenRoomSignal((String, String?) strings) async {
    var roomId = strings.$1;
    var clientId = strings.$2;

    var originalId = roomId;

    Client? client;

    if (clientId != null) {
      client = clientManager.getClient(clientId);

      if (client is MatrixClient) {
        var info = client.parseAddressToIdAndVia(roomId);
        if (info != null) {
          roomId = info.$1;
        }
      }
    } else {
      client = clientManager.clients
          .where((element) => element.hasRoom(roomId))
          .firstOrNull;
    }

    if (client == null) {
      return;
    }

    if (filterClient != null && client != filterClient) {
      askSwitchAccount(client, strings);
      return;
    }

    var room = client.getRoom(roomId);

    if (room == null) {
      room = client.getRoomByAlias(roomId);
    }

    if (room != null) {
      var spacesWithRoom =
          client.spaces.where((element) => element.containsRoom(roomId));

      if (spacesWithRoom.isNotEmpty) {
        selectSpace(spacesWithRoom.first);
      }

      selectRoom(room);
    } else {
      GetOrCreateRoom.show(client, context,
          pickExisting: false,
          showAllRoomTypes: false,
          initialRoomAddress: originalId);
    }
  }

  Future<void> askSwitchAccount(
      Client newClient, (String, String?) strings) async {
    var confirm = await AdaptiveDialog.confirmation(context,
        prompt:
            "You tried to open a room for another account (${newClient.self?.identifier}), would you like to switch?",
        title: "Switch Account");
    if (confirm != true) return;

    EventBus.setFilterClient.add(newClient);
    preferences.setFilterClient(newClient.identifier);
    EventBus.openRoom.add(strings);
  }

  void navigateRoomSettings() {
    if (currentRoom != null) {
      NavigationUtils.navigateTo(
          context,
          RoomSettingsPage(
            room: currentRoom!,
            onLeaveRoom: clearRoomSelection,
          ));
    }
  }

  void onOpenUserProfileSignal((String, String, String?) event) {
    var userId = event.$1;
    var clientId = event.$2;

    var client = clientManager.getClient(clientId);
    if (client != null) {
      UserProfile.show(context, client: client, userId: userId);
    }
  }

  void checkDonationFlow() async {
    var donationCheck = preferences.runningDonationCheckFlow;
    if (donationCheck != null) {
      var client = clientManager.getClient(donationCheck.$1);

      Log.i(
        "Resuming donation flow for user: ${client?.self?.identifier}",
      );

      if (client != null) {
        var secret = await client
            .getComponent<DonationAwardsComponent>()
            ?.getClientSecret();
        if (secret != null) {
          AdaptiveDialog.show(context,
              builder: (context) => DonationRewardsConfirmation(
                    client: client,
                    identifier: secret,
                    didOpenDonationWindow: true,
                    since: donationCheck.$2,
                  ),
              dismissible: false);
        }
      }
    }
  }
}
