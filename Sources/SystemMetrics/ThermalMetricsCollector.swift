import Foundation
import IOKit
import PulseMacDomain

public final class ThermalMetricsCollector: ThermalMetricsProviding {
  private let smc = SMCClient()
  private var discoveredTemperatureKeys: [String] = []
  private var discoveredFanKeys: [String] = []
  private var didProbeKeys = false
  private var didLogFailure = false

  public init() {}

  public func read() -> ThermalMetrics? {
    let thermalState = readThermalState()
    guard smc.openIfNeeded() else {
      logOnce("SMC indisponivel: falha ao abrir AppleSMC/AppleSMCKeysEndpoint.")
      let diagnostics = makeDiagnostics(message: "SMC indisponivel.")
      return ThermalMetrics(cpuTempC: nil, gpuTempC: nil, fanRPMs: [], thermalState: thermalState, diagnostics: diagnostics)
    }

    var cpuTemp = smc.firstAvailableTemperature(keys: cpuTemperatureKeys)
    let gpuTemp = smc.firstAvailableTemperature(keys: gpuTemperatureKeys)
    var fanRPMs = currentFanKeys().compactMap { key in
      smc.readFanRPM(key: key)
    }

    if cpuTemp == nil, gpuTemp == nil, fanRPMs.isEmpty {
      if !didProbeKeys {
        probeAvailableSensorKeys()
      }
      if !discoveredTemperatureKeys.isEmpty {
        let discovered = smc.firstAvailableTemperature(keys: discoveredTemperatureKeys)
        if cpuTemp == nil { cpuTemp = discovered }
      }
      if fanRPMs.isEmpty, !discoveredFanKeys.isEmpty {
        fanRPMs = discoveredFanKeys.compactMap { smc.readFanRPM(key: $0) }
      }
    }

    if cpuTemp == nil, gpuTemp == nil, fanRPMs.isEmpty {
      logOnce("SMC sem dados: chaves de sensores nao responderam neste Mac.")
      let diagnostics = makeDiagnostics(message: "SMC sem dados de sensores.")
      return ThermalMetrics(cpuTempC: nil, gpuTempC: nil, fanRPMs: [], thermalState: thermalState, diagnostics: diagnostics)
    }

    let diagnostics = makeDiagnostics(message: nil)
    return ThermalMetrics(cpuTempC: cpuTemp, gpuTempC: gpuTemp, fanRPMs: fanRPMs, thermalState: thermalState, diagnostics: diagnostics)
  }

  private func readThermalState() -> ThermalState {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal:
      return .nominal
    case .fair:
      return .fair
    case .serious:
      return .serious
    case .critical:
      return .critical
    @unknown default:
      return .unknown
    }
  }

  private var cpuTemperatureKeys: [String] {
    [
      "TC0P", "TC0E", "TC0F", "TC0H", "TC0D",
      "TC1P", "TC2P", "TC3P", "TC4P", "TC5P",
      "TC6P", "TC7P", "TC8P", "TC9P",
      "TC0C", "TC1C", "TC2C", "TC3C",
      "TC0J", "TC1J",
      "Tp0P", "Tp0A", "Tp0D", "Tp0H", "Tp0T",
      "Tp1P", "Tp1A", "Tp1D", "Tp1H", "Tp1T",
      "Tp2P", "Tp3P", "Tp4P", "Tp5P",
      "Ts0P", "Ts1P",
      "Tm0P", "Tm1P", "Tm0S"
    ]
  }

  private var gpuTemperatureKeys: [String] {
    [
      "TG0P", "TG0D", "TG0H", "TG1P", "TG1D", "TG1H",
      "TG0T", "TG1T",
      "Tp0G", "Tp1G"
    ]
  }

  private var fallbackFanKeys: [String] {
    [
      "F0Ac", "F1Ac", "F2Ac", "F3Ac", "F4Ac",
      "F5Ac", "F6Ac", "F7Ac", "F8Ac", "F9Ac"
    ]
  }

  private func currentFanKeys() -> [String] {
    guard let count = smc.readFanCount(), count > 0 else {
      return fallbackFanKeys
    }
    return (0 ..< count).map { "F\($0)Ac" }
  }

  private func probeAvailableSensorKeys() {
    didProbeKeys = true
    let temperatureCandidates = smc.readKeys(prefix: "T", limit: 2048)
    let fanCandidates = smc.readKeys(prefix: "F", limit: 2048)

    var temps: [String] = []
    for key in temperatureCandidates {
      guard let value = smc.readTemperature(key: key) else { continue }
      guard value > 5, value < 125 else { continue }
      temps.append(key)
      if temps.count >= 6 { break }
    }
    discoveredTemperatureKeys = temps

    var fans: [String] = []
    for key in fanCandidates {
      guard let rpm = smc.readFanRPM(key: key) else { continue }
      guard rpm > 100, rpm < 15000 else { continue }
      fans.append(key)
      if fans.count >= 6 { break }
    }
    discoveredFanKeys = fans
  }

  private func logOnce(_ message: String) {
    guard !didLogFailure else { return }
    didLogFailure = true
    print("PulseMac sensores: \(message)")
  }

  private func makeDiagnostics(message: String?) -> ThermalDiagnostics {
    let smcInfo = smc.diagnostics()
    return ThermalDiagnostics(
      serviceName: smcInfo.serviceName,
      openResult: Int32(smcInfo.openResult),
      openType: smcInfo.openType.map { Int32($0) },
      keyCount: smc.readKeyCount(),
      temperatureKeys: discoveredTemperatureKeys,
      fanKeys: discoveredFanKeys,
      message: message
    )
  }
}

private final class SMCClient {
  private var connection: io_connect_t = 0
  private var opened = false
  private var lastServiceName: String?
  private var lastOpenResult: kern_return_t = KERN_FAILURE
  private var lastOpenType: UInt32?

  struct DiagnosticsSnapshot {
    let serviceName: String?
    let openResult: kern_return_t
    let openType: UInt32?
  }

  deinit {
    close()
  }

  func openIfNeeded() -> Bool {
    if opened { return true }
    let serviceNames = ["AppleSMC", "AppleSMCKeysEndpoint"]
    var service: io_service_t = 0
    for name in serviceNames {
      service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(name))
      if service != 0 {
        lastServiceName = name
        break
      }
    }
    guard service != 0 else { return false }
    let types: [UInt32] = [0, 1, 2, 3]
    var openedResult = KERN_FAILURE
    for type in types {
      openedResult = IOServiceOpen(service, mach_task_self_, type, &connection)
      lastOpenType = type
      if openedResult == KERN_SUCCESS { break }
    }
    IOObjectRelease(service)
    lastOpenResult = openedResult
    opened = (openedResult == KERN_SUCCESS)
    return opened
  }

  func diagnostics() -> DiagnosticsSnapshot {
    DiagnosticsSnapshot(
      serviceName: lastServiceName,
      openResult: lastOpenResult,
      openType: lastOpenType
    )
  }

  func close() {
    if opened {
      IOServiceClose(connection)
      opened = false
    }
  }

  func firstAvailableTemperature(keys: [String]) -> Double? {
    for key in keys {
      if let value = readTemperature(key: key) {
        return value
      }
    }
    return nil
  }

  func readTemperature(key: String) -> Double? {
    guard let value = readValue(key: key) else { return nil }
    return decodeTemperature(value)
  }

  func readFanRPM(key: String) -> Double? {
    guard let value = readValue(key: key) else { return nil }
    return decodeFanRPM(value)
  }

  func readFanCount() -> Int? {
    guard let value = readValue(key: "FNum") else { return nil }
    guard let count = decodeUnsigned(value) else { return nil }
    return Int(count)
  }

  func readKeys(prefix: String, limit: Int) -> [String] {
    guard let count = readKeyCount() else { return [] }
    let maxCount = min(count, 4096)
    let upper = min(maxCount, limit)
    guard upper > 0 else { return [] }
    var keys: [String] = []
    for index in 0 ..< upper {
      guard let key = readKeyByIndex(UInt32(index)) else { continue }
      if key.hasPrefix(prefix) {
        keys.append(key)
      }
    }
    return keys
  }

  private func readValue(key: String) -> SMCValue? {
    guard opened else { return nil }
    let keyCode = fourCharCode(key)
    guard let keyInfo = readKeyInfo(keyCode: keyCode) else { return nil }
    guard let bytes = readBytes(keyCode: keyCode, dataSize: keyInfo.dataSize) else { return nil }
    let rawType = fourCharString(keyInfo.dataType)
    let dataType = rawType
      .replacingOccurrences(of: "\0", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return SMCValue(key: key, dataType: dataType, bytes: bytes)
  }

  func readKeyCount() -> Int? {
    guard let value = readValue(key: "#KEY") else { return nil }
    guard let count = decodeUnsigned(value) else { return nil }
    return Int(count)
  }

  private func readKeyByIndex(_ index: UInt32) -> String? {
    var input = SMCParamStruct()
    var output = SMCParamStruct()
    input.data.data8 = UInt8(kSMCReadKeyIndex)
    input.data.data32 = index
    let inputSize = MemoryLayout<SMCParamStruct>.stride
    var outputSize = MemoryLayout<SMCParamStruct>.stride

    let result = withUnsafeMutablePointer(to: &input) { inputPtr in
      withUnsafeMutablePointer(to: &output) { outputPtr in
        IOConnectCallStructMethod(
          connection,
          UInt32(kSMCUserClient),
          inputPtr,
          inputSize,
          outputPtr,
          &outputSize
        )
      }
    }

    guard result == KERN_SUCCESS else { return nil }
    let key = fourCharString(output.key)
      .replacingOccurrences(of: "\0", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return key.isEmpty ? nil : key
  }

  private func readKeyInfo(keyCode: UInt32) -> SMCKeyInfoData? {
    var input = SMCParamStruct()
    var output = SMCParamStruct()
    input.key = keyCode
    input.data.data8 = UInt8(kSMCReadKeyInfo)
    let inputSize = MemoryLayout<SMCParamStruct>.stride
    var outputSize = MemoryLayout<SMCParamStruct>.stride

    let result = withUnsafeMutablePointer(to: &input) { inputPtr in
      withUnsafeMutablePointer(to: &output) { outputPtr in
        IOConnectCallStructMethod(
          connection,
          UInt32(kSMCUserClient),
          inputPtr,
          inputSize,
          outputPtr,
          &outputSize
        )
      }
    }

    guard result == KERN_SUCCESS else { return nil }
    return output.data.keyInfo
  }

  private func readBytes(keyCode: UInt32, dataSize: UInt32) -> [UInt8]? {
    var input = SMCParamStruct()
    var output = SMCParamStruct()
    input.key = keyCode
    input.data.keyInfo.dataSize = dataSize
    input.data.data8 = UInt8(kSMCReadKey)
    let inputSize = MemoryLayout<SMCParamStruct>.stride
    var outputSize = MemoryLayout<SMCParamStruct>.stride

    let result = withUnsafeMutablePointer(to: &input) { inputPtr in
      withUnsafeMutablePointer(to: &output) { outputPtr in
        IOConnectCallStructMethod(
          connection,
          UInt32(kSMCUserClient),
          inputPtr,
          inputSize,
          outputPtr,
          &outputSize
        )
      }
    }

    guard result == KERN_SUCCESS else { return nil }
    let size = Int(dataSize)
    guard size > 0, size <= 32 else { return nil }
    return withUnsafeBytes(of: output.data.bytes) { rawBuffer in
      Array(rawBuffer.prefix(size))
    }
  }

  private func decodeTemperature(_ value: SMCValue) -> Double? {
    switch value.dataType {
    case "flt":
      decodeFloat(value.bytes)
    case let type where type.hasPrefix("sp"):
      decodeSignedFixedPoint(value.bytes, type: type)
    case let type where type.hasPrefix("fp"):
      decodeUnsignedFixedPoint(value.bytes, type: type)
    default:
      nil
    }
  }

  private func decodeFanRPM(_ value: SMCValue) -> Double? {
    switch value.dataType {
    case "fpe2":
      guard value.bytes.count >= 2 else { return nil }
      let raw = UInt16(value.bytes[0]) << 8 | UInt16(value.bytes[1])
      return Double(raw) / 4.0
    case "flt":
      return decodeFloat(value.bytes)
    case let type where type.hasPrefix("sp"):
      return decodeSignedFixedPoint(value.bytes, type: type)
    case let type where type.hasPrefix("fp"):
      return decodeUnsignedFixedPoint(value.bytes, type: type)
    default:
      return nil
    }
  }

  private func decodeSignedFixedPoint(_ bytes: [UInt8], type: String) -> Double? {
    guard bytes.count >= 2 else { return nil }
    let raw = Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
    let fractionBits = fixedPointFractionBits(from: type)
    let divisor = pow(2.0, Double(fractionBits))
    return Double(raw) / divisor
  }

  private func decodeUnsignedFixedPoint(_ bytes: [UInt8], type: String) -> Double? {
    guard bytes.count >= 2 else { return nil }
    let raw = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    let fractionBits = fixedPointFractionBits(from: type)
    let divisor = pow(2.0, Double(fractionBits))
    return Double(raw) / divisor
  }

  private func fixedPointFractionBits(from type: String) -> Int {
    guard type.count >= 4 else { return 8 }
    let index = type.index(type.startIndex, offsetBy: 3)
    let fractionChar = type[index]
    return Int(String(fractionChar), radix: 16) ?? 8
  }

  private func decodeUnsigned(_ value: SMCValue) -> UInt32? {
    switch value.dataType {
    case "ui8":
      guard let byte = value.bytes.first else { return nil }
      return UInt32(byte)
    case "ui16":
      guard value.bytes.count >= 2 else { return nil }
      return UInt32(value.bytes[0]) << 8 | UInt32(value.bytes[1])
    case "ui32":
      guard value.bytes.count >= 4 else { return nil }
      return UInt32(value.bytes[0]) << 24
        | UInt32(value.bytes[1]) << 16
        | UInt32(value.bytes[2]) << 8
        | UInt32(value.bytes[3])
    case "flt":
      guard let floatValue = decodeFloat(value.bytes) else { return nil }
      return UInt32(floatValue)
    default:
      return nil
    }
  }

  private func decodeFloat(_ bytes: [UInt8]) -> Double? {
    guard bytes.count >= 4 else { return nil }
    let raw = UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
    return Double(Float32(bitPattern: raw))
  }

  private func fourCharCode(_ string: String) -> UInt32 {
    var result: UInt32 = 0
    for byte in string.utf8 {
      result = (result << 8) + UInt32(byte)
    }
    return result
  }

  private func fourCharString(_ value: UInt32) -> String {
    let bytes: [UInt8] = [
      UInt8((value >> 24) & 0xFF),
      UInt8((value >> 16) & 0xFF),
      UInt8((value >> 8) & 0xFF),
      UInt8(value & 0xFF)
    ]
    return String(bytes: bytes, encoding: .ascii) ?? ""
  }
}

private struct SMCValue {
  let key: String
  let dataType: String
  let bytes: [UInt8]
}

private struct SMCParamStruct {
  var key: UInt32 = 0
  var data: SMCKeyData = .init()
}

private struct SMCKeyData {
  var version: SMCVersion = .init()
  var pLimitData: SMCPLimitData = .init()
  var keyInfo: SMCKeyInfoData = .init()
  var result: UInt8 = 0
  var status: UInt8 = 0
  var data8: UInt8 = 0
  var data32: UInt32 = 0
  var bytes: SMCBytes32 = .init()
}

private struct SMCBytes32 {
  var byte00: UInt8 = 0
  var byte01: UInt8 = 0
  var byte02: UInt8 = 0
  var byte03: UInt8 = 0
  var byte04: UInt8 = 0
  var byte05: UInt8 = 0
  var byte06: UInt8 = 0
  var byte07: UInt8 = 0
  var byte08: UInt8 = 0
  var byte09: UInt8 = 0
  var byte10: UInt8 = 0
  var byte11: UInt8 = 0
  var byte12: UInt8 = 0
  var byte13: UInt8 = 0
  var byte14: UInt8 = 0
  var byte15: UInt8 = 0
  var byte16: UInt8 = 0
  var byte17: UInt8 = 0
  var byte18: UInt8 = 0
  var byte19: UInt8 = 0
  var byte20: UInt8 = 0
  var byte21: UInt8 = 0
  var byte22: UInt8 = 0
  var byte23: UInt8 = 0
  var byte24: UInt8 = 0
  var byte25: UInt8 = 0
  var byte26: UInt8 = 0
  var byte27: UInt8 = 0
  var byte28: UInt8 = 0
  var byte29: UInt8 = 0
  var byte30: UInt8 = 0
  var byte31: UInt8 = 0
}

private struct SMCVersion {
  var major: UInt8 = 0
  var minor: UInt8 = 0
  var build: UInt8 = 0
  var reserved: UInt8 = 0
  var release: UInt16 = 0
}

private struct SMCPLimitData {
  var version: UInt16 = 0
  var length: UInt16 = 0
  var cpuPLimit: UInt32 = 0
  var gpuPLimit: UInt32 = 0
  var memPLimit: UInt32 = 0
}

private struct SMCKeyInfoData {
  var dataSize: UInt32 = 0
  var dataType: UInt32 = 0
  var dataAttributes: UInt8 = 0
}

private let kSMCUserClient: Int = 2
private let kSMCReadKey: Int = 5
private let kSMCReadKeyIndex: Int = 8
private let kSMCReadKeyInfo: Int = 9
