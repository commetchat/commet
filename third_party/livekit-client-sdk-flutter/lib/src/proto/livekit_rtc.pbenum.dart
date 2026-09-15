// This is a generated file - do not edit.
//
// Generated from livekit_rtc.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SignalTarget extends $pb.ProtobufEnum {
  static const SignalTarget PUBLISHER = SignalTarget._(0, _omitEnumNames ? '' : 'PUBLISHER');
  static const SignalTarget SUBSCRIBER = SignalTarget._(1, _omitEnumNames ? '' : 'SUBSCRIBER');

  static const $core.List<SignalTarget> values = <SignalTarget>[
    PUBLISHER,
    SUBSCRIBER,
  ];

  static final $core.List<SignalTarget?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static SignalTarget? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SignalTarget._(super.value, super.name);
}

class StreamState extends $pb.ProtobufEnum {
  static const StreamState ACTIVE = StreamState._(0, _omitEnumNames ? '' : 'ACTIVE');
  static const StreamState PAUSED = StreamState._(1, _omitEnumNames ? '' : 'PAUSED');

  static const $core.List<StreamState> values = <StreamState>[
    ACTIVE,
    PAUSED,
  ];

  static final $core.List<StreamState?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static StreamState? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StreamState._(super.value, super.name);
}

class CandidateProtocol extends $pb.ProtobufEnum {
  static const CandidateProtocol UDP = CandidateProtocol._(0, _omitEnumNames ? '' : 'UDP');
  static const CandidateProtocol TCP = CandidateProtocol._(1, _omitEnumNames ? '' : 'TCP');
  static const CandidateProtocol TLS = CandidateProtocol._(2, _omitEnumNames ? '' : 'TLS');

  static const $core.List<CandidateProtocol> values = <CandidateProtocol>[
    UDP,
    TCP,
    TLS,
  ];

  static final $core.List<CandidateProtocol?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CandidateProtocol? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CandidateProtocol._(super.value, super.name);
}

/// indicates action clients should take on receiving this message
class LeaveRequest_Action extends $pb.ProtobufEnum {
  static const LeaveRequest_Action DISCONNECT = LeaveRequest_Action._(0, _omitEnumNames ? '' : 'DISCONNECT');
  static const LeaveRequest_Action RESUME = LeaveRequest_Action._(1, _omitEnumNames ? '' : 'RESUME');
  static const LeaveRequest_Action RECONNECT = LeaveRequest_Action._(2, _omitEnumNames ? '' : 'RECONNECT');

  static const $core.List<LeaveRequest_Action> values = <LeaveRequest_Action>[
    DISCONNECT,
    RESUME,
    RECONNECT,
  ];

  static final $core.List<LeaveRequest_Action?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static LeaveRequest_Action? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LeaveRequest_Action._(super.value, super.name);
}

class RequestResponse_Reason extends $pb.ProtobufEnum {
  static const RequestResponse_Reason OK = RequestResponse_Reason._(0, _omitEnumNames ? '' : 'OK');
  static const RequestResponse_Reason NOT_FOUND = RequestResponse_Reason._(1, _omitEnumNames ? '' : 'NOT_FOUND');
  static const RequestResponse_Reason NOT_ALLOWED = RequestResponse_Reason._(2, _omitEnumNames ? '' : 'NOT_ALLOWED');
  static const RequestResponse_Reason LIMIT_EXCEEDED =
      RequestResponse_Reason._(3, _omitEnumNames ? '' : 'LIMIT_EXCEEDED');
  static const RequestResponse_Reason QUEUED = RequestResponse_Reason._(4, _omitEnumNames ? '' : 'QUEUED');
  static const RequestResponse_Reason UNSUPPORTED_TYPE =
      RequestResponse_Reason._(5, _omitEnumNames ? '' : 'UNSUPPORTED_TYPE');
  static const RequestResponse_Reason UNCLASSIFIED_ERROR =
      RequestResponse_Reason._(6, _omitEnumNames ? '' : 'UNCLASSIFIED_ERROR');
  static const RequestResponse_Reason INVALID_HANDLE =
      RequestResponse_Reason._(7, _omitEnumNames ? '' : 'INVALID_HANDLE');
  static const RequestResponse_Reason INVALID_NAME = RequestResponse_Reason._(8, _omitEnumNames ? '' : 'INVALID_NAME');
  static const RequestResponse_Reason DUPLICATE_HANDLE =
      RequestResponse_Reason._(9, _omitEnumNames ? '' : 'DUPLICATE_HANDLE');
  static const RequestResponse_Reason DUPLICATE_NAME =
      RequestResponse_Reason._(10, _omitEnumNames ? '' : 'DUPLICATE_NAME');

  static const $core.List<RequestResponse_Reason> values = <RequestResponse_Reason>[
    OK,
    NOT_FOUND,
    NOT_ALLOWED,
    LIMIT_EXCEEDED,
    QUEUED,
    UNSUPPORTED_TYPE,
    UNCLASSIFIED_ERROR,
    INVALID_HANDLE,
    INVALID_NAME,
    DUPLICATE_HANDLE,
    DUPLICATE_NAME,
  ];

  static final $core.List<RequestResponse_Reason?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 10);
  static RequestResponse_Reason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RequestResponse_Reason._(super.value, super.name);
}

class WrappedJoinRequest_Compression extends $pb.ProtobufEnum {
  static const WrappedJoinRequest_Compression NONE = WrappedJoinRequest_Compression._(0, _omitEnumNames ? '' : 'NONE');
  static const WrappedJoinRequest_Compression GZIP = WrappedJoinRequest_Compression._(1, _omitEnumNames ? '' : 'GZIP');

  static const $core.List<WrappedJoinRequest_Compression> values = <WrappedJoinRequest_Compression>[
    NONE,
    GZIP,
  ];

  static final $core.List<WrappedJoinRequest_Compression?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static WrappedJoinRequest_Compression? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WrappedJoinRequest_Compression._(super.value, super.name);
}

const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
