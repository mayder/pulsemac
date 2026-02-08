import Foundation

public struct ThermalFallbackSample: Codable, Equatable {
  public let temperatureC: Double?
  public let fanRPMs: [Double]
  public let rawOutput: String?
  public let errorMessage: String?

  public init(
    temperatureC: Double?,
    fanRPMs: [Double],
    rawOutput: String?,
    errorMessage: String?
  ) {
    self.temperatureC = temperatureC
    self.fanRPMs = fanRPMs
    self.rawOutput = rawOutput
    self.errorMessage = errorMessage
  }
}
