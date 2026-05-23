import Foundation
import PulseMacDomain

public final class AppGroupMetricsStore: MetricsSnapshotStore {
  private let defaults: UserDefaults
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let key = "pulsemac.metrics.snapshot"

  public init(suiteName: String) {
    defaults = UserDefaults(suiteName: suiteName) ?? .standard
    encoder = JSONEncoder()
    decoder = JSONDecoder()
  }

  public func save(_ snapshot: MetricSnapshot) {
    guard let data = try? encoder.encode(snapshot) else { return }
    defaults.set(data, forKey: key)
  }

  public func load() -> MetricSnapshot? {
    guard let data = defaults.data(forKey: key) else { return nil }
    return try? decoder.decode(MetricSnapshot.self, from: data)
  }
}

public final class AppGroupMetricsHistoryStore: MetricsHistoryStoring {
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let queue = DispatchQueue(label: "pulsemac.metrics.history", qos: .utility)
  private let fileURL: URL
  private let minSampleInterval: TimeInterval
  private var retentionDays: Int
  private var entries: [MetricHistoryEntry] = []

  public init(
    suiteName: String,
    retentionDays: Int,
    minSampleInterval: TimeInterval = 10
  ) {
    self.retentionDays = max(1, retentionDays)
    self.minSampleInterval = minSampleInterval
    let fileName = "metrics-history.json"
    if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) {
      fileURL = container.appendingPathComponent(fileName)
    } else {
      let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      let folder = base?.appendingPathComponent("PulseMac", isDirectory: true)
      if let folder {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent(fileName)
      } else {
        fileURL = URL(fileURLWithPath: fileName)
      }
    }
    loadFromDisk()
  }

  public func append(_ entry: MetricHistoryEntry) {
    queue.async { [weak self] in
      guard let self else { return }
      if let last = entries.last, entry.timestamp.timeIntervalSince(last.timestamp) < minSampleInterval {
        return
      }
      entries.append(entry)
      pruneOldEntries()
      persist()
    }
  }

  public func fetch(since: Date) -> [MetricHistoryEntry] {
    queue.sync {
      entries.filter { $0.timestamp >= since }
    }
  }

  public func updateRetentionDays(_ days: Int) {
    queue.async { [weak self] in
      guard let self else { return }
      retentionDays = max(1, days)
      pruneOldEntries()
      persist()
    }
  }

  private func loadFromDisk() {
    queue.sync {
      guard let data = try? Data(contentsOf: fileURL),
            let decoded = try? decoder.decode([MetricHistoryEntry].self, from: data)
      else {
        entries = []
        return
      }
      entries = decoded.sorted { $0.timestamp < $1.timestamp }
      pruneOldEntries()
    }
  }

  private func pruneOldEntries() {
    let cutoff = Date().addingTimeInterval(-TimeInterval(retentionDays * 24 * 3600))
    if let index = entries.firstIndex(where: { $0.timestamp >= cutoff }) {
      entries = Array(entries[index...])
    } else {
      entries.removeAll(keepingCapacity: true)
    }
  }

  private func persist() {
    guard let data = try? encoder.encode(entries) else { return }
    try? data.write(to: fileURL, options: .atomic)
  }
}
