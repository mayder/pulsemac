import PulseMacDomain
import XCTest

final class AlertRuleEvaluatorTests: XCTestCase {
  func testSustainedThresholdAndCooldown() {
    let evaluator = AlertRuleEvaluator()
    let rule = AlertRule(
      name: "CPU > 80%",
      metric: .cpuUsagePercent,
      comparison: .greaterThan,
      threshold: 80,
      duration: 20,
      cooldown: 30,
      severity: .warning,
      isEnabled: true
    )

    var state = AlertRuleState()
    let base = Date()

    let snapshotLow = MetricSnapshot(
      timestamp: base,
      cpu: CPUMetrics(usagePercent: 50),
      memory: MemoryMetrics(usedBytes: 0, totalBytes: 1)
    )
    XCTAssertNil(evaluator.evaluate(rule: rule, snapshot: snapshotLow, now: base, state: &state))

    let snapshotHigh = MetricSnapshot(
      timestamp: base,
      cpu: CPUMetrics(usagePercent: 90),
      memory: MemoryMetrics(usedBytes: 0, totalBytes: 1)
    )

    XCTAssertNil(evaluator.evaluate(rule: rule, snapshot: snapshotHigh, now: base, state: &state))
    XCTAssertNil(evaluator.evaluate(rule: rule, snapshot: snapshotHigh, now: base.addingTimeInterval(10), state: &state))

    let event = evaluator.evaluate(rule: rule, snapshot: snapshotHigh, now: base.addingTimeInterval(20), state: &state)
    XCTAssertNotNil(event)

    let cooldownEvent = evaluator.evaluate(rule: rule, snapshot: snapshotHigh, now: base.addingTimeInterval(30), state: &state)
    XCTAssertNil(cooldownEvent)

    let afterCooldown = evaluator.evaluate(rule: rule, snapshot: snapshotHigh, now: base.addingTimeInterval(60), state: &state)
    XCTAssertNotNil(afterCooldown)
  }
}
