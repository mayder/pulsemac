import Foundation

public enum ThermalState: String, Codable, CaseIterable {
  case nominal
  case fair
  case serious
  case critical
  case unknown

  public var label: String {
    switch self {
    case .nominal:
      "Normal"
    case .fair:
      "Atencao"
    case .serious:
      "Serio"
    case .critical:
      "Critico"
    case .unknown:
      "Desconhecido"
    }
  }
}

public struct ThermalMetrics: Codable, Equatable {
  public let cpuTempC: Double?
  public let gpuTempC: Double?
  public let fanRPMs: [Double]
  public let thermalState: ThermalState?
  public let diagnostics: ThermalDiagnostics?

  public init(
    cpuTempC: Double?,
    gpuTempC: Double?,
    fanRPMs: [Double],
    thermalState: ThermalState?,
    diagnostics: ThermalDiagnostics? = nil
  ) {
    self.cpuTempC = cpuTempC
    self.gpuTempC = gpuTempC
    self.fanRPMs = fanRPMs
    self.thermalState = thermalState
    self.diagnostics = diagnostics
  }
}

public struct ThermalDiagnostics: Codable, Equatable {
  public let serviceName: String?
  public let openResult: Int32?
  public let openType: Int32?
  public let keyCount: Int?
  public let temperatureKeys: [String]
  public let fanKeys: [String]
  public let message: String?

  public init(
    serviceName: String?,
    openResult: Int32?,
    openType: Int32?,
    keyCount: Int?,
    temperatureKeys: [String],
    fanKeys: [String],
    message: String?
  ) {
    self.serviceName = serviceName
    self.openResult = openResult
    self.openType = openType
    self.keyCount = keyCount
    self.temperatureKeys = temperatureKeys
    self.fanKeys = fanKeys
    self.message = message
  }
}
