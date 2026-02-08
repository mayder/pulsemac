import Foundation

public final class AlertEngine {
  private let ruleStore: AlertRuleStore
  private let historyStore: AlertHistoryStore
  private let notificationClient: NotificationClient
  private let clock: Clock
  private let evaluator: AlertRuleEvaluator
  private var states: [UUID: AlertRuleState]

  public init(
    ruleStore: AlertRuleStore,
    historyStore: AlertHistoryStore,
    notificationClient: NotificationClient,
    clock: Clock = SystemClock(),
    evaluator: AlertRuleEvaluator = AlertRuleEvaluator()
  ) {
    self.ruleStore = ruleStore
    self.historyStore = historyStore
    self.notificationClient = notificationClient
    self.clock = clock
    self.evaluator = evaluator
    states = [:]
  }

  public func process(snapshot: MetricSnapshot) {
    let now = clock.now
    var updatedStates: [UUID: AlertRuleState] = states

    for rule in ruleStore.loadRules() {
      var state = updatedStates[rule.id] ?? AlertRuleState()
      if let event = evaluator.evaluate(rule: rule, snapshot: snapshot, now: now, state: &state) {
        historyStore.record(event: event)
        notificationClient.notify(event: event)
      }
      updatedStates[rule.id] = state
    }

    states = updatedStates
  }
}
