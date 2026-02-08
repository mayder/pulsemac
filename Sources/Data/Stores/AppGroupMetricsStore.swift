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
