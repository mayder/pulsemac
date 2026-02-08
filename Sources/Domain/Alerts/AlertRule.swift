import Foundation

public enum AlertComparison: String, Codable, CaseIterable {
  case greaterThan
  case lessThan

  public var label: String {
    switch self {
    case .greaterThan:
      "Maior que"
    case .lessThan:
      "Menor que"
    }
  }

  public var symbol: String {
    switch self {
    case .greaterThan:
      ">"
    case .lessThan:
      "<"
    }
  }

  public func isSatisfied(value: Double, threshold: Double) -> Bool {
    switch self {
    case .greaterThan:
      value > threshold
    case .lessThan:
      value < threshold
    }
  }
}

public enum AlertMetric: String, Codable, CaseIterable {
  case cpuUsagePercent
  case memoryUsedPercent
  case cpuTempC
  case gpuTempC
  case fanMaxRPM
  case diskFreePercent
  case networkDownloadKBps
  case networkUploadKBps
  case batteryChargePercent

  public var label: String {
    switch self {
    case .cpuUsagePercent:
      "CPU"
    case .memoryUsedPercent:
      "Memoria"
    case .cpuTempC:
      "Temp CPU"
    case .gpuTempC:
      "Temp GPU"
    case .fanMaxRPM:
      "Fan"
    case .diskFreePercent:
      "Disco livre"
    case .networkDownloadKBps:
      "Rede download"
    case .networkUploadKBps:
      "Rede upload"
    case .batteryChargePercent:
      "Bateria"
    }
  }

  public var unit: String {
    switch self {
    case .cpuUsagePercent, .memoryUsedPercent:
      "%"
    case .cpuTempC, .gpuTempC:
      "C"
    case .fanMaxRPM:
      "RPM"
    case .diskFreePercent, .batteryChargePercent:
      "%"
    case .networkDownloadKBps, .networkUploadKBps:
      "KB/s"
    }
  }

  public var range: ClosedRange<Double> {
    switch self {
    case .cpuUsagePercent, .memoryUsedPercent:
      10 ... 100
    case .cpuTempC, .gpuTempC:
      40 ... 110
    case .fanMaxRPM:
      500 ... 6000
    case .diskFreePercent, .batteryChargePercent:
      1 ... 100
    case .networkDownloadKBps, .networkUploadKBps:
      0 ... 50000
    }
  }

  public var step: Double {
    switch self {
    case .cpuUsagePercent, .memoryUsedPercent:
      1
    case .cpuTempC, .gpuTempC:
      1
    case .fanMaxRPM:
      50
    case .diskFreePercent, .batteryChargePercent:
      1
    case .networkDownloadKBps, .networkUploadKBps:
      10
    }
  }

  public var defaultThreshold: Double {
    switch self {
    case .cpuUsagePercent:
      80
    case .memoryUsedPercent:
      85
    case .cpuTempC:
      85
    case .gpuTempC:
      85
    case .fanMaxRPM:
      1200
    case .diskFreePercent:
      15
    case .networkDownloadKBps:
      500
    case .networkUploadKBps:
      300
    case .batteryChargePercent:
      20
    }
  }

  public var defaultComparison: AlertComparison {
    switch self {
    case .fanMaxRPM:
      .lessThan
    case .diskFreePercent, .batteryChargePercent:
      .lessThan
    default:
      .greaterThan
    }
  }

  public func value(from snapshot: MetricSnapshot) -> Double? {
    switch self {
    case .cpuUsagePercent:
      return snapshot.cpu.usagePercent
    case .memoryUsedPercent:
      return snapshot.memory.usedPercent
    case .cpuTempC:
      guard let thermal = snapshot.thermal else { return nil }
      return thermal.cpuTempC
    case .gpuTempC:
      guard let thermal = snapshot.thermal else { return nil }
      return thermal.gpuTempC
    case .fanMaxRPM:
      return snapshot.thermal?.fanRPMs.max()
    case .diskFreePercent:
      return snapshot.disk?.freePercent
    case .networkDownloadKBps:
      return snapshot.network.map { $0.downloadBytesPerSec / 1024.0 }
    case .networkUploadKBps:
      return snapshot.network.map { $0.uploadBytesPerSec / 1024.0 }
    case .batteryChargePercent:
      return snapshot.battery?.chargePercent
    }
  }

  public func formatValue(_ value: Double) -> String {
    switch self {
    case .cpuUsagePercent, .memoryUsedPercent:
      String(format: "%.0f%%", value)
    case .cpuTempC, .gpuTempC:
      String(format: "%.0f C", value)
    case .fanMaxRPM:
      String(format: "%.0f RPM", value)
    case .diskFreePercent, .batteryChargePercent:
      String(format: "%.0f%%", value)
    case .networkDownloadKBps, .networkUploadKBps:
      String(format: "%.0f KB/s", value)
    }
  }

  public func formatRuleName(comparison: AlertComparison, threshold: Double) -> String {
    "\(label) \(comparison.symbol) \(formatValue(threshold))"
  }
}

public struct AlertRule: Codable, Equatable, Identifiable {
  public let id: UUID
  public var name: String
  public var metric: AlertMetric
  public var comparison: AlertComparison
  public var threshold: Double
  public var duration: TimeInterval
  public var cooldown: TimeInterval
  public var severity: AlertSeverity
  public var isEnabled: Bool

  public init(
    id: UUID = UUID(),
    name: String,
    metric: AlertMetric,
    comparison: AlertComparison,
    threshold: Double,
    duration: TimeInterval,
    cooldown: TimeInterval,
    severity: AlertSeverity,
    isEnabled: Bool
  ) {
    self.id = id
    self.name = name
    self.metric = metric
    self.comparison = comparison
    self.threshold = threshold
    self.duration = duration
    self.cooldown = cooldown
    self.severity = severity
    self.isEnabled = isEnabled
  }
}
