import Foundation

public struct MemoryMetrics: Codable, Equatable {
  public let usedBytes: UInt64
  public let totalBytes: UInt64

  public var usedPercent: Double {
    guard totalBytes > 0 else { return 0 }
    return (Double(usedBytes) / Double(totalBytes)) * 100.0
  }

  public init(usedBytes: UInt64, totalBytes: UInt64) {
    self.usedBytes = usedBytes
    self.totalBytes = totalBytes
  }
}
