// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: meshtastic/telemetry.proto
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
/// Supported I2C Sensors for telemetry in Meshtastic
enum TelemetrySensorType: SwiftProtobuf.Enum {
  typealias RawValue = Int

  ///
  /// No external telemetry sensor explicitly set
  case sensorUnset // = 0

  ///
  /// High accuracy temperature, pressure, humidity
  case bme280 // = 1

  ///
  /// High accuracy temperature, pressure, humidity, and air resistance
  case bme680 // = 2

  ///
  /// Very high accuracy temperature
  case mcp9808 // = 3

  ///
  /// Moderate accuracy current and voltage
  case ina260 // = 4

  ///
  /// Moderate accuracy current and voltage
  case ina219 // = 5

  ///
  /// High accuracy temperature and pressure
  case bmp280 // = 6

  ///
  /// High accuracy temperature and humidity
  case shtc3 // = 7

  ///
  /// High accuracy pressure
  case lps22 // = 8

  ///
  /// 3-Axis magnetic sensor
  case qmc6310 // = 9

  ///
  /// 6-Axis inertial measurement sensor
  case qmi8658 // = 10

  ///
  /// 3-Axis magnetic sensor
  case qmc5883L // = 11

  ///
  /// High accuracy temperature and humidity
  case sht31 // = 12

  ///
  /// PM2.5 air quality sensor
  case pmsa003I // = 13

  ///
  /// INA3221 3 Channel Voltage / Current Sensor
  case ina3221 // = 14

  ///
  /// BMP085/BMP180 High accuracy temperature and pressure (older Version of BMP280)
  case bmp085 // = 15

  ///
  /// RCWL-9620 Doppler Radar Distance Sensor, used for water level detection
  case rcwl9620 // = 16

  ///
  /// Sensirion High accuracy temperature and humidity
  case sht4X // = 17

  ///
  /// VEML7700 high accuracy ambient light(Lux) digital 16-bit resolution sensor.
  case veml7700 // = 18

  ///
  /// MLX90632 non-contact IR temperature sensor.
  case mlx90632 // = 19

  ///
  /// TI OPT3001 Ambient Light Sensor
  case opt3001 // = 20

  ///
  /// Lite On LTR-390UV-01 UV Light Sensor
  case ltr390Uv // = 21

  ///
  /// AMS TSL25911FN RGB Light Sensor
  case tsl25911Fn // = 22

  ///
  /// AHT10 Integrated temperature and humidity sensor
  case aht10 // = 23
  case UNRECOGNIZED(Int)

  init() {
    self = .sensorUnset
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .sensorUnset
    case 1: self = .bme280
    case 2: self = .bme680
    case 3: self = .mcp9808
    case 4: self = .ina260
    case 5: self = .ina219
    case 6: self = .bmp280
    case 7: self = .shtc3
    case 8: self = .lps22
    case 9: self = .qmc6310
    case 10: self = .qmi8658
    case 11: self = .qmc5883L
    case 12: self = .sht31
    case 13: self = .pmsa003I
    case 14: self = .ina3221
    case 15: self = .bmp085
    case 16: self = .rcwl9620
    case 17: self = .sht4X
    case 18: self = .veml7700
    case 19: self = .mlx90632
    case 20: self = .opt3001
    case 21: self = .ltr390Uv
    case 22: self = .tsl25911Fn
    case 23: self = .aht10
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  var rawValue: Int {
    switch self {
    case .sensorUnset: return 0
    case .bme280: return 1
    case .bme680: return 2
    case .mcp9808: return 3
    case .ina260: return 4
    case .ina219: return 5
    case .bmp280: return 6
    case .shtc3: return 7
    case .lps22: return 8
    case .qmc6310: return 9
    case .qmi8658: return 10
    case .qmc5883L: return 11
    case .sht31: return 12
    case .pmsa003I: return 13
    case .ina3221: return 14
    case .bmp085: return 15
    case .rcwl9620: return 16
    case .sht4X: return 17
    case .veml7700: return 18
    case .mlx90632: return 19
    case .opt3001: return 20
    case .ltr390Uv: return 21
    case .tsl25911Fn: return 22
    case .aht10: return 23
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension TelemetrySensorType: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static let allCases: [TelemetrySensorType] = [
    .sensorUnset,
    .bme280,
    .bme680,
    .mcp9808,
    .ina260,
    .ina219,
    .bmp280,
    .shtc3,
    .lps22,
    .qmc6310,
    .qmi8658,
    .qmc5883L,
    .sht31,
    .pmsa003I,
    .ina3221,
    .bmp085,
    .rcwl9620,
    .sht4X,
    .veml7700,
    .mlx90632,
    .opt3001,
    .ltr390Uv,
    .tsl25911Fn,
    .aht10,
  ]
}

#endif  // swift(>=4.2)

///
/// Key native device metrics such as battery level
struct DeviceMetrics {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///
  /// 0-100 (>100 means powered)
  var batteryLevel: UInt32 = 0

  ///
  /// Voltage measured
  var voltage: Float = 0

  ///
  /// Utilization for the current channel, including well formed TX, RX and malformed RX (aka noise).
  var channelUtilization: Float = 0

  ///
  /// Percent of airtime for transmission used within the last hour.
  var airUtilTx: Float = 0

  ///
  /// How long the device has been running since the last reboot (in seconds)
  var uptimeSeconds: UInt32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

///
/// Weather station or other environmental metrics
struct EnvironmentMetrics {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///
  /// Temperature measured
  var temperature: Float = 0

  ///
  /// Relative humidity percent measured
  var relativeHumidity: Float = 0

  ///
  /// Barometric pressure in hPA measured
  var barometricPressure: Float = 0

  ///
  /// Gas resistance in MOhm measured
  var gasResistance: Float = 0

  ///
  /// Voltage measured (To be depreciated in favor of PowerMetrics in Meshtastic 3.x)
  var voltage: Float = 0

  ///
  /// Current measured (To be depreciated in favor of PowerMetrics in Meshtastic 3.x)
  var current: Float = 0

  /// 
  /// relative scale IAQ value as measured by Bosch BME680 . value 0-500.
  /// Belongs to Air Quality but is not particle but VOC measurement. Other VOC values can also be put in here.
  var iaq: UInt32 = 0

  ///
  /// RCWL9620 Doppler Radar Distance Sensor, used for water level detection. Float value in mm.
  var distance: Float = 0

  ///
  /// VEML7700 high accuracy ambient light(Lux) digital 16-bit resolution sensor.
  var lux: Float = 0

  ///
  /// VEML7700 high accuracy white light(irradiance) not calibrated digital 16-bit resolution sensor.
  var whiteLux: Float = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

///
/// Power Metrics (voltage / current / etc)
struct PowerMetrics {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///
  /// Voltage (Ch1)
  var ch1Voltage: Float = 0

  ///
  /// Current (Ch1)
  var ch1Current: Float = 0

  ///
  /// Voltage (Ch2)
  var ch2Voltage: Float = 0

  ///
  /// Current (Ch2)
  var ch2Current: Float = 0

  ///
  /// Voltage (Ch3)
  var ch3Voltage: Float = 0

  ///
  /// Current (Ch3)
  var ch3Current: Float = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

///
/// Air quality metrics
struct AirQualityMetrics {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///
  /// Concentration Units Standard PM1.0
  var pm10Standard: UInt32 = 0

  ///
  /// Concentration Units Standard PM2.5
  var pm25Standard: UInt32 = 0

  ///
  /// Concentration Units Standard PM10.0
  var pm100Standard: UInt32 = 0

  ///
  /// Concentration Units Environmental PM1.0
  var pm10Environmental: UInt32 = 0

  ///
  /// Concentration Units Environmental PM2.5
  var pm25Environmental: UInt32 = 0

  ///
  /// Concentration Units Environmental PM10.0
  var pm100Environmental: UInt32 = 0

  ///
  /// 0.3um Particle Count
  var particles03Um: UInt32 = 0

  ///
  /// 0.5um Particle Count
  var particles05Um: UInt32 = 0

  ///
  /// 1.0um Particle Count
  var particles10Um: UInt32 = 0

  ///
  /// 2.5um Particle Count
  var particles25Um: UInt32 = 0

  ///
  /// 5.0um Particle Count
  var particles50Um: UInt32 = 0

  ///
  /// 10.0um Particle Count
  var particles100Um: UInt32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

///
/// Types of Measurements the telemetry module is equipped to handle
struct Telemetry {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///
  /// Seconds since 1970 - or 0 for unknown/unset
  var time: UInt32 = 0

  var variant: Telemetry.OneOf_Variant? = nil

  ///
  /// Key native device metrics such as battery level
  var deviceMetrics: DeviceMetrics {
    get {
      if case .deviceMetrics(let v)? = variant {return v}
      return DeviceMetrics()
    }
    set {variant = .deviceMetrics(newValue)}
  }

  ///
  /// Weather station or other environmental metrics
  var environmentMetrics: EnvironmentMetrics {
    get {
      if case .environmentMetrics(let v)? = variant {return v}
      return EnvironmentMetrics()
    }
    set {variant = .environmentMetrics(newValue)}
  }

  ///
  /// Air quality metrics
  var airQualityMetrics: AirQualityMetrics {
    get {
      if case .airQualityMetrics(let v)? = variant {return v}
      return AirQualityMetrics()
    }
    set {variant = .airQualityMetrics(newValue)}
  }

  ///
  /// Power Metrics
  var powerMetrics: PowerMetrics {
    get {
      if case .powerMetrics(let v)? = variant {return v}
      return PowerMetrics()
    }
    set {variant = .powerMetrics(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum OneOf_Variant: Equatable {
    ///
    /// Key native device metrics such as battery level
    case deviceMetrics(DeviceMetrics)
    ///
    /// Weather station or other environmental metrics
    case environmentMetrics(EnvironmentMetrics)
    ///
    /// Air quality metrics
    case airQualityMetrics(AirQualityMetrics)
    ///
    /// Power Metrics
    case powerMetrics(PowerMetrics)

  #if !swift(>=4.1)
    static func ==(lhs: Telemetry.OneOf_Variant, rhs: Telemetry.OneOf_Variant) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.deviceMetrics, .deviceMetrics): return {
        guard case .deviceMetrics(let l) = lhs, case .deviceMetrics(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.environmentMetrics, .environmentMetrics): return {
        guard case .environmentMetrics(let l) = lhs, case .environmentMetrics(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.airQualityMetrics, .airQualityMetrics): return {
        guard case .airQualityMetrics(let l) = lhs, case .airQualityMetrics(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.powerMetrics, .powerMetrics): return {
        guard case .powerMetrics(let l) = lhs, case .powerMetrics(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension TelemetrySensorType: @unchecked Sendable {}
extension DeviceMetrics: @unchecked Sendable {}
extension EnvironmentMetrics: @unchecked Sendable {}
extension PowerMetrics: @unchecked Sendable {}
extension AirQualityMetrics: @unchecked Sendable {}
extension Telemetry: @unchecked Sendable {}
extension Telemetry.OneOf_Variant: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "meshtastic"

extension TelemetrySensorType: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "SENSOR_UNSET"),
    1: .same(proto: "BME280"),
    2: .same(proto: "BME680"),
    3: .same(proto: "MCP9808"),
    4: .same(proto: "INA260"),
    5: .same(proto: "INA219"),
    6: .same(proto: "BMP280"),
    7: .same(proto: "SHTC3"),
    8: .same(proto: "LPS22"),
    9: .same(proto: "QMC6310"),
    10: .same(proto: "QMI8658"),
    11: .same(proto: "QMC5883L"),
    12: .same(proto: "SHT31"),
    13: .same(proto: "PMSA003I"),
    14: .same(proto: "INA3221"),
    15: .same(proto: "BMP085"),
    16: .same(proto: "RCWL9620"),
    17: .same(proto: "SHT4X"),
    18: .same(proto: "VEML7700"),
    19: .same(proto: "MLX90632"),
    20: .same(proto: "OPT3001"),
    21: .same(proto: "LTR390UV"),
    22: .same(proto: "TSL25911FN"),
    23: .same(proto: "AHT10"),
  ]
}

extension DeviceMetrics: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".DeviceMetrics"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "battery_level"),
    2: .same(proto: "voltage"),
    3: .standard(proto: "channel_utilization"),
    4: .standard(proto: "air_util_tx"),
    5: .standard(proto: "uptime_seconds"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.batteryLevel) }()
      case 2: try { try decoder.decodeSingularFloatField(value: &self.voltage) }()
      case 3: try { try decoder.decodeSingularFloatField(value: &self.channelUtilization) }()
      case 4: try { try decoder.decodeSingularFloatField(value: &self.airUtilTx) }()
      case 5: try { try decoder.decodeSingularUInt32Field(value: &self.uptimeSeconds) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.batteryLevel != 0 {
      try visitor.visitSingularUInt32Field(value: self.batteryLevel, fieldNumber: 1)
    }
    if self.voltage != 0 {
      try visitor.visitSingularFloatField(value: self.voltage, fieldNumber: 2)
    }
    if self.channelUtilization != 0 {
      try visitor.visitSingularFloatField(value: self.channelUtilization, fieldNumber: 3)
    }
    if self.airUtilTx != 0 {
      try visitor.visitSingularFloatField(value: self.airUtilTx, fieldNumber: 4)
    }
    if self.uptimeSeconds != 0 {
      try visitor.visitSingularUInt32Field(value: self.uptimeSeconds, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: DeviceMetrics, rhs: DeviceMetrics) -> Bool {
    if lhs.batteryLevel != rhs.batteryLevel {return false}
    if lhs.voltage != rhs.voltage {return false}
    if lhs.channelUtilization != rhs.channelUtilization {return false}
    if lhs.airUtilTx != rhs.airUtilTx {return false}
    if lhs.uptimeSeconds != rhs.uptimeSeconds {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension EnvironmentMetrics: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".EnvironmentMetrics"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "temperature"),
    2: .standard(proto: "relative_humidity"),
    3: .standard(proto: "barometric_pressure"),
    4: .standard(proto: "gas_resistance"),
    5: .same(proto: "voltage"),
    6: .same(proto: "current"),
    7: .same(proto: "iaq"),
    8: .same(proto: "distance"),
    9: .same(proto: "lux"),
    10: .standard(proto: "white_lux"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularFloatField(value: &self.temperature) }()
      case 2: try { try decoder.decodeSingularFloatField(value: &self.relativeHumidity) }()
      case 3: try { try decoder.decodeSingularFloatField(value: &self.barometricPressure) }()
      case 4: try { try decoder.decodeSingularFloatField(value: &self.gasResistance) }()
      case 5: try { try decoder.decodeSingularFloatField(value: &self.voltage) }()
      case 6: try { try decoder.decodeSingularFloatField(value: &self.current) }()
      case 7: try { try decoder.decodeSingularUInt32Field(value: &self.iaq) }()
      case 8: try { try decoder.decodeSingularFloatField(value: &self.distance) }()
      case 9: try { try decoder.decodeSingularFloatField(value: &self.lux) }()
      case 10: try { try decoder.decodeSingularFloatField(value: &self.whiteLux) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.temperature != 0 {
      try visitor.visitSingularFloatField(value: self.temperature, fieldNumber: 1)
    }
    if self.relativeHumidity != 0 {
      try visitor.visitSingularFloatField(value: self.relativeHumidity, fieldNumber: 2)
    }
    if self.barometricPressure != 0 {
      try visitor.visitSingularFloatField(value: self.barometricPressure, fieldNumber: 3)
    }
    if self.gasResistance != 0 {
      try visitor.visitSingularFloatField(value: self.gasResistance, fieldNumber: 4)
    }
    if self.voltage != 0 {
      try visitor.visitSingularFloatField(value: self.voltage, fieldNumber: 5)
    }
    if self.current != 0 {
      try visitor.visitSingularFloatField(value: self.current, fieldNumber: 6)
    }
    if self.iaq != 0 {
      try visitor.visitSingularUInt32Field(value: self.iaq, fieldNumber: 7)
    }
    if self.distance != 0 {
      try visitor.visitSingularFloatField(value: self.distance, fieldNumber: 8)
    }
    if self.lux != 0 {
      try visitor.visitSingularFloatField(value: self.lux, fieldNumber: 9)
    }
    if self.whiteLux != 0 {
      try visitor.visitSingularFloatField(value: self.whiteLux, fieldNumber: 10)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: EnvironmentMetrics, rhs: EnvironmentMetrics) -> Bool {
    if lhs.temperature != rhs.temperature {return false}
    if lhs.relativeHumidity != rhs.relativeHumidity {return false}
    if lhs.barometricPressure != rhs.barometricPressure {return false}
    if lhs.gasResistance != rhs.gasResistance {return false}
    if lhs.voltage != rhs.voltage {return false}
    if lhs.current != rhs.current {return false}
    if lhs.iaq != rhs.iaq {return false}
    if lhs.distance != rhs.distance {return false}
    if lhs.lux != rhs.lux {return false}
    if lhs.whiteLux != rhs.whiteLux {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension PowerMetrics: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".PowerMetrics"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "ch1_voltage"),
    2: .standard(proto: "ch1_current"),
    3: .standard(proto: "ch2_voltage"),
    4: .standard(proto: "ch2_current"),
    5: .standard(proto: "ch3_voltage"),
    6: .standard(proto: "ch3_current"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularFloatField(value: &self.ch1Voltage) }()
      case 2: try { try decoder.decodeSingularFloatField(value: &self.ch1Current) }()
      case 3: try { try decoder.decodeSingularFloatField(value: &self.ch2Voltage) }()
      case 4: try { try decoder.decodeSingularFloatField(value: &self.ch2Current) }()
      case 5: try { try decoder.decodeSingularFloatField(value: &self.ch3Voltage) }()
      case 6: try { try decoder.decodeSingularFloatField(value: &self.ch3Current) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.ch1Voltage != 0 {
      try visitor.visitSingularFloatField(value: self.ch1Voltage, fieldNumber: 1)
    }
    if self.ch1Current != 0 {
      try visitor.visitSingularFloatField(value: self.ch1Current, fieldNumber: 2)
    }
    if self.ch2Voltage != 0 {
      try visitor.visitSingularFloatField(value: self.ch2Voltage, fieldNumber: 3)
    }
    if self.ch2Current != 0 {
      try visitor.visitSingularFloatField(value: self.ch2Current, fieldNumber: 4)
    }
    if self.ch3Voltage != 0 {
      try visitor.visitSingularFloatField(value: self.ch3Voltage, fieldNumber: 5)
    }
    if self.ch3Current != 0 {
      try visitor.visitSingularFloatField(value: self.ch3Current, fieldNumber: 6)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: PowerMetrics, rhs: PowerMetrics) -> Bool {
    if lhs.ch1Voltage != rhs.ch1Voltage {return false}
    if lhs.ch1Current != rhs.ch1Current {return false}
    if lhs.ch2Voltage != rhs.ch2Voltage {return false}
    if lhs.ch2Current != rhs.ch2Current {return false}
    if lhs.ch3Voltage != rhs.ch3Voltage {return false}
    if lhs.ch3Current != rhs.ch3Current {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension AirQualityMetrics: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".AirQualityMetrics"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "pm10_standard"),
    2: .standard(proto: "pm25_standard"),
    3: .standard(proto: "pm100_standard"),
    4: .standard(proto: "pm10_environmental"),
    5: .standard(proto: "pm25_environmental"),
    6: .standard(proto: "pm100_environmental"),
    7: .standard(proto: "particles_03um"),
    8: .standard(proto: "particles_05um"),
    9: .standard(proto: "particles_10um"),
    10: .standard(proto: "particles_25um"),
    11: .standard(proto: "particles_50um"),
    12: .standard(proto: "particles_100um"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.pm10Standard) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.pm25Standard) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.pm100Standard) }()
      case 4: try { try decoder.decodeSingularUInt32Field(value: &self.pm10Environmental) }()
      case 5: try { try decoder.decodeSingularUInt32Field(value: &self.pm25Environmental) }()
      case 6: try { try decoder.decodeSingularUInt32Field(value: &self.pm100Environmental) }()
      case 7: try { try decoder.decodeSingularUInt32Field(value: &self.particles03Um) }()
      case 8: try { try decoder.decodeSingularUInt32Field(value: &self.particles05Um) }()
      case 9: try { try decoder.decodeSingularUInt32Field(value: &self.particles10Um) }()
      case 10: try { try decoder.decodeSingularUInt32Field(value: &self.particles25Um) }()
      case 11: try { try decoder.decodeSingularUInt32Field(value: &self.particles50Um) }()
      case 12: try { try decoder.decodeSingularUInt32Field(value: &self.particles100Um) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.pm10Standard != 0 {
      try visitor.visitSingularUInt32Field(value: self.pm10Standard, fieldNumber: 1)
    }
    if self.pm25Standard != 0 {
      try visitor.visitSingularUInt32Field(value: self.pm25Standard, fieldNumber: 2)
    }
    if self.pm100Standard != 0 {
      try visitor.visitSingularUInt32Field(value: self.pm100Standard, fieldNumber: 3)
    }
    if self.pm10Environmental != 0 {
      try visitor.visitSingularUInt32Field(value: self.pm10Environmental, fieldNumber: 4)
    }
    if self.pm25Environmental != 0 {
      try visitor.visitSingularUInt32Field(value: self.pm25Environmental, fieldNumber: 5)
    }
    if self.pm100Environmental != 0 {
      try visitor.visitSingularUInt32Field(value: self.pm100Environmental, fieldNumber: 6)
    }
    if self.particles03Um != 0 {
      try visitor.visitSingularUInt32Field(value: self.particles03Um, fieldNumber: 7)
    }
    if self.particles05Um != 0 {
      try visitor.visitSingularUInt32Field(value: self.particles05Um, fieldNumber: 8)
    }
    if self.particles10Um != 0 {
      try visitor.visitSingularUInt32Field(value: self.particles10Um, fieldNumber: 9)
    }
    if self.particles25Um != 0 {
      try visitor.visitSingularUInt32Field(value: self.particles25Um, fieldNumber: 10)
    }
    if self.particles50Um != 0 {
      try visitor.visitSingularUInt32Field(value: self.particles50Um, fieldNumber: 11)
    }
    if self.particles100Um != 0 {
      try visitor.visitSingularUInt32Field(value: self.particles100Um, fieldNumber: 12)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: AirQualityMetrics, rhs: AirQualityMetrics) -> Bool {
    if lhs.pm10Standard != rhs.pm10Standard {return false}
    if lhs.pm25Standard != rhs.pm25Standard {return false}
    if lhs.pm100Standard != rhs.pm100Standard {return false}
    if lhs.pm10Environmental != rhs.pm10Environmental {return false}
    if lhs.pm25Environmental != rhs.pm25Environmental {return false}
    if lhs.pm100Environmental != rhs.pm100Environmental {return false}
    if lhs.particles03Um != rhs.particles03Um {return false}
    if lhs.particles05Um != rhs.particles05Um {return false}
    if lhs.particles10Um != rhs.particles10Um {return false}
    if lhs.particles25Um != rhs.particles25Um {return false}
    if lhs.particles50Um != rhs.particles50Um {return false}
    if lhs.particles100Um != rhs.particles100Um {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Telemetry: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Telemetry"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "time"),
    2: .standard(proto: "device_metrics"),
    3: .standard(proto: "environment_metrics"),
    4: .standard(proto: "air_quality_metrics"),
    5: .standard(proto: "power_metrics"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularFixed32Field(value: &self.time) }()
      case 2: try {
        var v: DeviceMetrics?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .deviceMetrics(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .deviceMetrics(v)
        }
      }()
      case 3: try {
        var v: EnvironmentMetrics?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .environmentMetrics(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .environmentMetrics(v)
        }
      }()
      case 4: try {
        var v: AirQualityMetrics?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .airQualityMetrics(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .airQualityMetrics(v)
        }
      }()
      case 5: try {
        var v: PowerMetrics?
        var hadOneofValue = false
        if let current = self.variant {
          hadOneofValue = true
          if case .powerMetrics(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.variant = .powerMetrics(v)
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
    if self.time != 0 {
      try visitor.visitSingularFixed32Field(value: self.time, fieldNumber: 1)
    }
    switch self.variant {
    case .deviceMetrics?: try {
      guard case .deviceMetrics(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case .environmentMetrics?: try {
      guard case .environmentMetrics(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }()
    case .airQualityMetrics?: try {
      guard case .airQualityMetrics(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }()
    case .powerMetrics?: try {
      guard case .powerMetrics(let v)? = self.variant else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Telemetry, rhs: Telemetry) -> Bool {
    if lhs.time != rhs.time {return false}
    if lhs.variant != rhs.variant {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
