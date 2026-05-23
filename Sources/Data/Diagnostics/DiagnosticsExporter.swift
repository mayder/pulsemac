import Darwin
import Foundation
import OSLog
import PulseMacDomain

public struct DiagnosticsReport: Codable {
  public let generatedAt: Date
  public let app: DiagnosticsAppInfo
  public let system: DiagnosticsSystemInfo
  public let settings: AppSettings
  public let alertRules: [AlertRule]
  public let alertHistory: [AlertEvent]
  public let lastSnapshot: MetricSnapshot?

  public init(
    generatedAt: Date,
    app: DiagnosticsAppInfo,
    system: DiagnosticsSystemInfo,
    settings: AppSettings,
    alertRules: [AlertRule],
    alertHistory: [AlertEvent],
    lastSnapshot: MetricSnapshot?
  ) {
    self.generatedAt = generatedAt
    self.app = app
    self.system = system
    self.settings = settings
    self.alertRules = alertRules
    self.alertHistory = alertHistory
    self.lastSnapshot = lastSnapshot
  }
}

public struct QuickReport: Codable {
  public let generatedAt: Date
  public let snapshot: MetricSnapshot?
  public let topProcesses: TopProcessesSnapshot?
  public let activeRules: [AlertRule]

  public init(
    generatedAt: Date,
    snapshot: MetricSnapshot?,
    topProcesses: TopProcessesSnapshot?,
    activeRules: [AlertRule]
  ) {
    self.generatedAt = generatedAt
    self.snapshot = snapshot
    self.topProcesses = topProcesses
    self.activeRules = activeRules
  }
}

public struct DiagnosticsAppInfo: Codable {
  public let bundleId: String
  public let version: String
  public let build: String

  public init(bundleId: String, version: String, build: String) {
    self.bundleId = bundleId
    self.version = version
    self.build = build
  }

  public static func current() -> DiagnosticsAppInfo {
    let bundle = Bundle.main
    let bundleId = bundle.bundleIdentifier ?? "pulsemac"
    let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    return DiagnosticsAppInfo(bundleId: bundleId, version: version, build: build)
  }
}

public struct DiagnosticsSystemInfo: Codable {
  public let osVersion: String
  public let modelIdentifier: String?
  public let cpuBrand: String?
  public let cpuCount: Int
  public let memoryBytes: UInt64
  public let locale: String
  public let timeZone: String

  public init(
    osVersion: String,
    modelIdentifier: String?,
    cpuBrand: String?,
    cpuCount: Int,
    memoryBytes: UInt64,
    locale: String,
    timeZone: String
  ) {
    self.osVersion = osVersion
    self.modelIdentifier = modelIdentifier
    self.cpuBrand = cpuBrand
    self.cpuCount = cpuCount
    self.memoryBytes = memoryBytes
    self.locale = locale
    self.timeZone = timeZone
  }

  public static func current() -> DiagnosticsSystemInfo {
    let processInfo = ProcessInfo.processInfo
    return DiagnosticsSystemInfo(
      osVersion: processInfo.operatingSystemVersionString,
      modelIdentifier: sysctlString("hw.model"),
      cpuBrand: sysctlString("machdep.cpu.brand_string"),
      cpuCount: processInfo.processorCount,
      memoryBytes: processInfo.physicalMemory,
      locale: Locale.current.identifier,
      timeZone: TimeZone.current.identifier
    )
  }

  private static func sysctlString(_ key: String) -> String? {
    var size: size_t = 0
    guard sysctlbyname(key, nil, &size, nil, 0) == 0 else { return nil }
    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
    return String(cString: buffer)
  }
}

public final class DiagnosticsExporter {
  private let settingsStore: SettingsStore
  private let ruleStore: AlertRuleStore
  private let historyStore: AlertHistoryStore
  private let metricsStore: AppGroupMetricsStore
  private let historyLimit: Int
  private let appInfo: DiagnosticsAppInfo
  private let encoder: JSONEncoder

  public init(
    settingsStore: SettingsStore,
    ruleStore: AlertRuleStore,
    historyStore: AlertHistoryStore,
    metricsStore: AppGroupMetricsStore,
    appInfo: DiagnosticsAppInfo = DiagnosticsAppInfo.current(),
    historyLimit: Int = 200
  ) {
    self.settingsStore = settingsStore
    self.ruleStore = ruleStore
    self.historyStore = historyStore
    self.metricsStore = metricsStore
    self.historyLimit = historyLimit
    self.appInfo = appInfo
    encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
  }

  public func export(to url: URL) throws {
    let report = makeReport()
    let data = try encoder.encode(report)
    try data.write(to: url, options: [.atomic])
  }

  public func exportQuickReport(to url: URL) throws {
    let report = makeQuickReport()
    let data = try encoder.encode(report)
    try data.write(to: url, options: [.atomic])
  }

  public func makeReport() -> DiagnosticsReport {
    let settings = settingsStore.load()
    let rules = ruleStore.loadRules()
    let history = historyStore.list(limit: historyLimit)
    let snapshot = metricsStore.load()
    return DiagnosticsReport(
      generatedAt: Date(),
      app: appInfo,
      system: DiagnosticsSystemInfo.current(),
      settings: settings,
      alertRules: rules,
      alertHistory: history,
      lastSnapshot: snapshot
    )
  }

  public func makeQuickReport() -> QuickReport {
    let snapshot = metricsStore.load()
    let rules = ruleStore.loadRules().filter(\.isEnabled)
    return QuickReport(
      generatedAt: Date(),
      snapshot: snapshot,
      topProcesses: snapshot?.topProcesses,
      activeRules: rules
    )
  }
}

public struct DiagnosticsErrorEntry: Codable, Equatable {
  public let message: String
  public let context: String?
  public let recordedAt: Date

  public init(message: String, context: String?, recordedAt: Date) {
    self.message = message
    self.context = context
    self.recordedAt = recordedAt
  }
}

public final class DiagnosticsLogger {
  public static let shared = DiagnosticsLogger()
  private let queue = DispatchQueue(label: "pulsemac.diagnostics.logger")
  private var lastError: DiagnosticsErrorEntry?

  private init() {}

  public func record(_ message: String, context: String? = nil) {
    let entry = DiagnosticsErrorEntry(message: message, context: context, recordedAt: Date())
    queue.async {
      self.lastError = entry
    }
  }

  public func snapshot() -> DiagnosticsErrorEntry? {
    queue.sync {
      lastError
    }
  }
}

public final class UnifiedLogReader: SystemLogProviding {
  public init() {}

  public func readEntries(since: Date, limit: Int) -> [SystemLogEntry] {
    guard limit > 0 else { return [] }
    do {
      let store = try OSLogStore.local()
      let position = store.position(date: since)
      let entries = try store.getEntries(at: position, matching: NSPredicate(value: true))
      var items: [SystemLogEntry] = []
      items.reserveCapacity(min(limit, 200))
      for case let entry as OSLogEntryLog in entries {
        let level = Self.mapLevel(entry.level)
        items.append(
          SystemLogEntry(
            date: entry.date,
            level: level,
            subsystem: entry.subsystem,
            category: entry.category,
            process: entry.process,
            message: entry.composedMessage
          )
        )
        if items.count >= limit {
          break
        }
      }
      return items
    } catch {
      DiagnosticsLogger.shared.record("Falha ao ler logs: \(error.localizedDescription)", context: "Logs")
      return []
    }
  }

  private static func mapLevel(_ level: OSLogEntryLog.Level) -> SystemLogLevel {
    switch level {
    case .debug:
      return .debug
    case .info:
      return .info
    case .notice:
      return .notice
    case .error:
      return .error
    case .fault:
      return .fault
    @unknown default:
      return .info
    }
  }
}
