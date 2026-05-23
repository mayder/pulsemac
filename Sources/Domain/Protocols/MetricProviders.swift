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

public protocol MetricsHistoryStoring {
  func append(_ entry: MetricHistoryEntry)
  func fetch(since: Date) -> [MetricHistoryEntry]
  func updateRetentionDays(_ days: Int)
}

public enum SystemLogLevel: String, CaseIterable, Identifiable {
  case debug
  case info
  case notice
  case error
  case fault

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .debug:
      "Debug"
    case .info:
      "Info"
    case .notice:
      "Notice"
    case .error:
      "Erro"
    case .fault:
      "Falha"
    }
  }
}

public struct SystemLogEntry: Identifiable, Equatable {
  public let id: UUID
  public let date: Date
  public let level: SystemLogLevel
  public let subsystem: String?
  public let category: String?
  public let process: String?
  public let message: String

  public init(
    id: UUID = UUID(),
    date: Date,
    level: SystemLogLevel,
    subsystem: String?,
    category: String?,
    process: String?,
    message: String
  ) {
    self.id = id
    self.date = date
    self.level = level
    self.subsystem = subsystem
    self.category = category
    self.process = process
    self.message = message
  }
}

public protocol SystemLogProviding {
  func readEntries(since: Date, limit: Int) -> [SystemLogEntry]
}

public protocol FavoritesStoring {
  func load() -> [ProcessFavorite]
  func save(_ favorites: [ProcessFavorite])
}
