import Foundation
import PulseMacDomain

public final class AlertRuleDefaultsStore: AlertRuleStore {
  private let defaults: UserDefaults
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let key = "pulsemac.alert.rules"

  public init(suiteName: String) {
    defaults = UserDefaults(suiteName: suiteName) ?? .standard
    encoder = JSONEncoder()
    decoder = JSONDecoder()
  }

  public func loadRules() -> [AlertRule] {
    guard let data = defaults.data(forKey: key) else { return [] }
    return (try? decoder.decode([AlertRule].self, from: data)) ?? []
  }

  public func saveRules(_ rules: [AlertRule]) {
    guard let data = try? encoder.encode(rules) else { return }
    defaults.set(data, forKey: key)
  }
}
