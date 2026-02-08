import Foundation

public protocol AlertRuleStore {
  func loadRules() -> [AlertRule]
  func saveRules(_ rules: [AlertRule])
}

public protocol AlertHistoryStore {
  func record(event: AlertEvent)
  func list(limit: Int) -> [AlertEvent]
}
