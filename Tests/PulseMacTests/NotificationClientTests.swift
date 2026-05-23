import PulseMacDomain
import XCTest

final class NotificationClientTests: XCTestCase {
  func testAlertEngineNotifies() {
    let rule = AlertRule(
      name: "CPU > 80%",
      metric: .cpuUsagePercent,
      comparison: .greaterThan,
      threshold: 80,
      duration: 0,
      cooldown: 0,
      severity: .warning,
      isEnabled: true
    )

    let ruleStore = InMemoryRuleStore(rules: [rule])
    let historyStore = InMemoryHistoryStore()
    let notificationClient = FakeNotificationClient()
    let engine = AlertEngine(ruleStore: ruleStore, historyStore: historyStore, notificationClient: notificationClient)

    let snapshot = MetricSnapshot(
      timestamp: Date(),
      cpu: CPUMetrics(usagePercent: 90),
      memory: MemoryMetrics(usedBytes: 0, totalBytes: 1)
    )

    engine.process(snapshot: snapshot)

    XCTAssertEqual(notificationClient.events.count, 1)
    XCTAssertEqual(historyStore.events.count, 1)
  }
}

private final class FakeNotificationClient: NotificationClient {
  var events: [AlertEvent] = []
  func notify(event: AlertEvent) {
    events.append(event)
  }
}

private final class InMemoryRuleStore: AlertRuleStore {
  private var rules: [AlertRule]
  init(rules: [AlertRule]) {
    self.rules = rules
  }

  func loadRules() -> [AlertRule] {
    rules
  }

  func saveRules(_ rules: [AlertRule]) {
    self.rules = rules
  }
}

private final class InMemoryHistoryStore: AlertHistoryStore {
  var events: [AlertEvent] = []
  func record(event: AlertEvent) {
    events.append(event)
  }

  func list(limit: Int) -> [AlertEvent] {
    Array(events.prefix(limit))
  }

  func clearAll() {
    events.removeAll()
  }
}
