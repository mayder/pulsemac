import Foundation

public struct CPUMetrics: Codable, Equatable {
  public let usagePercent: Double
  public let perCoreUsagePercent: [Double]?

  public init(usagePercent: Double, perCoreUsagePercent: [Double]? = nil) {
    self.usagePercent = usagePercent
    self.perCoreUsagePercent = perCoreUsagePercent
  }
}
