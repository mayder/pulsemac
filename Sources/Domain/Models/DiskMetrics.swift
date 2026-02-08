import Foundation

public struct DiskMetrics: Codable, Equatable {
  public let freeBytes: UInt64
  public let totalBytes: UInt64

  public var freePercent: Double {
    guard totalBytes > 0 else { return 0 }
    return (Double(freeBytes) / Double(totalBytes)) * 100.0
  }

  public init(freeBytes: UInt64, totalBytes: UInt64) {
    self.freeBytes = freeBytes
    self.totalBytes = totalBytes
  }
}
