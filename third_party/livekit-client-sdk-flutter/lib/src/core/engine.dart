// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../e2ee/e2ee_manager.dart';
import '../e2ee/options.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../internal/types.dart';
import '../logger.dart' show logger;
import '../managers/event.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../publication/local.dart';
import '../support/disposable.dart';
import '../support/platform.dart' show lkPlatformIsTest, lkPlatformIs, PlatformType;
import '../support/region_url_provider.dart';
import '../support/websocket.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';
import '../types/internal.dart';
import '../types/other.dart';
import '../utils/data_packet_buffer.dart';
import '../utils/ttl_map.dart';
import 'signal_client.dart';
import 'transport.dart';

const maxRetryDelay = 7000;

const defaultRetryDelaysInMs = [
  0,
  300,
  2 * 2 * 300,
  3 * 3 * 300,
  4 * 4 * 300,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
];

class Engine extends Disposable with EventsEmittable<EngineEvent> {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  @internal
  final SignalClient signalClient;

  final PeerConnectionCreate _peerConnectionCreate;

  @internal
  Transport? publisher;

  @internal
  Transport? subscriber;

  @internal
  Transport? get primary => _subscriberPrimary ? subscriber : publisher;

  rtc.RTCDataChannel? get dataChannel =>
      _subscriberPrimary ? _reliableDCSub ?? _lossyDCSub : _reliableDCPub ?? _lossyDCPub;

  // data channels for packets
  rtc.RTCDataChannel? _reliableDCPub;
  rtc.RTCDataChannel? _lossyDCPub;
  rtc.RTCDataChannel? _reliableDCSub;
  rtc.RTCDataChannel? _lossyDCSub;

  /// Connection state of the [Room].
  ConnectionState get connectionState => signalClient.connectionState;

  // true if publisher connection has already been established.
  // this is helpful to know if we need to restart ICE on the publisher connection
  bool _hasPublished = false;

  lk_models.ClientConfiguration? _clientConfiguration;

  // remember url and token for reconnect
  String? url;
  String? token;

  ConnectOptions connectOptions;
  RoomOptions roomOptions;
  FastConnectOptions? fastConnectOptions;

  bool _subscriberPrimary = false;

  String? _connectedServerAddress;
  String? get connectedServerAddress => _connectedServerAddress;

  bool fullReconnectOnNext = false;

  // server-provided ice servers
  List<RTCIceServer> _serverProvidedIceServers = [];

  late EventsListener<SignalEvent> _signalListener = signalClient.createListener(synchronized: true);

  int? reconnectAttempts;

  Timer? reconnectTimeout;
  DateTime? reconnectStart;

  bool _isClosed = false;

  bool get isClosed => _isClosed;

  bool get isPendingReconnect => reconnectStart != null && reconnectTimeout != null;

  final int _reconnectCount = defaultRetryDelaysInMs.length;

  bool attemptingReconnect = false;

  RegionUrlProvider? _regionUrlProvider;

  lk_models.ServerInfo? _serverInfo;

  lk_models.ServerInfo? get serverInfo => _serverInfo;

  final Map<Reliability, bool> _dcBufferStatus = {
    Reliability.reliable: true,
    Reliability.lossy: false,
  };

  List<lk_models.Codec>? _enabledPublishCodecs;

  List<lk_models.Codec>? get enabledPublishCodecs => _enabledPublishCodecs;

  E2EEManager? _e2eeManager;

  E2EEManager? get e2eeManager => _e2eeManager;

  void setE2eeManager(E2EEManager? e2eeManager) {
    _e2eeManager = e2eeManager;
  }

  // E2E reliability for data channels
  int _reliableDataSequence = 1;
  final DataPacketBuffer _reliableMessageBuffer = DataPacketBuffer(
    maxBufferSize: 64 * 1024 * 1024, // 64MB
    maxPacketCount: 1000, // max 1000 packets
  );
  final TTLMap<String, int> _reliableReceivedState = TTLMap<String, int>(30000);
  bool _isReconnecting = false;

  Completer<void>? _publisherConnectionCompleter;

  String? _reliableParticipantKey(lk_models.DataPacket packet) {
    if (packet.hasParticipantSid() && packet.participantSid.isNotEmpty) {
      return packet.participantSid;
    }
    logger.fine(
        'Reliable packet missing participant SID (identity: ${packet.participantIdentity}), skipping dedupe handling');
    return null;
  }

  void clearReconnectTimeout() {
    if (reconnectTimeout != null) {
      reconnectTimeout?.cancel();
      reconnectTimeout = null;
    }
  }

  void clearPendingReconnect() {
    clearReconnectTimeout();
    reconnectAttempts = 0;
    reconnectStart = null;
  }

  Engine({
    required this.connectOptions,
    required this.roomOptions,
    SignalClient? signalClient,
    PeerConnectionCreate? peerConnectionCreate,
    E2EEManager? e2eeManager,
  })  : signalClient = signalClient ?? SignalClient(LiveKitWebSocket.connect),
        _peerConnectionCreate = peerConnectionCreate ?? rtc.createPeerConnection,
        _e2eeManager = e2eeManager {
    if (kDebugMode) {
      // log all EngineEvents
      events.listen((event) => logger.fine('[EngineEvent] $objectId $event'));
    }

    _setUpEngineListeners();
    _setUpSignalListeners();

    onDispose(() async {
      _isClosed = true;
      await cleanUp();
      await events.dispose();
      await _signalListener.dispose();
      _reliableReceivedState.dispose();
    });
  }

  Future<void> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
    FastConnectOptions? fastConnectOptions,
    RegionUrlProvider? regionUrlProvider,
  }) async {
    this.url = url;
    this.token = token;
    // update new options (if exists)
    this.connectOptions = connectOptions ?? this.connectOptions;
    this.roomOptions = roomOptions ?? this.roomOptions;
    this.fastConnectOptions = fastConnectOptions;

    if (regionUrlProvider != null) {
      _regionUrlProvider = regionUrlProvider;
    }

    //reset state
    _isClosed = false;

    try {
      // wait for socket to connect rtc server
      await signalClient.connect(
        url,
        token,
        connectOptions: this.connectOptions,
        roomOptions: this.roomOptions,
      );

      // wait for join response
      await events.waitFor<EngineJoinResponseEvent>(
        duration: this.connectOptions.timeouts.connection,
        onTimeout: () => throw ConnectException('Timed out waiting for SignalJoinResponseEvent',
            reason: ConnectionErrorReason.Timeout),
      );

      logger.fine('Waiting for engine to connect...');

      // wait until primary pc is connected
      await events.waitFor<EnginePeerStateUpdatedEvent>(
        filter: (event) => event.isPrimary && event.state.isConnected(),
        duration: this.connectOptions.timeouts.connection,
        onTimeout: () => throw MediaConnectException(
            'Timed out waiting for PeerConnection to connect, please check your network for ice connectivity'),
      );
      events.emit(const EngineConnectedEvent());
    } catch (error) {
      logger.fine('Connect Error $error');

      events.emit(EngineDisconnectedEvent(
        reason: DisconnectReason.joinFailure,
      ));
      rethrow;
    }
  }

  // resets internal state to a re-usable state
  Future<void> cleanUp() async {
    logger.fine('[$objectId] cleanUp()');

    await publisher?.dispose();
    publisher = null;
    _hasPublished = false;

    await subscriber?.dispose();
    subscriber = null;

    await signalClient.cleanUp();

    fullReconnectOnNext = false;
    attemptingReconnect = false;

    // Reset reliability state
    _reliableDataSequence = 1;
    _reliableMessageBuffer.clear();
    _reliableReceivedState.clear();
    _isReconnecting = false;

    clearPendingReconnect();
  }

  @internal
  Future<lk_models.TrackInfo> addTrack(lk_rtc.AddTrackRequest req) async {
    // send request to add track
    signalClient.sendAddTrack(req);

    // wait for response, or timeout
    final event = await _signalListener.waitFor<SignalLocalTrackPublishedEvent>(
      filter: (event) => event.cid == req.cid,
      duration: connectOptions.timeouts.publish,
      onTimeout: () => throw TrackPublishException(),
    );

    return event.track;
  }

  @internal
  Future<void> negotiate({bool? iceRestart}) async {
    if (publisher == null) {
      return;
    }
    _hasPublished = true;
    try {
      publisher!.negotiate(null);
    } catch (error) {
      if (error is NegotiationError) {
        fullReconnectOnNext = true;
      }
      await handleReconnect(
        ClientDisconnectReason.negotiationFailed,
        reconnectReason: lk_models.ReconnectReason.RR_UNKNOWN,
      );
    }
  }

  bool? isBufferStatusLow(Reliability kind) {
    final dc = _publisherDataChannel(kind);
    if (dc != null) {
      return dc.bufferedAmount! <= dc.bufferedAmountLowThreshold!;
    }
    return null;
  }

  Future<void> waitForBufferStatusLow(Reliability kind) async {
    final Completer<void> completer = Completer();

    if (isBufferStatusLow(kind) == true) {
      completer.complete();
    } else {
      onClosing() {
        if (!completer.isCompleted) {
          completer.completeError('Engine disconnected');
        }
      }

      events.once<EngineClosingEvent>((e) => onClosing());

      while (!_dcBufferStatus[kind]!) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      if (completer.isCompleted) {
        return;
      }
      completer.complete();
    }

    return completer.future;
  }

  Future<void> _resendReliableMessagesForResume(int lastMessageSeq) async {
    logger.fine('Resending reliable messages from sequence $lastMessageSeq');

    final channel = _publisherDataChannel(Reliability.reliable);
    if (channel == null) {
      logger.warning('Reliable data channel is null, cannot resend messages');
      return;
    }

    // Remove acknowledged messages from buffer
    _reliableMessageBuffer.popToSequence(lastMessageSeq);

    // Get remaining messages to resend
    final messagesToResend = _reliableMessageBuffer.getAll();

    if (messagesToResend.isEmpty) {
      logger.fine('No reliable messages to resend');
      return;
    }

    logger.fine('Resending ${messagesToResend.length} reliable messages');

    for (final item in messagesToResend) {
      try {
        await channel.send(item.message);
        logger.fine('Resent reliable message with sequence ${item.sequence}');
      } catch (e) {
        logger.warning('Failed to resend reliable message ${item.sequence}: $e');
      }
    }
  }

  @internal
  Future<void> sendDataPacket(
    lk_models.DataPacket packet, {
    Reliability reliability = Reliability.lossy,
  }) async {
    // Add sequence number for reliable packets
    if (reliability == Reliability.reliable) {
      packet.sequence = _reliableDataSequence++;
    }

    // construct the data channel message
    var message = rtc.RTCDataChannelMessage.fromBinary(packet.writeToBuffer());

    if (_subscriberPrimary) {
      // make sure publisher transport is connected
      await ensurePublisherConnected();

      // wait for data channel to open (if not already)
      if (_publisherDataChannelState(reliability) != rtc.RTCDataChannelState.RTCDataChannelOpen) {
        logger.fine('Waiting for data channel ${reliability} to open...');
        await events.waitFor<PublisherDataChannelStateUpdatedEvent>(
          filter: (event) => event.type == reliability,
          duration: connectOptions.timeouts.connection,
        );
      }
    }

    // chose data channel
    final rtc.RTCDataChannel? channel = _publisherDataChannel(reliability);

    if (channel == null) {
      throw UnexpectedStateException('Data channel for ${packet.kind.toSDKType()} is null');
    }

    if (_e2eeManager != null && _e2eeManager!.isDataChannelEncryptionEnabled) {
      final encryptablePacket = asEncryptablePacket(packet);
      if (encryptablePacket != null) {
        final encryptedData = await _e2eeManager?.encryptData(data: encryptablePacket.writeToBuffer());

        if (encryptedData == null) {
          logger.warning('Failed to encrypt data packet');
          return;
        }

        final encryptedPacket = lk_models.EncryptedPacket(
          encryptionType: lk_models.Encryption_Type.GCM,
          encryptedValue: encryptedData.data,
          iv: encryptedData.iv,
          keyIndex: encryptedData.keyIndex,
        );

        final dataToSend = lk_models.DataPacket(
          participantIdentity: packet.participantIdentity,
          kind: packet.kind,
          encryptedPacket: encryptedPacket,
          destinationIdentities: packet.destinationIdentities,
          sequence: packet.hasSequence() ? packet.sequence : null,
          participantSid: packet.hasParticipantSid() ? packet.participantSid : null,
        );

        message = rtc.RTCDataChannelMessage.fromBinary(dataToSend.writeToBuffer());
      }
    }

    // Buffer reliable packets for potential resending
    if (reliability == Reliability.reliable) {
      _reliableMessageBuffer.push(BufferedDataPacket(
        packet: packet,
        message: message,
        sequence: packet.sequence,
      ));
    }

    // Don't send during reconnection, but keep message buffered for resending
    if (_isReconnecting) {
      logger.fine('Deferring data packet send during reconnection (will resend when resumed)');
      return;
    }

    logger.fine('sendDataPacket(label:${channel.label}, sequence:${packet.sequence})');
    await channel.send(message);

    _dcBufferStatus[reliability] = await channel.getBufferedAmount() <= channel.bufferedAmountLowThreshold!;

    // Align buffer with WebRTC buffer for reliable packets
    if (reliability == Reliability.reliable) {
      _reliableMessageBuffer.alignBufferedAmount(await channel.getBufferedAmount());
    }
  }

  Future<void> _publisherEnsureConnected() async {
    final state = await publisher?.pc.getConnectionState();
    if (state?.isConnected() != true) {
      logger.fine('Publisher is not connected...');

      // start negotiation
      if (state != rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        await negotiate();
      }
      if (!lkPlatformIsTest()) {
        logger.fine('Waiting for publisher to ice-connect...');
        await events.waitFor<EnginePublisherPeerStateUpdatedEvent>(
          filter: (event) => event.state.isConnected(),
          duration: connectOptions.timeouts.peerConnection,
        );
      }
    }
  }

  @internal
  Future<void> ensurePublisherConnected() {
    final existing = _publisherConnectionCompleter;
    if (existing != null && !existing.isCompleted) {
      return existing.future;
    }

    final completer = Completer<void>();
    _publisherConnectionCompleter = completer;

    unawaited(
      _publisherEnsureConnected().then((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }, onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }).whenComplete(() {
        if (identical(_publisherConnectionCompleter, completer)) {
          _publisherConnectionCompleter = null;
        }
      }),
    );

    return completer.future;
  }

  void _resetPublisherConnection() {
    final completer = _publisherConnectionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer
          .completeError(ConnectException('Publisher connection reset', reason: ConnectionErrorReason.InternalError));
    }
    _publisherConnectionCompleter = null;
  }

  lk_models.EncryptedPacketPayload? asEncryptablePacket(lk_models.DataPacket packet) {
    if ([
          lk_models.DataPacket_Value.sipDtmf,
          lk_models.DataPacket_Value.metrics,
          lk_models.DataPacket_Value.speaker,
          lk_models.DataPacket_Value.transcription,
          lk_models.DataPacket_Value.encryptedPacket
        ].contains(packet.whichValue()) ==
        false) {
      switch (packet.whichValue()) {
        case lk_models.DataPacket_Value.user:
          return lk_models.EncryptedPacketPayload(user: packet.user);
        case lk_models.DataPacket_Value.rpcRequest:
          return lk_models.EncryptedPacketPayload(rpcRequest: packet.rpcRequest);
        case lk_models.DataPacket_Value.rpcResponse:
          return lk_models.EncryptedPacketPayload(rpcResponse: packet.rpcResponse);
        case lk_models.DataPacket_Value.rpcAck:
          return lk_models.EncryptedPacketPayload(rpcAck: packet.rpcAck);
        case lk_models.DataPacket_Value.streamHeader:
          return lk_models.EncryptedPacketPayload(streamHeader: packet.streamHeader);
        case lk_models.DataPacket_Value.streamChunk:
          return lk_models.EncryptedPacketPayload(streamChunk: packet.streamChunk);
        case lk_models.DataPacket_Value.streamTrailer:
          return lk_models.EncryptedPacketPayload(streamTrailer: packet.streamTrailer);
        default:
          return null;
      }
    }
    return null;
  }

  lk_models.DataPacket asDataPacket(lk_models.EncryptedPacketPayload packet) {
    switch (packet.whichValue()) {
      case lk_models.EncryptedPacketPayload_Value.user:
        return lk_models.DataPacket(user: packet.user);
      case lk_models.EncryptedPacketPayload_Value.rpcRequest:
        return lk_models.DataPacket(rpcRequest: packet.rpcRequest);
      case lk_models.EncryptedPacketPayload_Value.rpcResponse:
        return lk_models.DataPacket(rpcResponse: packet.rpcResponse);
      case lk_models.EncryptedPacketPayload_Value.rpcAck:
        return lk_models.DataPacket(rpcAck: packet.rpcAck);
      case lk_models.EncryptedPacketPayload_Value.streamHeader:
        return lk_models.DataPacket(streamHeader: packet.streamHeader);
      case lk_models.EncryptedPacketPayload_Value.streamChunk:
        return lk_models.DataPacket(streamChunk: packet.streamChunk);
      case lk_models.EncryptedPacketPayload_Value.streamTrailer:
        return lk_models.DataPacket(streamTrailer: packet.streamTrailer);
      default:
        throw Exception('Unknown encrypted packet type: ${packet.whichValue()}');
    }
  }

  Future<RTCConfiguration> _buildRtcConfiguration(
      {required lk_models.ClientConfigSetting serverResponseForceRelay,
      required List<RTCIceServer> serverProvidedIceServers}) async {
    // RTCConfiguration? config;
    RTCConfiguration rtcConfiguration = connectOptions.rtcConfiguration;

    // The server provided iceServers are only used if
    // the client's iceServers are not set.
    if (rtcConfiguration.iceServers == null && serverProvidedIceServers.isNotEmpty) {
      rtcConfiguration = connectOptions.rtcConfiguration.copyWith(iceServers: serverProvidedIceServers);
    }

    // set forceRelay if server response is enabled
    if (serverResponseForceRelay == lk_models.ClientConfigSetting.ENABLED) {
      rtcConfiguration = rtcConfiguration.copyWith(
        iceTransportPolicy: RTCIceTransportPolicy.relay,
      );
    }

    if (kIsWeb && (roomOptions.e2eeOptions != null || roomOptions.encryption != null)) {
      rtcConfiguration = rtcConfiguration.copyWith(encodedInsertableStreams: true);
    }

    return rtcConfiguration;
  }

  Future<void> _createPeerConnections(RTCConfiguration rtcConfiguration) async {
    publisher =
        await Transport.create(_peerConnectionCreate, rtcConfig: rtcConfiguration, connectOptions: connectOptions);
    subscriber =
        await Transport.create(_peerConnectionCreate, rtcConfig: rtcConfiguration, connectOptions: connectOptions);

    publisher?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('publisher onIceCandidate');
      signalClient.sendIceCandidate(candidate, lk_rtc.SignalTarget.PUBLISHER);
    };

    publisher?.pc.onIceConnectionState = (rtc.RTCIceConnectionState state) async {
      logger.fine('publisher iceConnectionState: $state');
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        await _handleGettingConnectedServerAddress(publisher!.pc);
      }
    };

    subscriber?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('subscriber onIceCandidate');
      signalClient.sendIceCandidate(candidate, lk_rtc.SignalTarget.SUBSCRIBER);
    };

    subscriber?.pc.onIceConnectionState = (rtc.RTCIceConnectionState state) async {
      logger.fine('subscriber iceConnectionState: $state');
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        await _handleGettingConnectedServerAddress(subscriber!.pc);
      }
    };

    publisher?.onOffer = (offer) {
      logger.fine('publisher onOffer');
      signalClient.sendOffer(offer);
    };

    // in subscriber primary mode, server side opens sub data channels.
    if (_subscriberPrimary) {
      subscriber?.pc.onDataChannel = _onDataChannel;
    }

    subscriber?.pc.onConnectionState = (state) async {
      events.emit(EngineSubscriberPeerStateUpdatedEvent(
        state: state,
        isPrimary: _subscriberPrimary,
      ));
      logger.fine('subscriber connectionState: $state');
      if (state.isDisconnected() || state.isFailed()) {
        await handleReconnect(
          state.isFailed() ? ClientDisconnectReason.peerConnectionFailed : ClientDisconnectReason.peerConnectionClosed,
          reconnectReason: lk_models.ReconnectReason.RR_SUBSCRIBER_FAILED,
        );
      }
    };

    publisher?.pc.onConnectionState = (state) async {
      if ([
        rtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed,
        rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed,
        rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected
      ].contains(state)) {
        _resetPublisherConnection();
      }
      events.emit(EnginePublisherPeerStateUpdatedEvent(
        state: state,
        isPrimary: !_subscriberPrimary,
      ));
      logger.fine('publisher connectionState: $state');
      if (state.isDisconnected() || state.isFailed()) {
        await handleReconnect(
          state.isFailed() ? ClientDisconnectReason.peerConnectionFailed : ClientDisconnectReason.peerConnectionClosed,
          reconnectReason: lk_models.ReconnectReason.RR_PUBLISHER_FAILED,
        );
      }
    };

    subscriber?.pc.onTrack = (rtc.RTCTrackEvent event) {
      logger.fine('[WebRTC] pc.onTrack');

      final stream = event.streams.firstOrNull;
      if (stream == null) {
        // we need the stream to get the track's id
        logger.severe('received track without mediastream');
        return;
      }

      // doesn't get called reliably
      event.track.onEnded = () {
        logger.fine('[WebRTC] track.onEnded');
      };

      // doesn't get called reliably
      stream.onRemoveTrack = (_) {
        logger.fine('[WebRTC] stream.onRemoveTrack');
      };

      if (signalClient.connectionState == ConnectionState.reconnecting ||
          signalClient.connectionState == ConnectionState.connecting) {
        final track = event.track;
        final receiver = event.receiver;
        events.on<EngineConnectedEvent>((event) async {
          Timer(const Duration(milliseconds: 10), () {
            events.emit(EngineTrackAddedEvent(
              track: track,
              stream: stream,
              receiver: receiver,
            ));
          });
        });
        return;
      }

      if (connectionState == ConnectionState.disconnected) {
        logger.warning('skipping incoming track after Room disconnected');
        return;
      }

      events.emit(EngineTrackAddedEvent(
        track: event.track,
        stream: stream,
        receiver: event.receiver,
      ));
    };

    // doesn't get called reliably, doesn't work on mac
    subscriber?.pc.onRemoveTrack = (rtc.MediaStream stream, rtc.MediaStreamTrack track) {
      logger.fine('[WebRTC] ${track.id} pc.onRemoveTrack');
    };

    // also handle messages over the pub channel, for backwards compatibility
    try {
      final lossyInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = false
        ..maxRetransmits = 0;
      _lossyDCPub = await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);
      _lossyDCPub?.onMessage = _onDCMessage;
      _lossyDCPub?.stateChangeStream.listen((state) => events.emit(PublisherDataChannelStateUpdatedEvent(
            isPrimary: !_subscriberPrimary,
            state: state,
            type: Reliability.lossy,
          )));
      // _onDCStateUpdated(Reliability.lossy, state)
      _lossyDCPub?.bufferedAmountLowThreshold = 2 * 1024 * 1024;
      _lossyDCPub?.onBufferedAmountLow = (_) {
        _dcBufferStatus[Reliability.lossy] = (_lossyDCPub!.bufferedAmount! <= _lossyDCPub!.bufferedAmountLowThreshold!);
      };
    } catch (err) {
      logger.severe('[$objectId] createDataChannel() did throw $err');
    }

    try {
      final reliableInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true;
      _reliableDCPub = await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);
      _reliableDCPub?.onMessage = _onDCMessage;
      _reliableDCPub?.stateChangeStream.listen((state) => events.emit(PublisherDataChannelStateUpdatedEvent(
            isPrimary: !_subscriberPrimary,
            state: state,
            type: Reliability.reliable,
          )));
      _reliableDCPub?.bufferedAmountLowThreshold = 2 * 1024 * 1024;
      _reliableDCPub?.onBufferedAmountLow = (_) {
        _dcBufferStatus[Reliability.reliable] =
            (_reliableDCPub!.bufferedAmount! <= _reliableDCPub!.bufferedAmountLowThreshold!);
      };
    } catch (err) {
      logger.severe('[$objectId] createDataChannel() did throw $err');
    }
  }

  void _onDataChannel(rtc.RTCDataChannel dc) {
    switch (dc.label) {
      case _reliableDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _reliableDCSub = dc;
        _reliableDCSub?.onMessage = _onDCMessage;
        _reliableDCSub?.stateChangeStream.listen((state) =>
            _reliableDCPub?.stateChangeStream.listen((state) => events.emit(SubscriberDataChannelStateUpdatedEvent(
                  isPrimary: _subscriberPrimary,
                  state: state,
                  type: Reliability.reliable,
                ))));
        break;
      case _lossyDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _lossyDCSub = dc;
        _lossyDCSub?.onMessage = _onDCMessage;
        _lossyDCSub?.stateChangeStream.listen((event) =>
            _reliableDCPub?.stateChangeStream.listen((state) => events.emit(SubscriberDataChannelStateUpdatedEvent(
                  isPrimary: _subscriberPrimary,
                  state: state,
                  type: Reliability.lossy,
                ))));
        break;
      default:
        logger.warning('Unknown DC label: ${dc.label}');
        break;
    }
  }

  Future<void> _handleGettingConnectedServerAddress(rtc.RTCPeerConnection pc) async {
    try {
      final remoteAddress = await getConnectedAddress(publisher!.pc);
      logger.fine('Connected address: $remoteAddress');
      if (_connectedServerAddress == null || _connectedServerAddress != remoteAddress) {
        _connectedServerAddress = remoteAddress;
      }
    } catch (e) {
      logger.warning('could not get connected server address ${e.toString()}');
    }
  }

  void _onDCMessage(rtc.RTCDataChannelMessage message) async {
    // always expect binary
    if (!message.isBinary) {
      logger.warning('Data message is not binary');
      return;
    }
    final dp = lk_models.DataPacket.fromBuffer(message.binary);
    if (dp.whichValue() == lk_models.DataPacket_Value.encryptedPacket) {
      if (_e2eeManager == null) {
        logger.warning('Received encrypted packet but E2EE not set up');
        return;
      }
      final decryptedData = await _e2eeManager?.handleEncryptedData(
        data: Uint8List.fromList(dp.encryptedPacket.encryptedValue),
        iv: Uint8List.fromList(dp.encryptedPacket.iv),
        participantIdentity: dp.participantIdentity,
        keyIndex: dp.encryptedPacket.keyIndex,
      );
      if (decryptedData == null) {
        logger.warning('Failed to decrypt data packet');
        return;
      }
      final decryptedPacketPayload = lk_models.EncryptedPacketPayload.fromBuffer(decryptedData);
      final newDp = asDataPacket(decryptedPacketPayload);

      // Handle sequence numbers for reliable packets (encrypted outer packet)
      if (dp.kind == lk_models.DataPacket_Kind.RELIABLE && dp.hasSequence()) {
        final participantKey = _reliableParticipantKey(dp);
        if (participantKey != null) {
          final sequence = dp.sequence;
          final lastReceived = _reliableReceivedState.get(participantKey) ?? 0;
          if (sequence <= lastReceived) {
            logger.fine('Ignoring duplicate or out-of-order packet: '
                'sequence=$sequence, lastReceived=$lastReceived, participantSid=$participantKey');
            return;
          }
          _reliableReceivedState.set(participantKey, sequence);
        }
      }

      // Preserve metadata from the outer packet on the decrypted packet
      newDp
        ..kind = dp.kind
        ..sequence = dp.sequence
        ..participantIdentity = dp.participantIdentity
        ..participantSid = dp.participantSid
        ..destinationIdentities.addAll(dp.destinationIdentities);

      _emitDataPacket(newDp, encryptionType: dp.encryptedPacket.encryptionType.toLkType());
    } else {
      // Handle sequence numbers for reliable packets (plaintext)
      if (dp.kind == lk_models.DataPacket_Kind.RELIABLE && dp.hasSequence()) {
        final participantKey = _reliableParticipantKey(dp);
        if (participantKey != null) {
          final sequence = dp.sequence;
          final lastReceived = _reliableReceivedState.get(participantKey) ?? 0;
          if (sequence <= lastReceived) {
            logger.fine('Ignoring duplicate or out-of-order packet: '
                'sequence=$sequence, lastReceived=$lastReceived, participantSid=$participantKey');
            return;
          }
          _reliableReceivedState.set(participantKey, sequence);
        } else {
          logger.fine('Reliable packet without participant SID, skipping dedupe');
        }
      }

      _emitDataPacket(dp);
    }
  }

  void _emitDataPacket(lk_models.DataPacket dp, {EncryptionType encryptionType = EncryptionType.kNone}) {
    if (dp.whichValue() == lk_models.DataPacket_Value.speaker) {
      // Speaker packet
      events.emit(EngineActiveSpeakersUpdateEvent(
        speakers: dp.speaker.speakers,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.user) {
      // User packet
      events.emit(EngineDataPacketReceivedEvent(
        packet: dp.user,
        kind: dp.kind,
        identity: dp.participantIdentity,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.transcription) {
      // Transcription packet
      events.emit(EngineTranscriptionReceivedEvent(
        transcription: dp.transcription,
        identity: dp.participantIdentity,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.sipDtmf) {
      // SIP DTMF packet
      events.emit(EngineSipDtmfReceivedEvent(
        dtmf: dp.sipDtmf,
        identity: dp.participantIdentity,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.rpcRequest) {
      // RPC Request
      events.emit(EngineRPCRequestReceivedEvent(
        request: dp.rpcRequest,
        identity: dp.participantIdentity,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.rpcResponse) {
      // RPC Response
      events.emit(EngineRPCResponseReceivedEvent(
        response: dp.rpcResponse,
        identity: dp.participantIdentity,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.rpcAck) {
      // RPC Ack
      events.emit(EngineRPCAckReceivedEvent(
        ack: dp.rpcAck,
        identity: dp.participantIdentity,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.streamHeader) {
      // Data Stream Header
      events.emit(
        EngineDataStreamHeaderEvent(
          header: dp.streamHeader,
          identity: dp.participantIdentity,
          encryptionType: encryptionType,
        ),
      );
    } else if (dp.whichValue() == lk_models.DataPacket_Value.streamChunk) {
      // Data Stream Chunk
      events.emit(
        EngineDataStreamChunkEvent(
          chunk: dp.streamChunk,
          identity: dp.participantIdentity,
          encryptionType: encryptionType,
        ),
      );
    } else if (dp.whichValue() == lk_models.DataPacket_Value.streamTrailer) {
      // Data Stream trailer
      events.emit(
        EngineDataStreamTrailerEvent(
          trailer: dp.streamTrailer,
          identity: dp.participantIdentity,
          encryptionType: encryptionType,
        ),
      );
    } else {
      logger.warning('Unknown data packet type: ${dp.whichValue()}');
    }
  }

  @internal
  Future<void> handleReconnect(
    ClientDisconnectReason reason, {
    lk_models.ReconnectReason? reconnectReason,
  }) async {
    if (_isClosed) {
      logger.fine('handleReconnect: engine is closed, skip');
      return;
    }

    logger.info('onDisconnected state:${connectionState} reason:${reason.name}');

    _isReconnecting = true;

    if (reconnectAttempts == 0) {
      reconnectStart = DateTime.timestamp();
    }

    if (reconnectAttempts! >= _reconnectCount) {
      logger.fine('reconnectAttempts exceeded, disconnecting...');
      _isClosed = true;
      await cleanUp();

      events.emit(EngineDisconnectedEvent(
        reason: DisconnectReason.reconnectAttemptsExceeded,
      ));
      return;
    }

    var delay = defaultRetryDelaysInMs[reconnectAttempts!];
    // Add random jitter to prevent thundering herd on reconnect
    if (reconnectAttempts! > 1) {
      delay += math.Random().nextInt(1000);
    }

    events.emit(EngineAttemptReconnectEvent(
      attempt: reconnectAttempts! + 1,
      maxAttempts: _reconnectCount,
      nextRetryDelaysInMs: delay,
    ));

    clearReconnectTimeout();
    if (token != null && _regionUrlProvider != null) {
      // token may have been refreshed, we do not want to recreate the regionUrlProvider
      // since the current engine may have inherited a regional url
      _regionUrlProvider!.updateToken(token!);
    }
    logger.fine('WebSocket reconnecting in $delay ms, retry times $reconnectAttempts');
    reconnectTimeout = Timer(Duration(milliseconds: delay), () async {
      await attemptReconnect(
        reason,
        reconnectReason: reconnectReason,
      );
    });
  }

  @internal
  Future<void> attemptReconnect(
    ClientDisconnectReason reason, {
    lk_models.ReconnectReason? reconnectReason,
  }) async {
    if (_isClosed) {
      return;
    }

    // guard for attempting reconnection multiple times while one attempt is still not finished
    if (attemptingReconnect) {
      return;
    }

    if (_clientConfiguration?.resumeConnection == lk_models.ClientConfigSetting.DISABLED ||
        [
          ClientDisconnectReason.leaveReconnect,
          ClientDisconnectReason.negotiationFailed,
          ClientDisconnectReason.peerConnectionFailed,
        ].contains(reason)) {
      fullReconnectOnNext = true;
    }

    try {
      attemptingReconnect = true;

      if (await signalClient.networkIsAvailable() == false) {
        logger.fine('no internet connection, waiting...');
        await signalClient.events.waitFor<SignalConnectivityChangedEvent>(
          duration: connectOptions.timeouts.connection * 10,
          filter: (event) => !event.state.contains(ConnectivityResult.none),
          onTimeout: () => throw ConnectException(
              'attemptReconnect: Timed out waiting for SignalConnectivityChangedEvent',
              reason: ConnectionErrorReason.Timeout),
        );
      }

      if (fullReconnectOnNext) {
        await restartConnection();
      } else {
        await resumeConnection(
          reason,
          reconnectReason: reconnectReason,
        );
      }
      clearPendingReconnect();
      attemptingReconnect = false;
      _isReconnecting = false;
    } catch (e) {
      reconnectAttempts = reconnectAttempts! + 1;
      bool recoverable = true;
      if (e is WebSocketException || e is MediaConnectException) {
        // cannot resume connection, need to do full reconnect
        fullReconnectOnNext = true;
      }

      if (e is UnexpectedConnectionState) {
        recoverable = false;
      }

      if (recoverable) {
        unawaited(handleReconnect(ClientDisconnectReason.reconnectRetry));
      } else {
        logger.fine('attemptReconnect: disconnecting...');
        events.emit(EngineDisconnectedEvent(
          reason: DisconnectReason.disconnected,
        ));
        await cleanUp();
      }
    } finally {
      attemptingReconnect = false;
    }
  }

  Future<void> resumeConnection(
    ClientDisconnectReason reason, {
    lk_models.ReconnectReason? reconnectReason,
  }) async {
    if (_isClosed) {
      return;
    }

    events.emit(const EngineResumingEvent());

    // wait for socket to connect rtc server
    await signalClient.connect(
      url!,
      token!,
      connectOptions: connectOptions,
      roomOptions: roomOptions,
      reconnect: true,
      reconnectReason: reconnectReason,
    );

    await events.waitFor<SignalReconnectedEvent>(
      duration: connectOptions.timeouts.connection,
      onTimeout: () => throw ConnectException('resumeConnection: Timed out waiting for SignalReconnectedEvent',
          reason: ConnectionErrorReason.Timeout),
    );

    logger.fine('resumeConnection: reason: ${reason.name}');

    if (_hasPublished) {
      logger.fine('resumeConnection: negotiating publisher...');
      await publisher!.createAndSendOffer(const RTCOfferOptions(
        iceRestart: true,
      ));
    }

    final isConnected = (await primary?.pc.getConnectionState())?.isConnected() ?? false;

    logger.fine('resumeConnection: primary is connected: $isConnected');

    if (!isConnected) {
      subscriber!.restartingIce = true;
      logger.fine('resumeConnection: Waiting for primary to connect...');
      await events.waitFor<EnginePeerStateUpdatedEvent>(
        filter: (event) => event.isPrimary && event.state.isConnected(),
        duration: connectOptions.timeouts.peerConnection,
        onTimeout: () =>
            throw MediaConnectException('resumeConnection: Timed out waiting for EnginePeerStateUpdatedEvent'),
      );
      logger.fine('resumeConnection: primary connected');
    }

    _isReconnecting = false;
    events.emit(const EngineResumedEvent());
  }

  @internal
  Future<void> restartConnection({String? regionUrl}) async {
    if (_isClosed) {
      return;
    }

    try {
      events.emit(const EngineFullRestartingEvent());

      if (signalClient.connectionState == ConnectionState.connected) {
        await signalClient.cleanUp();
      }

      await publisher?.dispose();
      publisher = null;

      _resetPublisherConnection();

      await subscriber?.dispose();
      subscriber = null;

      _reliableDCSub = null;
      _reliableDCPub = null;
      _lossyDCSub = null;
      _lossyDCPub = null;

      await _signalListener.cancelAll();

      _signalListener = signalClient.createListener(synchronized: true);
      _setUpSignalListeners();

      await connect(
        regionUrl ?? url!,
        token!,
        roomOptions: roomOptions,
        connectOptions: connectOptions,
        fastConnectOptions: fastConnectOptions,
      );

      if (_hasPublished) {
        await ensurePublisherConnected();
      }

      fullReconnectOnNext = false;
      _regionUrlProvider?.resetAttempts();
      events.emit(const EngineRestartedEvent());
    } catch (error) {
      final nextRegionUrl = await _regionUrlProvider?.getNextBestRegionUrl();
      if (nextRegionUrl != null) {
        await restartConnection(regionUrl: nextRegionUrl);
        return;
      } else {
        // no more regions to try (or we're not on cloud)
        _regionUrlProvider?.resetAttempts();
        rethrow;
      }
    }
  }

  @internal
  void sendSyncState({
    required lk_rtc.UpdateSubscription subscription,
    required Iterable<lk_rtc.TrackPublishedResponse>? publishTracks,
    required List<String> trackSidsDisabled,
  }) async {
    final previousAnswer = (await subscriber?.pc.getLocalDescription())?.toPBType();
    final previousOffer = (await subscriber?.pc.getRemoteDescription())?.toPBType();

    // Build data channel receive states for reliability
    final dataChannelReceiveStates = <lk_rtc.DataChannelReceiveState>[];
    for (final participantId in List.of(_reliableReceivedState.keys)) {
      final lastSequence = _reliableReceivedState.get(participantId);
      if (lastSequence != null) {
        final receiveState = lk_rtc.DataChannelReceiveState();
        receiveState.publisherSid = participantId;
        receiveState.lastSeq = lastSequence;
        dataChannelReceiveStates.add(receiveState);
      }
    }
    signalClient.sendSyncState(
      answer: previousAnswer,
      offer: previousOffer,
      subscription: subscription,
      publishTracks: publishTracks,
      dataChannelInfo: dataChannelInfo(),
      trackSidsDisabled: trackSidsDisabled,
      dataChannelReceiveStates: dataChannelReceiveStates,
    );
  }

  void _setUpEngineListeners() => events.on<SignalReconnectedEvent>((event) async {
        // send queued requests if engine re-connected
        signalClient.sendQueuedRequests();
      });

  void _setUpSignalListeners() => _signalListener
    ..on<SignalJoinResponseEvent>((event) async {
      // create peer connections
      _subscriberPrimary = event.response.subscriberPrimary;
      _serverInfo = event.response.serverInfo;
      final iceServersFromServer = event.response.iceServers.map((e) => e.toSDKType()).toList();

      if (iceServersFromServer.isNotEmpty) {
        _serverProvidedIceServers = iceServersFromServer;
      }

      _clientConfiguration = event.response.clientConfiguration;

      logger.fine('onConnected subscriberPrimary: ${_subscriberPrimary}, '
          'serverVersion: ${event.response.serverVersion}, '
          'iceServers: ${event.response.iceServers}, '
          'forceRelay: $event.response.clientConfiguration.forceRelay');

      final rtcConfiguration = await _buildRtcConfiguration(
          serverResponseForceRelay: event.response.clientConfiguration.forceRelay,
          serverProvidedIceServers: _serverProvidedIceServers);

      if (publisher == null && subscriber == null) {
        await _createPeerConnections(rtcConfiguration);
      }

      if (!_subscriberPrimary || event.response.fastPublish) {
        _enabledPublishCodecs = event.response.enabledPublishCodecs;

        /// for subscriberPrimary, we negotiate when necessary (lazy)
        /// and if `response.fastPublish == true`, we need to negotiate
        /// immediately
        await negotiate();
      }

      events.emit(EngineJoinResponseEvent(response: event.response));
    })
    ..on<SignalReconnectResponseEvent>((event) async {
      final iceServersFromServer = event.response.iceServers.map((e) => e.toSDKType()).toList();

      if (iceServersFromServer.isNotEmpty) {
        _serverProvidedIceServers = iceServersFromServer;
      }

      _clientConfiguration = event.response.clientConfiguration;

      logger.fine('Handle ReconnectResponse: '
          'iceServers: ${event.response.iceServers}, '
          'forceRelay: $event.response.clientConfiguration.forceRelay, '
          'lastMessageSeq: ${event.response.lastMessageSeq}');

      final rtcConfiguration = await _buildRtcConfiguration(
          serverResponseForceRelay: event.response.clientConfiguration.forceRelay,
          serverProvidedIceServers: _serverProvidedIceServers);

      await publisher?.pc.setConfiguration(rtcConfiguration.toMap());
      await subscriber?.pc.setConfiguration(rtcConfiguration.toMap());

      if (!_subscriberPrimary) {
        await negotiate();
      }

      // Handle reliable message resending
      if (event.response.hasLastMessageSeq()) {
        await _resendReliableMessagesForResume(event.response.lastMessageSeq);
      }

      events.emit(const SignalReconnectedEvent());
    })
    ..on<SignalConnectedEvent>((event) async {
      logger.fine('Signal connected');
      reconnectAttempts = 0;
      events.emit(const EngineConnectedEvent());
    })
    ..on<SignalConnectingEvent>((event) async {
      logger.fine('Signal connecting');
      events.emit(const EngineConnectingEvent());
    })
    ..on<SignalReconnectingEvent>((event) async {
      logger.fine('Signal reconnecting');
      events.emit(const EngineReconnectingEvent());
    })
    ..on<SignalDisconnectedEvent>((event) async {
      logger.fine('Signal disconnected ${event.reason}');
      if (event.reason == DisconnectReason.disconnected && !_isClosed) {
        await handleReconnect(ClientDisconnectReason.signal,
            reconnectReason: lk_models.ReconnectReason.RR_SIGNAL_DISCONNECTED);
      } else if (event.reason == DisconnectReason.signalingConnectionFailure) {
        events.emit(EngineDisconnectedEvent(
          reason: event.reason,
        ));
      }
    })
    ..on<SignalOfferEvent>((event) async {
      if (subscriber == null) {
        logger.warning('[$objectId] subscriber is null');
        return;
      }
      final signalingState = await subscriber!.pc.getSignalingState();
      logger.fine('[$objectId] Received server offer(type: ${event.sd.type}, '
          '$signalingState)');
      logger.finer('sdp: ${event.sd.sdp}');

      await subscriber!.setRemoteDescription(event.sd);

      try {
        final answer = await subscriber!.pc.createAnswer();
        logger.fine('Created answer');
        logger.finer('sdp: ${answer.sdp}');
        await subscriber!.pc.setLocalDescription(answer);
        signalClient.sendAnswer(answer);
      } catch (_) {
        logger.severe('[$objectId] Failed to createAnswer()');
      }
    })
    ..on<SignalAnswerEvent>((event) async {
      if (publisher == null) {
        return;
      }
      logger.fine('received answer (type: ${event.sd.type})');
      logger.finer('sdp: ${event.sd.sdp}');
      await publisher!.setRemoteDescription(event.sd);
    })
    ..on<SignalTrickleEvent>((event) async {
      if (publisher == null || subscriber == null) {
        logger.warning('Received ${SignalTrickleEvent} but publisher or subscriber was null.');
        return;
      }
      logger.fine('got ICE candidate from peer (target: ${event.target})');
      if (event.target == lk_rtc.SignalTarget.SUBSCRIBER) {
        await subscriber!.addIceCandidate(event.candidate);
      } else if (event.target == lk_rtc.SignalTarget.PUBLISHER) {
        await publisher!.addIceCandidate(event.candidate);
      }
    })
    ..on<SignalLocalTrackSubscribedEvent>((event) async {
      events.emit(EngineLocalTrackSubscribedEvent(
        trackSid: event.trackSid,
      ));
    })
    ..on<SignalTokenUpdatedEvent>((event) {
      logger.fine('Server refreshed the token');
      token = event.token;
    })
    ..on<SignalLeaveEvent>((event) async {
      logger.fine('[Signal] Leave received, action: ${event.action}, reason: ${event.reason}');
      if (event.regions != null && _regionUrlProvider != null) {
        logger.fine('updating regions');
        _regionUrlProvider?.setServerReportedRegions(event.regions!);
      }
      // Protocol v13: LeaveRequest.action replaces the deprecated canReconnect boolean.
      // canReconnect is still checked for backward compatibility with v12 servers
      // (where action defaults to DISCONNECT=0 since it's unset).
      if (event.action == lk_rtc.LeaveRequest_Action.RESUME) {
        fullReconnectOnNext = false;
        // reconnect immediately instead of waiting for next attempt
        await handleReconnect(ClientDisconnectReason.leaveReconnect);
      } else if (event.action == lk_rtc.LeaveRequest_Action.RECONNECT || event.canReconnect) {
        fullReconnectOnNext = true;
        // reconnect immediately instead of waiting for next attempt
        await handleReconnect(ClientDisconnectReason.leaveReconnect);
      } else {
        // DISCONNECT or v12 server with canReconnect=false
        await signalClient.cleanUp();
        fullReconnectOnNext = false;
        await disconnect(reason: event.reason.toSDKType());
      }
    })
    ..on<SignalRequestResponseEvent>((event) async {
      events.emit(EngineRequestResponseEvent(response: event.response));
    })
    ..on<SignalRoomMovedEvent>((event) async {
      logger.fine('[Signal] RoomMoved received, room: ${event.response.room.name}');
      if (event.response.hasParticipant()) {
        signalClient.participantSid = event.response.participant.sid;
      }
      events.emit(EngineRoomMovedEvent(response: event.response));
    });

  Future<void> disconnect({
    DisconnectReason reason = DisconnectReason.clientInitiated,
  }) async {
    _isClosed = true;
    events.emit(EngineClosingEvent());
    if (connectionState == ConnectionState.connected) {
      await signalClient.sendLeave();
    } else {
      if (isPendingReconnect) {
        logger.fine('disconnect: Cancel the reconnection processing!');
        await signalClient.cleanUp();
        await _signalListener.cancelAll();
        clearPendingReconnect();
      }
      await cleanUp();
      events.emit(EngineDisconnectedEvent(reason: reason));
    }
  }

  void setRegionUrlProvider(RegionUrlProvider provider) {
    _regionUrlProvider = provider;
  }
}

extension EnginePrivateMethods on Engine {
  // publisher data channel for the reliability
  rtc.RTCDataChannel? _publisherDataChannel(Reliability reliability) =>
      reliability == Reliability.reliable ? _reliableDCPub : _lossyDCPub;

  // state of the publisher data channel
  rtc.RTCDataChannelState _publisherDataChannelState(Reliability reliability) =>
      _publisherDataChannel(reliability)?.state ?? rtc.RTCDataChannelState.RTCDataChannelClosed;
}

extension EngineInternalMethods on Engine {
  @internal
  Future<rtc.RTCRtpTransceiver> createTransceiverRTCRtpSender(
    LocalTrack track,
    PublishOptions opts,
    List<rtc.RTCRtpEncoding>? encodings,
  ) async {
    if (publisher == null) {
      throw UnexpectedConnectionState('publisher is closed');
    }

    if (track.mediaStreamTrack.kind == 'video' && opts is VideoPublishOptions) {
      track.codec = opts.videoCodec;
    }
    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
    );
    if (encodings != null) {
      transceiverInit.sendEncodings = encodings;
    }
    final transceiver = await publisher!.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: track is LocalVideoTrack
          ? rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo
          : rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: transceiverInit,
    );
    return transceiver;
  }

  @internal
  List<lk_rtc.DataChannelInfo> dataChannelInfo() =>
      [_reliableDCPub, _lossyDCPub].nonNulls.where((e) => e.id != -1).map((e) => e.toLKInfoType()).toList();

  @internal
  Future<rtc.RTCRtpSender> createSimulcastTransceiverSender(
    LocalVideoTrack track,
    SimulcastTrackInfo simulcastTrack,
    List<rtc.RTCRtpEncoding>? encodings,
    LocalTrackPublication publication,
    String videoCodec,
  ) async {
    if (publisher == null) {
      throw Exception('publisher is closed');
    }
    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
    );
    if (encodings != null) {
      transceiverInit.sendEncodings = encodings;
    }
    final transceiver = await publisher!.pc.addTransceiver(
      track: simulcastTrack.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: transceiverInit,
    );
    await setPreferredCodec(transceiver, track.kind.toString().toLowerCase(), videoCodec);
    return transceiver.sender;
  }

  Future<void> setPreferredCodec(rtc.RTCRtpTransceiver transceiver, String kind, String videoCodec) async {
    // when setting codec preferences, the capabilites need to be read from
    // the RTCRtpReceiver
    final caps = await rtc.getRtpReceiverCapabilities(kind);
    if (caps.codecs == null) return;

    logger.fine('get capabilities ${caps.codecs}');

    final List<rtc.RTCRtpCodecCapability> matched = [];
    final List<rtc.RTCRtpCodecCapability> partialMatched = [];
    final List<rtc.RTCRtpCodecCapability> unmatched = [];
    for (var c in caps.codecs!) {
      final codec = c.mimeType.toLowerCase();
      if (codec == 'audio/opus') {
        matched.add(c);
        continue;
      }

      final matchesVideoCodec = codec == 'video/$videoCodec';
      if (!matchesVideoCodec) {
        if (lkPlatformIs(PlatformType.android) && codec == 'video/vp9') {
          if (c.sdpFmtpLine != null &&
              (c.sdpFmtpLine!.contains('profile-id=0') || c.sdpFmtpLine!.contains('profile-id=1'))) {
            unmatched.add(c);
          }
        } else {
          unmatched.add(c);
        }
        continue;
      }
      // for h264 codecs that have sdpFmtpLine available, use only if the
      // profile-level-id is 42e01f for cross-browser compatibility
      if (videoCodec.toLowerCase() == 'h264') {
        if (c.sdpFmtpLine != null && c.sdpFmtpLine!.contains('profile-level-id=42e01f')) {
          matched.add(c);
        } else {
          partialMatched.add(c);
        }
        continue;
      }
      if (lkPlatformIs(PlatformType.android) && codec == 'video/vp9') {
        if (c.sdpFmtpLine != null &&
            (c.sdpFmtpLine!.contains('profile-id=0') || c.sdpFmtpLine!.contains('profile-id=1'))) {
          matched.add(c);
        }
      } else {
        matched.add(c);
      }
    }
    matched.addAll([...partialMatched, ...unmatched]);
    try {
      await transceiver.setCodecPreferences(matched);
    } catch (e) {
      logger.warning('setCodecPreferences failed: $e');
    }
  }
}

Future<String?> getConnectedAddress(rtc.RTCPeerConnection pc) async {
  var selectedCandidatePairId = '';
  final candidatePairs = <String, rtc.StatsReport>{};
  // id -> candidate ip
  final candidates = <String, String>{};
  final List<rtc.StatsReport> stats = await pc.getStats();
  for (var v in stats) {
    switch (v.type) {
      case 'transport':
        selectedCandidatePairId = v.values['selectedCandidatePairId'] as String;
        break;
      case 'candidate-pair':
        if (selectedCandidatePairId == '') {
          if (v.values['selected'] != null && v.values['selected'] == true) {
            selectedCandidatePairId = v.id;
          }
        }
        candidatePairs[v.id] = v;
        break;
      case 'remote-candidate':
        var address = '';
        var port = 0;
        if (v.values['address'] != null) {
          address = v.values['address'] as String;
        }
        if (v.values['port'] != null) {
          port = v.values['port'] as int;
        }
        candidates[v.id] = '$address:$port';
        break;
      default:
    }
  }

  if (selectedCandidatePairId == '') {
    return null;
  }

  final report = candidatePairs[selectedCandidatePairId];
  if (report == null) {
    return null;
  }
  final selectedID = report.values['remoteCandidateId'] as String;
  return candidates[selectedID];
}
