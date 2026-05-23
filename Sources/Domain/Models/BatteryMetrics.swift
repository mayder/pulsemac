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
  public let currentCapacity: Double?
  public let maxCapacity: Double?
  public let designCapacity: Double?
  public let cycleCount: Int?
  public let isCharged: Bool?
  public let timeToEmptyMinutes: Int?
  public let timeToFullMinutes: Int?
  public let health: String?

  public init(
    chargePercent: Double,
    isCharging: Bool,
    powerSource: PowerSource,
    currentCapacity: Double? = nil,
    maxCapacity: Double? = nil,
    designCapacity: Double? = nil,
    cycleCount: Int? = nil,
    isCharged: Bool? = nil,
    timeToEmptyMinutes: Int? = nil,
    timeToFullMinutes: Int? = nil,
    health: String? = nil
  ) {
    self.chargePercent = chargePercent
    self.isCharging = isCharging
    self.powerSource = powerSource
    self.currentCapacity = currentCapacity
    self.maxCapacity = maxCapacity
    self.designCapacity = designCapacity
    self.cycleCount = cycleCount
    self.isCharged = isCharged
    self.timeToEmptyMinutes = timeToEmptyMinutes
    self.timeToFullMinutes = timeToFullMinutes
    self.health = health
  }
}
