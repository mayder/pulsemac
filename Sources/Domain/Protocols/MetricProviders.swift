import Foundation

public protocol CPUMetricsProviding {
  func read() -> CPUMetrics
}

public protocol MemoryMetricsProviding {
  func read() -> MemoryMetrics
}

public protocol DiskMetricsProviding {
  func read() -> DiskMetrics?
}

public protocol NetworkMetricsProviding {
  func read() -> NetworkMetrics?
}

public protocol BatteryMetricsProviding {
  func read() -> BatteryMetrics?
}

public protocol TopProcessesProviding {
  func read(limit: Int) -> TopProcessesSnapshot
}

public protocol ProcessResourcesProviding {
  func readResources(limit: Int) -> [ProcessResourceSnapshot]
}

public protocol ThermalMetricsProviding {
  func read() -> ThermalMetrics?
}

public protocol ThermalFallbackProviding {
  func readOnce(completion: @escaping (ThermalFallbackSample) -> Void)
}

public protocol MetricsSnapshotStore {
  func save(_ snapshot: MetricSnapshot)
  func load() -> MetricSnapshot?
}
