import Foundation

public struct MetricSnapshot: Codable, Equatable {
  public let timestamp: Date
  public let cpu: CPUMetrics
  public let memory: MemoryMetrics
  public let disk: DiskMetrics?
  public let network: NetworkMetrics?
  public let battery: BatteryMetrics?
  public let topProcesses: TopProcessesSnapshot?
  public let thermal: ThermalMetrics?

  public init(
    timestamp: Date,
    cpu: CPUMetrics,
    memory: MemoryMetrics,
    disk: DiskMetrics? = nil,
    network: NetworkMetrics? = nil,
    battery: BatteryMetrics? = nil,
    topProcesses: TopProcessesSnapshot? = nil,
    thermal: ThermalMetrics? = nil
  ) {
    self.timestamp = timestamp
    self.cpu = cpu
    self.memory = memory
    self.disk = disk
    self.network = network
    self.battery = battery
    self.topProcesses = topProcesses
    self.thermal = thermal
  }
}

public struct MetricHistoryEntry: Codable, Equatable, Identifiable {
  public let id: UUID
  public let timestamp: Date
  public let cpuPercent: Double
  public let memoryUsedPercent: Double
  public let diskFreePercent: Double?
  public let networkDownloadKBps: Double?
  public let networkUploadKBps: Double?
  public let batteryPercent: Double?

  public init(
    id: UUID = UUID(),
    timestamp: Date,
    cpuPercent: Double,
    memoryUsedPercent: Double,
    diskFreePercent: Double?,
    networkDownloadKBps: Double?,
    networkUploadKBps: Double?,
    batteryPercent: Double?
  ) {
    self.id = id
    self.timestamp = timestamp
    self.cpuPercent = cpuPercent
    self.memoryUsedPercent = memoryUsedPercent
    self.diskFreePercent = diskFreePercent
    self.networkDownloadKBps = networkDownloadKBps
    self.networkUploadKBps = networkUploadKBps
    self.batteryPercent = batteryPercent
  }

  public init(snapshot: MetricSnapshot) {
    id = UUID()
    timestamp = snapshot.timestamp
    cpuPercent = snapshot.cpu.usagePercent
    memoryUsedPercent = snapshot.memory.usedPercent
    diskFreePercent = snapshot.disk?.freePercent
    if let network = snapshot.network {
      networkDownloadKBps = network.downloadBytesPerSec / 1024.0
      networkUploadKBps = network.uploadBytesPerSec / 1024.0
    } else {
      networkDownloadKBps = nil
      networkUploadKBps = nil
    }
    batteryPercent = snapshot.battery?.chargePercent
  }
}
