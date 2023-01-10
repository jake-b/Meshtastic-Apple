// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: storeforward.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

///
/// TODO: REPLACE
struct StoreAndForward {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///
  /// TODO: REPLACE
  var rr: StoreAndForward.RequestResponse = .unset

  ///
  /// TODO: REPLACE
  var variant: StoreAndForward.OneOf_Variant? = nil

  ///
  /// TODO: REPLACE
  var stats: StoreAndForward.Statistics {
    get {
      if case .stats(let v)? = variant {return v}
      return StoreAndForward.Statistics()
    }
    set {variant = .stats(newValue)}
  }

  ///
  /// TODO: REPLACE
  var history: StoreAndForward.History {
    get {
      if case .history(let v)? = variant {return v}
      return StoreAndForward.History()
    }
    set {variant = .history(newValue)}
  }

  ///
  /// TODO: REPLACE
  var heartbeat: StoreAndForward.Heartbeat {
    get {
      if case .heartbeat(let v)? = variant {return v}
      return StoreAndForward.Heartbeat()
    }
    set {variant = .heartbeat(newValue)}
  }

  ///
  /// Empty Payload
  var empty: Bool {
    get {
      if case .empty(let v)? = variant {return v}
      return false
    }
    set {variant = .empty(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  ///
  /// TODO: REPLACE
  enum OneOf_Variant: Equatable {
    ///
    /// TODO: REPLACE
    case stats(StoreAndForward.Statistics)
    ///
    /// TODO: REPLACE
    case history(StoreAndForward.History)
    ///
    /// TODO: REPLACE
    case heartbeat(StoreAndForward.Heartbeat)
    ///
    /// Empty Payload
    case empty(Bool)

  #if !swift(>=4.1)
    static func ==(lhs: StoreAndForward.OneOf_Variant, rhs: StoreAndForward.OneOf_Variant) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.stats, .stats): return {
        guard case .stats(let l) = lhs, case .stats(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.history, .history): return {
        guard case .history(let l) = lhs, case .history(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.heartbeat, .heartbeat): return {
        guard case .heartbeat(let l) = lhs, case .heartbeat(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.empty, .empty): return {
        guard case .empty(let l) = lhs, case .empty(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  ///
  /// 001 - 063 = From Router
  /// 064 - 127 = From Client
  enum RequestResponse: SwiftProtobuf.Enum {
    typealias RawValue = Int

    ///
    /// Unset/unused
    case unset // = 0

    ///
    /// Router is an in error state.
    case routerError // = 1

    ///
    /// Router heartbeat
    case routerHeartbeat // = 2

    ///
    /// Router has requested the client respond. This can work as a
    /// "are you there" message.
    case routerPing // = 3

    ///
    /// The response to a "Ping"
    case routerPong // = 4

    ///
    /// Router is currently busy. Please try again later.
    case routerBusy // = 5

    ///
    /// Router is responding to a request for history.
    case routerHistory // = 6

    ///
    /// Router is responding to a request for stats.
    case routerStats // = 7

    ///
    /// Client is an in error state.
    case clientError // = 64

    ///
    /// Client has requested a replay from the router.
    case clientHistory // = 65

    ///
    /// Client has requested stats from the router.
    case clientStats // = 66

    ///
    /// Client has requested the router respond. This can work as a
    /// "are you there" message.
    case clientPing // = 67

    ///
    /// The response to a "Ping"
    case clientPong // = 68

    ///
    /// Client has requested that the router abort processing the client's request
    case clientAbort // = 106
    case UNRECOGNIZED(Int)

    init() {
      self = .unset
    }

    init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .unset
      case 1: self = .routerError
      case 2: self = .routerHeartbeat
      case 3: self = .routerPing
      case 4: self = .routerPong
      case 5: self = .routerBusy
      case 6: self = .routerHistory
      case 7: self = .routerStats
      case 64: self = .clientError
      case 65: self = .clientHistory
      case 66: self = .clientStats
      case 67: self = .clientPing
      case 68: self = .clientPong
      case 106: self = .clientAbort
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    var rawValue: Int {
      switch self {
      case .unset: return 0
      case .routerError: return 1
      case .routerHeartbeat: return 2
      case .routerPing: return 3
      case .routerPong: return 4
      case .routerBusy: return 5
      case .routerHistory: return 6
      case .routerStats: return 7
      case .clientError: return 64
      case .clientHistory: return 65
      case .clientStats: return 66
      case .clientPing: return 67
      case .clientPong: return 68
      case .clientAbort: return 106
      case .UNRECOGNIZED(let i): return i
      }
    }

  }

  ///
  /// TODO: REPLACE
  struct Statistics {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    ///
    /// Number of messages we have ever seen
    var messagesTotal: UInt32 = 0

    ///
    /// Number of messages we have currently saved our history.
    var messagesSaved: UInt32 = 0

    ///
    /// Maximum number of messages we will save
    var messagesMax: UInt32 = 0

    ///
    /// Router uptime in seconds
    var upTime: UInt32 = 0

    ///
    /// Number of times any client sent a request to the S&F.
    var requests: UInt32 = 0

    ///
    /// Number of times the history was requested.
    var requestsHistory: UInt32 = 0

    ///
    /// Is the heartbeat enabled on the server?
    var heartbeat: Bool = false

    ///
    /// Is the heartbeat enabled on the server?
    var returnMax: UInt32 = 0

    ///
    /// Is the heartbeat enabled on the server?
    var returnWindow: UInt32 = 0

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  ///
  /// TODO: REPLACE
  struct History {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    ///
    /// Number of that will be sent to the client
    var historyMessages: UInt32 = 0

    ///
    /// The window of messages that was used to filter the history client requested
    var window: UInt32 = 0

    ///
    /// The window of messages that was used to filter the history client requested
    var lastRequest: UInt32 = 0

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  ///
  /// TODO: REPLACE
  struct Heartbeat {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    ///
    /// Number of that will be sent to the client
    var period: UInt32 = 0

    ///
    /// If set, this is not the primary Store & Forward router on the mesh
    var secondary: UInt32 = 0

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  init() {}
}

#if swift(>=4.2)

extension StoreAndForward.RequestResponse: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static var allCases: [StoreAndForward.RequestResponse] = [
    .unset,
    .routerError,
    .routerHeartbeat,
    .routerPing,
    .routerPong,
    .routerBusy,
    .routerHistory,
    .routerStats,
    .clientError,
    .clientHistory,
    .clientStats,
    .clientPing,
    .clientPong,
    .clientAbort,
  ]
}

#endif  // swift(>=4.2)

#if swift(>=5.5) && canImport(_Concurrency)
extension StoreAndForward: @unchecked Sendable {}
extension StoreAndForward.OneOf_Variant: @unchecked Sendable {}
extension StoreAndForward.RequestResponse: @unchecked Sendable {}
extension StoreAndForward.Statistics: @unchecked Sendable {}
extension StoreAndForward.History: @unchecked Sendable {}
extension StoreAndForward.Heartbeat: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension StoreAndForward: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "StoreAndForward"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "rr"),
    2: .same(proto: "stats"),
    3: .same(proto: "history"),
    4: .same(proto: "heartbeat"),
    5: .same(proto: "empty"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.rr) }()
      case 2: try {
        var v: StoreAndForward.Statistics?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .stats(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .stats(v)
        }
      }()
      case 3: try {
        var v: StoreAndForward.History?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .history(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .history(v)
        }
      }()
      case 4: try {
        var v: StoreAndForward.Heartbeat?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .heartbeat(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .heartbeat(v)
        }
      }()
      case 5: try {
        var v: Bool?
        try decoder.decodeSingularBoolField(value: &v)
        if let v = v {
          if self.variant != nil {try decoder.handleConflictingOneOf()}
          self.variant = .empty(v)
        }
      }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if self.rr != .unset {
      try visitor.visitSingularEnumField(value: self.rr, fieldNumber: 1)
    }
    switch self.variant {
    case .stats?: try {
      guard case .stats(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case .history?: try {
      guard case .history(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }()
    case .heartbeat?: try {
      guard case .heartbeat(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }()
    case .empty?: try {
      guard case .empty(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularBoolField(value: v, fieldNumber: 5)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: StoreAndForward, rhs: StoreAndForward) -> Bool {
    if lhs.rr != rhs.rr {return false}
    if lhs.variant != rhs.variant {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension StoreAndForward.RequestResponse: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "UNSET"),
    1: .same(proto: "ROUTER_ERROR"),
    2: .same(proto: "ROUTER_HEARTBEAT"),
    3: .same(proto: "ROUTER_PING"),
    4: .same(proto: "ROUTER_PONG"),
    5: .same(proto: "ROUTER_BUSY"),
    6: .same(proto: "ROUTER_HISTORY"),
    7: .same(proto: "ROUTER_STATS"),
    64: .same(proto: "CLIENT_ERROR"),
    65: .same(proto: "CLIENT_HISTORY"),
    66: .same(proto: "CLIENT_STATS"),
    67: .same(proto: "CLIENT_PING"),
    68: .same(proto: "CLIENT_PONG"),
    106: .same(proto: "CLIENT_ABORT"),
  ]
}

extension StoreAndForward.Statistics: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = StoreAndForward.protoMessageName + ".Statistics"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "messages_total"),
    2: .standard(proto: "messages_saved"),
    3: .standard(proto: "messages_max"),
    4: .standard(proto: "up_time"),
    5: .same(proto: "requests"),
    6: .standard(proto: "requests_history"),
    7: .same(proto: "heartbeat"),
    8: .standard(proto: "return_max"),
    9: .standard(proto: "return_window"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.messagesTotal) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.messagesSaved) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.messagesMax) }()
      case 4: try { try decoder.decodeSingularUInt32Field(value: &self.upTime) }()
      case 5: try { try decoder.decodeSingularUInt32Field(value: &self.requests) }()
      case 6: try { try decoder.decodeSingularUInt32Field(value: &self.requestsHistory) }()
      case 7: try { try decoder.decodeSingularBoolField(value: &self.heartbeat) }()
      case 8: try { try decoder.decodeSingularUInt32Field(value: &self.returnMax) }()
      case 9: try { try decoder.decodeSingularUInt32Field(value: &self.returnWindow) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.messagesTotal != 0 {
      try visitor.visitSingularUInt32Field(value: self.messagesTotal, fieldNumber: 1)
    }
    if self.messagesSaved != 0 {
      try visitor.visitSingularUInt32Field(value: self.messagesSaved, fieldNumber: 2)
    }
    if self.messagesMax != 0 {
      try visitor.visitSingularUInt32Field(value: self.messagesMax, fieldNumber: 3)
    }
    if self.upTime != 0 {
      try visitor.visitSingularUInt32Field(value: self.upTime, fieldNumber: 4)
    }
    if self.requests != 0 {
      try visitor.visitSingularUInt32Field(value: self.requests, fieldNumber: 5)
    }
    if self.requestsHistory != 0 {
      try visitor.visitSingularUInt32Field(value: self.requestsHistory, fieldNumber: 6)
    }
    if self.heartbeat != false {
      try visitor.visitSingularBoolField(value: self.heartbeat, fieldNumber: 7)
    }
    if self.returnMax != 0 {
      try visitor.visitSingularUInt32Field(value: self.returnMax, fieldNumber: 8)
    }
    if self.returnWindow != 0 {
      try visitor.visitSingularUInt32Field(value: self.returnWindow, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: StoreAndForward.Statistics, rhs: StoreAndForward.Statistics) -> Bool {
    if lhs.messagesTotal != rhs.messagesTotal {return false}
    if lhs.messagesSaved != rhs.messagesSaved {return false}
    if lhs.messagesMax != rhs.messagesMax {return false}
    if lhs.upTime != rhs.upTime {return false}
    if lhs.requests != rhs.requests {return false}
    if lhs.requestsHistory != rhs.requestsHistory {return false}
    if lhs.heartbeat != rhs.heartbeat {return false}
    if lhs.returnMax != rhs.returnMax {return false}
    if lhs.returnWindow != rhs.returnWindow {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension StoreAndForward.History: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = StoreAndForward.protoMessageName + ".History"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "history_messages"),
    2: .same(proto: "window"),
    3: .standard(proto: "last_request"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.historyMessages) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.window) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.lastRequest) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.historyMessages != 0 {
      try visitor.visitSingularUInt32Field(value: self.historyMessages, fieldNumber: 1)
    }
    if self.window != 0 {
      try visitor.visitSingularUInt32Field(value: self.window, fieldNumber: 2)
    }
    if self.lastRequest != 0 {
      try visitor.visitSingularUInt32Field(value: self.lastRequest, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: StoreAndForward.History, rhs: StoreAndForward.History) -> Bool {
    if lhs.historyMessages != rhs.historyMessages {return false}
    if lhs.window != rhs.window {return false}
    if lhs.lastRequest != rhs.lastRequest {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension StoreAndForward.Heartbeat: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = StoreAndForward.protoMessageName + ".Heartbeat"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "period"),
    2: .same(proto: "secondary"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.period) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.secondary) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.period != 0 {
      try visitor.visitSingularUInt32Field(value: self.period, fieldNumber: 1)
    }
    if self.secondary != 0 {
      try visitor.visitSingularUInt32Field(value: self.secondary, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: StoreAndForward.Heartbeat, rhs: StoreAndForward.Heartbeat) -> Bool {
    if lhs.period != rhs.period {return false}
    if lhs.secondary != rhs.secondary {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
