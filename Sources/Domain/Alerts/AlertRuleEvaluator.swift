import Foundation

public final class AlertRuleEvaluator {
  public init() {}

  public func evaluate(
    rule: AlertRule,
    snapshot: MetricSnapshot,
    now: Date,
    state: inout AlertRuleState
  ) -> AlertEvent? {
    guard rule.isEnabled else {
      state.conditionBeganAt = nil
      return nil
    }

    guard let value = rule.metric.value(from: snapshot) else {
      state.conditionBeganAt = nil
      return nil
    }

    let satisfied = rule.comparison.isSatisfied(value: value, threshold: rule.threshold)

    if satisfied {
      if state.conditionBeganAt == nil {
        state.conditionBeganAt = now
      }

      let sustained = now.timeIntervalSince(state.conditionBeganAt ?? now)
      let cooldownPassed: Bool = if let last = state.lastTriggeredAt {
        now.timeIntervalSince(last) >= rule.cooldown
      } else {
        true
      }

      if sustained >= rule.duration, cooldownPassed {
        state.lastTriggeredAt = now
        let message = "\(rule.name): \(rule.metric.formatValue(value))"
        return AlertEvent(ruleId: rule.id, timestamp: now, severity: rule.severity, message: message, metric: rule.metric)
      }
    } else {
      state.conditionBeganAt = nil
    }

    return nil
  }
}
