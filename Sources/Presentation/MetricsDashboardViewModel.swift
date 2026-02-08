import Combine
import Foundation
import PulseMacDomain

public final class MetricsDashboardViewModel: ObservableObject {
  @Published public private(set) var cpuText: String = "CPU --"
  @Published public private(set) var memoryText: String = "Memoria --"
  @Published public private(set) var diskText: String = "Disco --"
  @Published public private(set) var networkText: String = "Rede --"
  @Published public private(set) var batteryText: String = "Bateria --"
  @Published public private(set) var lastUpdatedText: String = ""
  @Published public private(set) var cpuPercent: Double = 0
  @Published public private(set) var memoryPercent: Double = 0
  @Published public private(set) var diskFreePercent: Double?
  @Published public private(set) var batteryPercent: Double?
  @Published public private(set) var memoryUsedGB: Double?
  @Published public private(set) var memoryFreeGB: Double?
  @Published public private(set) var memoryTotalGB: Double?
  @Published public private(set) var diskFreeGB: Double?
  @Published public private(set) var diskUsedGB: Double?
  @Published public private(set) var diskTotalGB: Double?
  @Published public private(set) var batterySourceText: String = "--"
  @Published public private(set) var networkDownloadKBps: Double?
  @Published public private(set) var networkUploadKBps: Double?
  @Published public private(set) var cpuHistory: [Double] = []
  @Published public private(set) var memoryHistory: [Double] = []
  @Published public private(set) var diskHistory: [Double] = []
  @Published public private(set) var batteryHistory: [Double] = []
  @Published public private(set) var networkDownloadHistory: [Double] = []
  @Published public private(set) var networkUploadHistory: [Double] = []
  @Published public private(set) var topCpuProcesses: [ProcessRow] = []
  @Published public private(set) var topMemoryProcesses: [ProcessRow] = []
  @Published public private(set) var processOverview: [ProcessRow] = []
  @Published public private(set) var processHistory: [Int32: ProcessHistory] = [:]
  @Published public private(set) var thermalText: String = "Temperatura --"
  @Published public private(set) var fansText: String = "Fans --"
  @Published public private(set) var thermalDetailText: String = "Nao disponivel neste Mac"
  @Published public private(set) var fansDetailText: String = "Nao disponivel neste Mac"
  @Published public private(set) var hasThermalData: Bool = false
  @Published public private(set) var hasFanData: Bool = false
  @Published public private(set) var thermalDiagnosticsRows: [ThermalDiagnosticRow] = []
  @Published public private(set) var thermalDiagnosticsMessage: String = ""
  @Published public private(set) var powermetricsStatusText: String = ""
  @Published public private(set) var powermetricsTemperatureText: String = "--"
  @Published public private(set) var powermetricsFansText: String = "--"
  @Published public private(set) var powermetricsPressureText: String = "--"
  @Published public private(set) var powermetricsLastUpdatedText: String = ""
  @Published public private(set) var powermetricsRawOutput: String = ""
  @Published public var selectedCategory: MetricsCategory = .overview

  private var showDisk = true
  private var showNetwork = true
  private var showBattery = true
  private var cancellables: Set<AnyCancellable> = []
  private let historyLimit = 60
  private let processHistoryLimit = 60
  private let powermetricsProvider: ThermalFallbackProviding?

  public init(powermetricsProvider: ThermalFallbackProviding? = nil) {
    self.powermetricsProvider = powermetricsProvider
  }

  public func bind(to publisher: AnyPublisher<MetricSnapshot, Never>) {
    publisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] snapshot in
        self?.apply(snapshot: snapshot)
      }
      .store(in: &cancellables)
  }

  public func updateVisibility(showDisk: Bool, showNetwork: Bool, showBattery: Bool) {
    self.showDisk = showDisk
    self.showNetwork = showNetwork
    self.showBattery = showBattery
  }

  private func apply(snapshot: MetricSnapshot) {
    cpuPercent = snapshot.cpu.usagePercent
    append(cpuPercent, to: &cpuHistory)
    cpuText = String(format: "CPU %.0f%%", cpuPercent)
    let usedGB = Double(snapshot.memory.usedBytes) / 1_073_741_824.0
    let totalGB = Double(snapshot.memory.totalBytes) / 1_073_741_824.0
    let freeGB = max(totalGB - usedGB, 0)
    memoryPercent = snapshot.memory.usedPercent
    append(memoryPercent, to: &memoryHistory)
    memoryText = String(format: "Memoria usada %.1f GB", usedGB)
    memoryUsedGB = usedGB
    memoryTotalGB = totalGB
    memoryFreeGB = freeGB
    lastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: snapshot.timestamp))"

    if showDisk {
      if let disk = snapshot.disk {
        let freeGB = Double(disk.freeBytes) / 1_073_741_824.0
        let totalGB = Double(disk.totalBytes) / 1_073_741_824.0
        let usedGB = max(totalGB - freeGB, 0)
        diskFreePercent = disk.freePercent
        append(disk.freePercent, to: &diskHistory)
        diskText = String(format: "Disco livre %.1f GB (usado %.1f GB)", freeGB, usedGB)
        diskFreeGB = freeGB
        diskTotalGB = totalGB
        diskUsedGB = usedGB
      } else {
        diskText = "Disco --"
        diskFreePercent = nil
        diskFreeGB = nil
        diskTotalGB = nil
        diskUsedGB = nil
        diskHistory.removeAll(keepingCapacity: true)
      }
    } else {
      diskText = "Disco desativado"
      diskFreePercent = nil
      diskFreeGB = nil
      diskTotalGB = nil
      diskUsedGB = nil
      diskHistory.removeAll(keepingCapacity: true)
    }

    if showNetwork {
      if let network = snapshot.network {
        let downloadRate = formatRate(network.downloadBytesPerSec)
        let uploadRate = formatRate(network.uploadBytesPerSec)
        let downloadKBps = network.downloadBytesPerSec / 1024.0
        let uploadKBps = network.uploadBytesPerSec / 1024.0
        networkDownloadKBps = downloadKBps
        networkUploadKBps = uploadKBps
        append(downloadKBps, to: &networkDownloadHistory)
        append(uploadKBps, to: &networkUploadHistory)
        networkText = "Rede \(downloadRate) ↓ / \(uploadRate) ↑"
      } else {
        networkText = "Rede --"
        networkDownloadKBps = nil
        networkUploadKBps = nil
        networkDownloadHistory.removeAll(keepingCapacity: true)
        networkUploadHistory.removeAll(keepingCapacity: true)
      }
    } else {
      networkText = "Rede desativada"
      networkDownloadKBps = nil
      networkUploadKBps = nil
      networkDownloadHistory.removeAll(keepingCapacity: true)
      networkUploadHistory.removeAll(keepingCapacity: true)
    }

    if showBattery {
      if let battery = snapshot.battery {
        let source = battery.powerSource == .acPower ? "AC" : battery.powerSource == .battery ? "Bateria" : "--"
        batteryPercent = battery.chargePercent
        batterySourceText = source
        append(battery.chargePercent, to: &batteryHistory)
        batteryText = String(format: "Bateria %.0f%% (%@)", battery.chargePercent, source)
      } else {
        batteryText = "Bateria --"
        batteryPercent = nil
        batterySourceText = "--"
        batteryHistory.removeAll(keepingCapacity: true)
      }
    } else {
      batteryText = "Bateria desativada"
      batteryPercent = nil
      batterySourceText = "--"
      batteryHistory.removeAll(keepingCapacity: true)
    }

    if let top = snapshot.topProcesses {
      topCpuProcesses = top.topCpu.map { process in
        ProcessRow(
          id: process.pid,
          name: process.name,
          cpuPercent: process.cpuPercent,
          memoryBytes: process.memoryBytes,
          cpuText: String(format: "%.0f%%", process.cpuPercent),
          memoryText: formatBytes(process.memoryBytes)
        )
      }
      topMemoryProcesses = top.topMemory.map { process in
        ProcessRow(
          id: process.pid,
          name: process.name,
          cpuPercent: process.cpuPercent,
          memoryBytes: process.memoryBytes,
          cpuText: String(format: "%.0f%%", process.cpuPercent),
          memoryText: formatBytes(process.memoryBytes)
        )
      }

      var combined: [Int32: ProcessSnapshot] = [:]
      for process in top.topCpu + top.topMemory {
        combined[process.pid] = process
      }
      let sorted = combined.values.sorted { $0.cpuPercent > $1.cpuPercent }
      processOverview = sorted.prefix(12).map { process in
        ProcessRow(
          id: process.pid,
          name: process.name,
          cpuPercent: process.cpuPercent,
          memoryBytes: process.memoryBytes,
          cpuText: String(format: "%.0f%%", process.cpuPercent),
          memoryText: formatBytes(process.memoryBytes)
        )
      }
      updateProcessHistory(with: combined)
    } else {
      topCpuProcesses = []
      topMemoryProcesses = []
      processOverview = []
      processHistory = [:]
    }

    if let thermal = snapshot.thermal {
      hasThermalData = thermal.cpuTempC != nil || thermal.gpuTempC != nil
      hasFanData = !thermal.fanRPMs.isEmpty

      thermalText = hasThermalData ? formatTemperatures(cpu: thermal.cpuTempC, gpu: thermal.gpuTempC) : "Temperatura --"
      fansText = hasFanData ? formatFans(thermal.fanRPMs) : "Fans --"

      let stateLabel = thermal.thermalState?.label
      let unavailableMessage = "macOS nao expoe sensores neste modelo"
      if hasThermalData {
        thermalDetailText = thermalText
      } else if let stateLabel {
        thermalDetailText = "\(unavailableMessage) (estado: \(stateLabel))"
      } else {
        thermalDetailText = unavailableMessage
      }

      if hasFanData {
        fansDetailText = fansText
      } else if let stateLabel {
        fansDetailText = "\(unavailableMessage) (estado: \(stateLabel))"
      } else {
        fansDetailText = unavailableMessage
      }
      applyDiagnostics(thermal.diagnostics)
    } else {
      hasThermalData = false
      hasFanData = false
      thermalText = "Temperatura --"
      fansText = "Fans --"
      thermalDetailText = "macOS nao expoe sensores neste modelo"
      fansDetailText = "macOS nao expoe sensores neste modelo"
      applyDiagnostics(nil)
    }
  }

  public func requestPowermetricsFallback() {
    guard let powermetricsProvider else {
      powermetricsStatusText = "Powermetrics indisponivel."
      return
    }
    powermetricsStatusText = "Solicitando permissao..."
    powermetricsProvider.readOnce { [weak self] sample in
      guard let self else { return }
      if let value = sample.temperatureC {
        powermetricsTemperatureText = String(format: "%.0f C (powermetrics)", value)
      } else {
        powermetricsTemperatureText = "--"
      }
      if sample.fanRPMs.isEmpty {
        powermetricsFansText = "--"
      } else {
        let fanText = sample.fanRPMs.prefix(2).enumerated().map { index, value in
          String(format: "F%d %.0f RPM", index + 1, value)
        }
        powermetricsFansText = fanText.joined(separator: " | ")
      }
      powermetricsLastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: Date()))"
      powermetricsRawOutput = sample.rawOutput ?? ""

      let pressureLevel = extractThermalPressure(from: powermetricsRawOutput)
      if let pressureLevel {
        powermetricsPressureText = "Pressao \(pressureLevel)"
      } else {
        powermetricsPressureText = "--"
      }

      var status = sample.errorMessage ?? ""
      if status.isEmpty, sample.temperatureC == nil, sample.fanRPMs.isEmpty {
        if let pressureLevel {
          status = "Sem sensores. Apenas pressao termica: \(pressureLevel)."
        } else {
          status = "Powermetrics sem dados de sensores."
        }
      }
      powermetricsStatusText = status
    }
  }

  private func extractThermalPressure(from text: String) -> String? {
    let pattern = #"(?i)pressure level:\s*([A-Za-z]+)"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
    let range = NSRange(text.startIndex ..< text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 else {
      return nil
    }
    guard let valueRange = Range(match.range(at: 1), in: text) else { return nil }
    return String(text[valueRange]).capitalized
  }

  private func formatRate(_ bytesPerSec: Double) -> String {
    let kiloBytes = bytesPerSec / 1024.0
    let megaBytes = kiloBytes / 1024.0
    if megaBytes >= 1 {
      return String(format: "%.1f MB/s", megaBytes)
    }
    return String(format: "%.0f KB/s", kiloBytes)
  }

  private func formatBytes(_ bytes: UInt64) -> String {
    let gigaBytes = Double(bytes) / 1_073_741_824.0
    if gigaBytes >= 1 {
      return String(format: "%.1f GB", gigaBytes)
    }
    let megaBytes = Double(bytes) / 1_048_576.0
    if megaBytes >= 1 {
      return String(format: "%.0f MB", megaBytes)
    }
    let kiloBytes = Double(bytes) / 1024.0
    return String(format: "%.0f KB", kiloBytes)
  }

  private func formatTemperatures(cpu: Double?, gpu: Double?) -> String {
    let cpuText = cpu.map { String(format: "CPU %.0f C", $0) } ?? "CPU --"
    let gpuText = gpu.map { String(format: "GPU %.0f C", $0) } ?? "GPU --"
    return "Temp \(cpuText) | \(gpuText)"
  }

  private func formatFans(_ fans: [Double]) -> String {
    guard !fans.isEmpty else { return "Fans --" }
    let values = fans.prefix(2).enumerated().map { index, value in
      String(format: "F%d %.0f RPM", index + 1, value)
    }
    return values.joined(separator: " | ")
  }

  private func applyDiagnostics(_ diagnostics: ThermalDiagnostics?) {
    guard let diagnostics else {
      thermalDiagnosticsRows = []
      thermalDiagnosticsMessage = "Diagnostico indisponivel."
      return
    }

    var rows: [ThermalDiagnosticRow] = []
    rows.append(ThermalDiagnosticRow(title: "Servico SMC", value: diagnostics.serviceName ?? "--"))
    rows.append(ThermalDiagnosticRow(title: "Resultado", value: openResultText(diagnostics)))
    if let keyCount = diagnostics.keyCount {
      rows.append(ThermalDiagnosticRow(title: "Chaves SMC", value: "\(keyCount)"))
    } else {
      rows.append(ThermalDiagnosticRow(title: "Chaves SMC", value: "--"))
    }
    let tempKeys = diagnostics.temperatureKeys.joined(separator: ", ")
    let fanKeys = diagnostics.fanKeys.joined(separator: ", ")
    rows.append(ThermalDiagnosticRow(title: "Temp keys", value: tempKeys.isEmpty ? "--" : tempKeys))
    rows.append(ThermalDiagnosticRow(title: "Fan keys", value: fanKeys.isEmpty ? "--" : fanKeys))
    thermalDiagnosticsRows = rows
    thermalDiagnosticsMessage = diagnostics.message ?? ""
  }

  private func openResultText(_ diagnostics: ThermalDiagnostics) -> String {
    guard let openResult = diagnostics.openResult else { return "--" }
    let status = openResult == 0 ? "OK" : "Erro \(openResult)"
    if let openType = diagnostics.openType {
      return "\(status) (tipo \(openType))"
    }
    return status
  }

  private func append(_ value: Double, to series: inout [Double]) {
    series.append(value)
    if series.count > historyLimit {
      let overflow = series.count - historyLimit
      series.removeFirst(overflow)
    }
  }

  private func updateProcessHistory(with processes: [Int32: ProcessSnapshot]) {
    var updated = processHistory
    let visibleIds = Set(processes.keys)
    updated = updated.filter { visibleIds.contains($0.key) }

    for process in processes.values {
      var history = updated[process.pid] ?? ProcessHistory(
        name: process.name,
        cpuSeries: [],
        memorySeries: []
      )
      history.name = process.name
      history.cpuSeries.append(process.cpuPercent)
      history.memorySeries.append(Double(process.memoryBytes) / 1_048_576.0)
      if history.cpuSeries.count > processHistoryLimit {
        history.cpuSeries.removeFirst(history.cpuSeries.count - processHistoryLimit)
      }
      if history.memorySeries.count > processHistoryLimit {
        history.memorySeries.removeFirst(history.memorySeries.count - processHistoryLimit)
      }
      updated[process.pid] = history
    }
    processHistory = updated
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter
  }()
}

public struct ProcessRow: Identifiable, Equatable {
  public let id: Int32
  public let name: String
  public let cpuPercent: Double
  public let memoryBytes: UInt64
  public let cpuText: String
  public let memoryText: String

  public init(id: Int32, name: String, cpuPercent: Double, memoryBytes: UInt64, cpuText: String, memoryText: String) {
    self.id = id
    self.name = name
    self.cpuPercent = cpuPercent
    self.memoryBytes = memoryBytes
    self.cpuText = cpuText
    self.memoryText = memoryText
  }
}

public struct ThermalDiagnosticRow: Identifiable, Equatable {
  public let title: String
  public let value: String

  public var id: String {
    title
  }
}

public struct ProcessHistory: Equatable {
  public var name: String
  public var cpuSeries: [Double]
  public var memorySeries: [Double]

  public init(name: String, cpuSeries: [Double], memorySeries: [Double]) {
    self.name = name
    self.cpuSeries = cpuSeries
    self.memorySeries = memorySeries
  }
}
