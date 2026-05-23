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
  @Published public private(set) var cpuPerCoreUsage: [Double] = []
  @Published public private(set) var cpuLogicalCores: Int = ProcessInfo.processInfo.processorCount
  @Published public private(set) var cpuActiveCores: Int = ProcessInfo.processInfo.activeProcessorCount
  @Published public private(set) var cpuLoadAverage1: Double?
  @Published public private(set) var cpuLoadAverage5: Double?
  @Published public private(set) var cpuLoadAverage15: Double?
  @Published public private(set) var memoryPercent: Double = 0
  @Published public private(set) var diskFreePercent: Double?
  @Published public private(set) var diskReadBytesPerSec: Double?
  @Published public private(set) var diskWriteBytesPerSec: Double?
  @Published public private(set) var diskActivityUpdatedText: String = ""
  @Published public private(set) var diskActivityStatusText: String = ""
  @Published public private(set) var topDiskProcesses: [ProcessDiskRow] = []
  @Published public private(set) var batteryPercent: Double?
  @Published public private(set) var memoryUsedGB: Double?
  @Published public private(set) var memoryFreeGB: Double?
  @Published public private(set) var memoryTotalGB: Double?
  @Published public private(set) var diskFreeGB: Double?
  @Published public private(set) var diskUsedGB: Double?
  @Published public private(set) var diskTotalGB: Double?
  @Published public private(set) var batterySourceText: String = "--"
  @Published public private(set) var batteryStatusText: String = "--"
  @Published public private(set) var batteryHealthText: String = "--"
  @Published public private(set) var batteryCycleCount: Int?
  @Published public private(set) var batteryTimeRemainingText: String = "--"
  @Published public private(set) var batteryCurrentCapacity: Double?
  @Published public private(set) var batteryMaxCapacity: Double?
  @Published public private(set) var batteryDesignCapacity: Double?
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
  @Published public private(set) var thermalStateText: String = "--"
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
  @Published public var selectedHistoryMetric: MetricsHistoryMetric = .cpu
  @Published public var selectedHistoryRange: MetricsHistoryRange = .oneHour
  @Published public private(set) var historyValues: [Double] = []
  @Published public private(set) var historyStatusText: String = ""
  @Published public private(set) var comparisonRows: [MetricsComparisonRow] = []
  @Published public private(set) var comparisonStatusText: String = ""

  private var showDisk = true
  private var showNetwork = true
  private var showBattery = true
  private var cancellables: Set<AnyCancellable> = []
  private let historyLimit = 60
  private let processHistoryLimit = 60
  private let powermetricsProvider: ThermalFallbackProviding?
  private let historyStore: MetricsHistoryStoring?
  private let processResourcesProvider: ProcessResourcesProviding?
  private var historyDidLoad = false
  private var comparisonDidLoad = false
  private var diskActivityDidLoad = false

  public init(
    powermetricsProvider: ThermalFallbackProviding? = nil,
    historyStore: MetricsHistoryStoring? = nil,
    processResourcesProvider: ProcessResourcesProviding? = nil
  ) {
    self.powermetricsProvider = powermetricsProvider
    self.historyStore = historyStore
    self.processResourcesProvider = processResourcesProvider
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

  public func refreshHistoryIfNeeded() {
    guard !historyDidLoad else { return }
    refreshHistory()
  }

  public func refreshHistory() {
    guard let historyStore else {
      historyStatusText = "Historico indisponivel."
      historyValues = []
      return
    }
    historyStatusText = "Carregando historico..."
    let metric = selectedHistoryMetric
    let range = selectedHistoryRange
    DispatchQueue.global(qos: .utility).async { [weak self] in
      guard let self else { return }
      let since = Date().addingTimeInterval(-range.seconds)
      let entries = historyStore.fetch(since: since)
      let values = entries.compactMap { metric.value(from: $0) }
      DispatchQueue.main.async {
        self.historyValues = values
        self.historyStatusText = values.isEmpty ? "Sem dados no periodo selecionado." : ""
        self.historyDidLoad = true
      }
    }
  }

  public func refreshComparisonIfNeeded() {
    guard !comparisonDidLoad else { return }
    refreshComparison()
  }

  public func refreshDiskActivityIfNeeded() {
    guard !diskActivityDidLoad else { return }
    refreshDiskActivity()
  }

  public func refreshDiskActivity() {
    guard let processResourcesProvider else {
      diskActivityStatusText = "Atividade de disco indisponivel."
      diskReadBytesPerSec = nil
      diskWriteBytesPerSec = nil
      topDiskProcesses = []
      diskActivityUpdatedText = ""
      return
    }

    diskActivityStatusText = "Coletando atividade..."
    DispatchQueue.global(qos: .utility).async { [weak self] in
      guard let self else { return }
      let rows = processResourcesProvider.readResources(limit: 50)
      let active = rows.filter { $0.diskReadBytesPerSec > 0 || $0.diskWriteBytesPerSec > 0 }
      let totalRead = active.reduce(0) { $0 + $1.diskReadBytesPerSec }
      let totalWrite = active.reduce(0) { $0 + $1.diskWriteBytesPerSec }
      let sorted = active.sorted {
        ($0.diskReadBytesPerSec + $0.diskWriteBytesPerSec) >
          ($1.diskReadBytesPerSec + $1.diskWriteBytesPerSec)
      }
      let top = sorted.prefix(6).map { process in
        ProcessDiskRow(
          id: process.pid,
          name: process.appName ?? process.name,
          readBytesPerSec: process.diskReadBytesPerSec,
          writeBytesPerSec: process.diskWriteBytesPerSec
        )
      }
      let updatedText = "Atualizado: \(Self.timeFormatter.string(from: Date()))"

      DispatchQueue.main.async {
        self.diskReadBytesPerSec = totalRead
        self.diskWriteBytesPerSec = totalWrite
        self.topDiskProcesses = top
        self.diskActivityUpdatedText = updatedText
        self.diskActivityStatusText = active.isEmpty ? "Sem atividade de disco no momento." : ""
        self.diskActivityDidLoad = true
      }
    }
  }

  public func refreshComparison() {
    guard let historyStore else {
      comparisonStatusText = "Comparacao indisponivel."
      comparisonRows = []
      return
    }
    comparisonStatusText = "Carregando comparacao..."
    DispatchQueue.global(qos: .utility).async { [weak self] in
      guard let self else { return }
      let calendar = Calendar.current
      let startToday = calendar.startOfDay(for: Date())
      guard let startYesterday = calendar.date(byAdding: .day, value: -1, to: startToday) else {
        DispatchQueue.main.async {
          self.comparisonRows = []
          self.comparisonStatusText = "Comparacao indisponivel."
          self.comparisonDidLoad = true
        }
        return
      }

      let entries = historyStore.fetch(since: startYesterday)
      let today = entries.filter { $0.timestamp >= startToday }
      let yesterday = entries.filter { $0.timestamp < startToday }

      let rows = [
        buildComparisonRow(
          title: "CPU",
          todayValues: today.map(\.cpuPercent),
          yesterdayValues: yesterday.map(\.cpuPercent),
          formatter: Self.formatPercent
        ),
        buildComparisonRow(
          title: "Memoria",
          todayValues: today.map(\.memoryUsedPercent),
          yesterdayValues: yesterday.map(\.memoryUsedPercent),
          formatter: Self.formatPercent
        ),
        buildComparisonRow(
          title: "Disco livre",
          todayValues: today.map(\.diskFreePercent),
          yesterdayValues: yesterday.map(\.diskFreePercent),
          formatter: Self.formatPercent
        ),
        buildComparisonRow(
          title: "Rede (total)",
          todayValues: today.map(Self.networkTotal(from:)),
          yesterdayValues: yesterday.map(Self.networkTotal(from:)),
          formatter: Self.formatRate
        )
      ]

      DispatchQueue.main.async {
        self.comparisonRows = rows
        self.comparisonStatusText = rows.allSatisfy(\.isEmpty) ? "Sem dados suficientes para comparar." : ""
        self.comparisonDidLoad = true
      }
    }
  }

  public var historyRange: ClosedRange<Double> {
    switch selectedHistoryMetric {
    case .cpu, .memory, .diskFree, .battery:
      return 0 ... 100
    case .networkDown, .networkUp:
      let maxValue = max(historyValues.max() ?? 1, 1)
      return 0 ... maxValue
    }
  }

  public var historyUnitLabel: String {
    switch selectedHistoryMetric {
    case .cpu, .memory, .diskFree, .battery:
      "%"
    case .networkDown, .networkUp:
      "KB/s"
    }
  }

  private func buildComparisonRow(
    title: String,
    todayValues: [Double?],
    yesterdayValues: [Double?],
    formatter: (Double?) -> String
  ) -> MetricsComparisonRow {
    let todayAvg = Self.average(todayValues)
    let yesterdayAvg = Self.average(yesterdayValues)
    let deltaText = Self.formatDelta(today: todayAvg, yesterday: yesterdayAvg)
    return MetricsComparisonRow(
      id: title,
      title: title,
      todayText: formatter(todayAvg),
      yesterdayText: formatter(yesterdayAvg),
      deltaText: deltaText
    )
  }

  private static func average(_ values: [Double?]) -> Double? {
    let cleaned = values.compactMap { $0 }
    guard !cleaned.isEmpty else { return nil }
    let sum = cleaned.reduce(0, +)
    return sum / Double(cleaned.count)
  }

  private static func formatPercent(_ value: Double?) -> String {
    guard let value else { return "--" }
    return String(format: "%.1f%%", value)
  }

  private static func formatRate(_ value: Double?) -> String {
    guard let value else { return "--" }
    if value < 1 {
      return String(format: "%.1f KB/s", value)
    }
    return String(format: "%.0f KB/s", value)
  }

  private static func formatDelta(today: Double?, yesterday: Double?) -> String {
    guard let today, let yesterday, yesterday > 0 else { return "--" }
    let delta = (today - yesterday) / yesterday * 100
    let sign = delta >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.1f%%", delta))"
  }

  private static func networkTotal(from entry: MetricHistoryEntry) -> Double? {
    guard entry.networkDownloadKBps != nil || entry.networkUploadKBps != nil else { return nil }
    return (entry.networkDownloadKBps ?? 0) + (entry.networkUploadKBps ?? 0)
  }

  private func apply(snapshot: MetricSnapshot) {
    cpuPercent = snapshot.cpu.usagePercent
    cpuPerCoreUsage = snapshot.cpu.perCoreUsagePercent ?? []
    updateCpuLoadAverage()
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
        batteryHealthText = battery.health ?? "--"
        batteryCycleCount = battery.cycleCount
        batteryCurrentCapacity = battery.currentCapacity
        batteryMaxCapacity = battery.maxCapacity
        batteryDesignCapacity = battery.designCapacity
        batteryStatusText = statusText(for: battery, source: source)
        batteryTimeRemainingText = timeRemainingText(for: battery)
        append(battery.chargePercent, to: &batteryHistory)
        batteryText = String(format: "Bateria %.0f%% (%@)", battery.chargePercent, source)
      } else {
        batteryText = "Bateria --"
        batteryPercent = nil
        batterySourceText = "--"
        batteryHealthText = "--"
        batteryCycleCount = nil
        batteryCurrentCapacity = nil
        batteryMaxCapacity = nil
        batteryDesignCapacity = nil
        batteryStatusText = "--"
        batteryTimeRemainingText = "--"
        batteryHistory.removeAll(keepingCapacity: true)
      }
    } else {
      batteryText = "Bateria desativada"
      batteryPercent = nil
      batterySourceText = "--"
      batteryHealthText = "--"
      batteryCycleCount = nil
      batteryCurrentCapacity = nil
      batteryMaxCapacity = nil
      batteryDesignCapacity = nil
      batteryStatusText = "--"
      batteryTimeRemainingText = "--"
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

      let stateLabel = thermal.thermalState?.label ?? "Desconhecido"
      thermalStateText = stateLabel
      let unavailableMessage = "macOS nao expoe sensores neste modelo"
      if hasThermalData {
        thermalDetailText = thermalText
      } else {
        thermalDetailText = "\(unavailableMessage) (estado: \(stateLabel))"
      }

      if hasFanData {
        fansDetailText = fansText
      } else {
        fansDetailText = "\(unavailableMessage) (estado: \(stateLabel))"
      }
      applyDiagnostics(thermal.diagnostics)
    } else {
      hasThermalData = false
      hasFanData = false
      thermalText = "Temperatura --"
      fansText = "Fans --"
      thermalDetailText = "macOS nao expoe sensores neste modelo"
      fansDetailText = "macOS nao expoe sensores neste modelo"
      thermalStateText = "Desconhecido"
      applyDiagnostics(nil)
    }
  }

  private func updateCpuLoadAverage() {
    var values = [Double](repeating: 0, count: 3)
    let result = getloadavg(&values, 3)
    if result == 3 {
      cpuLoadAverage1 = values[0]
      cpuLoadAverage5 = values[1]
      cpuLoadAverage15 = values[2]
    } else {
      cpuLoadAverage1 = nil
      cpuLoadAverage5 = nil
      cpuLoadAverage15 = nil
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

  private func statusText(for battery: BatteryMetrics, source: String) -> String {
    if battery.isCharged == true {
      return "Cheia"
    }
    if battery.isCharging {
      return "Carregando"
    }
    if battery.powerSource == .battery {
      return "Em bateria"
    }
    if battery.powerSource == .acPower {
      return "Em AC"
    }
    return source
  }

  private func timeRemainingText(for battery: BatteryMetrics) -> String {
    if battery.isCharging, let minutes = battery.timeToFullMinutes {
      return "Completar em \(formatMinutes(minutes))"
    }
    if battery.powerSource == .battery, let minutes = battery.timeToEmptyMinutes {
      return "Restante \(formatMinutes(minutes))"
    }
    return "--"
  }

  private func formatMinutes(_ minutes: Int) -> String {
    if minutes <= 0 { return "--" }
    let hours = minutes / 60
    let remaining = minutes % 60
    if hours > 0 {
      return "\(hours)h \(remaining)m"
    }
    return "\(remaining)m"
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

public struct ProcessDiskRow: Identifiable, Equatable {
  public let id: Int32
  public let name: String
  public let readBytesPerSec: Double
  public let writeBytesPerSec: Double

  public init(id: Int32, name: String, readBytesPerSec: Double, writeBytesPerSec: Double) {
    self.id = id
    self.name = name
    self.readBytesPerSec = readBytesPerSec
    self.writeBytesPerSec = writeBytesPerSec
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

public struct MetricsComparisonRow: Identifiable, Equatable {
  public let id: String
  public let title: String
  public let todayText: String
  public let yesterdayText: String
  public let deltaText: String

  public var isEmpty: Bool {
    todayText == "--" && yesterdayText == "--"
  }
}

public enum MetricsHistoryMetric: String, CaseIterable, Identifiable {
  case cpu
  case memory
  case diskFree
  case networkDown
  case networkUp
  case battery

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .cpu:
      "CPU"
    case .memory:
      "Memoria"
    case .diskFree:
      "Disco livre"
    case .networkDown:
      "Rede download"
    case .networkUp:
      "Rede upload"
    case .battery:
      "Bateria"
    }
  }

  public func value(from entry: MetricHistoryEntry) -> Double? {
    switch self {
    case .cpu:
      entry.cpuPercent
    case .memory:
      entry.memoryUsedPercent
    case .diskFree:
      entry.diskFreePercent
    case .networkDown:
      entry.networkDownloadKBps
    case .networkUp:
      entry.networkUploadKBps
    case .battery:
      entry.batteryPercent
    }
  }
}

public enum MetricsHistoryRange: Int, CaseIterable, Identifiable {
  case oneHour = 1
  case oneDay = 24
  case sevenDays = 168

  public var id: Int {
    rawValue
  }

  public var label: String {
    switch self {
    case .oneHour:
      "1h"
    case .oneDay:
      "24h"
    case .sevenDays:
      "7d"
    }
  }

  public var seconds: TimeInterval {
    TimeInterval(rawValue * 3600)
  }
}
