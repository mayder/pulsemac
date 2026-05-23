import Foundation

public struct ProcessSnapshot: Codable, Equatable, Identifiable {
  public let pid: Int32
  public let name: String
  public let cpuPercent: Double
  public let memoryBytes: UInt64

  public var id: Int32 {
    pid
  }

  public init(pid: Int32, name: String, cpuPercent: Double, memoryBytes: UInt64) {
    self.pid = pid
    self.name = name
    self.cpuPercent = cpuPercent
    self.memoryBytes = memoryBytes
  }
}

public struct ProcessResourceSnapshot: Codable, Equatable, Identifiable {
  public let pid: Int32
  public let name: String
  public let cpuPercent: Double
  public let memoryBytes: UInt64
  public let diskReadBytesPerSec: Double
  public let diskWriteBytesPerSec: Double
  public let appName: String?
  public let bundleId: String?
  public let bundlePath: String?
  public let executablePath: String?
  public let parentPid: Int32?

  public var id: Int32 {
    pid
  }

  public init(
    pid: Int32,
    name: String,
    cpuPercent: Double,
    memoryBytes: UInt64,
    diskReadBytesPerSec: Double,
    diskWriteBytesPerSec: Double,
    appName: String? = nil,
    bundleId: String? = nil,
    bundlePath: String? = nil,
    executablePath: String? = nil,
    parentPid: Int32? = nil
  ) {
    self.pid = pid
    self.name = name
    self.cpuPercent = cpuPercent
    self.memoryBytes = memoryBytes
    self.diskReadBytesPerSec = diskReadBytesPerSec
    self.diskWriteBytesPerSec = diskWriteBytesPerSec
    self.appName = appName
    self.bundleId = bundleId
    self.bundlePath = bundlePath
    self.executablePath = executablePath
    self.parentPid = parentPid
  }
}

public struct ProcessFavorite: Codable, Equatable, Identifiable {
  public let id: String
  public let name: String
  public let appName: String?
  public let bundleId: String?
  public let bundlePath: String?
  public let executablePath: String?
  public var alertEnabled: Bool

  public init(
    id: String,
    name: String,
    appName: String?,
    bundleId: String?,
    bundlePath: String?,
    executablePath: String?,
    alertEnabled: Bool
  ) {
    self.id = id
    self.name = name
    self.appName = appName
    self.bundleId = bundleId
    self.bundlePath = bundlePath
    self.executablePath = executablePath
    self.alertEnabled = alertEnabled
  }
}
