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
