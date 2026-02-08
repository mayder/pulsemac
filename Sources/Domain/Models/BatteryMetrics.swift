import Foundation

public enum PowerSource: String, Codable, CaseIterable {
  case acPower = "ac"
  case battery
  case unknown
}

public struct BatteryMetrics: Codable, Equatable {
  public let chargePercent: Double
  public let isCharging: Bool
  public let powerSource: PowerSource

  public init(chargePercent: Double, isCharging: Bool, powerSource: PowerSource) {
    self.chargePercent = chargePercent
    self.isCharging = isCharging
    self.powerSource = powerSource
  }
}
