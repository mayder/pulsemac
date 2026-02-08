import Foundation

public struct NetworkMetrics: Codable, Equatable {
  public let downloadBytesPerSec: Double
  public let uploadBytesPerSec: Double

  public init(downloadBytesPerSec: Double, uploadBytesPerSec: Double) {
    self.downloadBytesPerSec = downloadBytesPerSec
    self.uploadBytesPerSec = uploadBytesPerSec
  }
}
