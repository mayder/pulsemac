import Combine
import Foundation
import PulseMacDomain

public final class MetricsSampler {
  public var publisher: AnyPublisher<MetricSnapshot, Never> {
    subject.eraseToAnyPublisher()
  }

  private let cpuProvider: CPUMetricsProviding
  private let memoryProvider: MemoryMetricsProviding
  private let diskProvider: DiskMetricsProviding?
  private let networkProvider: NetworkMetricsProviding?
  private let batteryProvider: BatteryMetricsProviding?
  private let topProcessesProvider: TopProcessesProviding?
  private let topProcessesLimit: Int
  private let thermalProvider: ThermalMetricsProviding?
  private let snapshotStore: MetricsSnapshotStore
  private let historyStore: MetricsHistoryStoring?
  private let subject: CurrentValueSubject<MetricSnapshot, Never>
  private let queue: DispatchQueue
  private var timer: DispatchSourceTimer?
  private var options = Options()
  private var sampleCounter = 0
  private var lastTopProcesses: TopProcessesSnapshot?
  private var lastThermal: ThermalMetrics?
  private let topProcessesEverySamples = 2
  private let thermalEverySamples = 3

  public init(
    cpuProvider: CPUMetricsProviding,
    memoryProvider: MemoryMetricsProviding,
    diskProvider: DiskMetricsProviding? = nil,
    networkProvider: NetworkMetricsProviding? = nil,
    batteryProvider: BatteryMetricsProviding? = nil,
    topProcessesProvider: TopProcessesProviding? = nil,
    topProcessesLimit: Int = 5,
    thermalProvider: ThermalMetricsProviding? = nil,
    snapshotStore: MetricsSnapshotStore,
    historyStore: MetricsHistoryStoring? = nil
  ) {
    self.cpuProvider = cpuProvider
    self.memoryProvider = memoryProvider
    self.diskProvider = diskProvider
    self.networkProvider = networkProvider
    self.batteryProvider = batteryProvider
    self.topProcessesProvider = topProcessesProvider
    self.topProcessesLimit = topProcessesLimit
    self.thermalProvider = thermalProvider
    self.snapshotStore = snapshotStore
    self.historyStore = historyStore
    let initial = MetricSnapshot(
      timestamp: Date(),
      cpu: CPUMetrics(usagePercent: 0),
      memory: MemoryMetrics(usedBytes: 0, totalBytes: ProcessInfo.processInfo.physicalMemory)
    )
    subject = CurrentValueSubject(initial)
    queue = DispatchQueue(label: "pulsemac.metrics.sampler", qos: .utility)
  }

  public func start(interval: SamplingInterval) {
    stop()

    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now(), repeating: interval.rawValue, leeway: leeway(for: interval))
    timer.setEventHandler { [weak self] in
      self?.sample()
    }
    timer.resume()
    self.timer = timer
  }

  public func stop() {
    timer?.cancel()
    timer = nil
  }

  public func updateOptions(showDisk: Bool, showNetwork: Bool, showBattery: Bool) {
    options = Options(showDisk: showDisk, showNetwork: showNetwork, showBattery: showBattery)
  }

  private func sample() {
    sampleCounter &+= 1
    let cpu = cpuProvider.read()
    let memory = memoryProvider.read()
    let disk = options.showDisk ? diskProvider?.read() : nil
    let network = options.showNetwork ? networkProvider?.read() : nil
    let battery = options.showBattery ? batteryProvider?.read() : nil
    let topProcesses = readTopProcesses()
    let thermal = readThermal()
    let snapshot = MetricSnapshot(
      timestamp: Date(),
      cpu: cpu,
      memory: memory,
      disk: disk,
      network: network,
      battery: battery,
      topProcesses: topProcesses,
      thermal: thermal
    )
    snapshotStore.save(snapshot)
    historyStore?.append(MetricHistoryEntry(snapshot: snapshot))
    subject.send(snapshot)
  }

  private func readTopProcesses() -> TopProcessesSnapshot? {
    guard let provider = topProcessesProvider else { return nil }
    if sampleCounter % topProcessesEverySamples == 0 || lastTopProcesses == nil {
      lastTopProcesses = provider.read(limit: topProcessesLimit)
    }
    return lastTopProcesses
  }

  private func readThermal() -> ThermalMetrics? {
    guard let provider = thermalProvider else { return nil }
    if sampleCounter % thermalEverySamples == 0 || lastThermal == nil {
      lastThermal = provider.read()
    }
    return lastThermal
  }

  private func leeway(for interval: SamplingInterval) -> DispatchTimeInterval {
    let baseMs = Int(interval.rawValue * 200)
    let clamped = min(500, max(100, baseMs))
    return .milliseconds(clamped)
  }
}

private struct Options {
  let showDisk: Bool
  let showNetwork: Bool
  let showBattery: Bool

  init(showDisk: Bool = true, showNetwork: Bool = true, showBattery: Bool = true) {
    self.showDisk = showDisk
    self.showNetwork = showNetwork
    self.showBattery = showBattery
  }
}
