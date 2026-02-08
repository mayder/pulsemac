import Foundation
import PulseMacDomain

public final class DiskMetricsCollector: DiskMetricsProviding {
  private let path: String

  public init(path: String = "/") {
    self.path = path
  }

  public func read() -> DiskMetrics? {
    guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path) else { return nil }
    guard
      let free = attributes[.systemFreeSize] as? NSNumber,
      let total = attributes[.systemSize] as? NSNumber
    else { return nil }

    return DiskMetrics(freeBytes: free.uint64Value, totalBytes: total.uint64Value)
  }
}
