import Combine
import Foundation
import PulseMacDomain

public final class AlertsViewModel: ObservableObject {
  @Published public private(set) var rules: [AlertRule] = []
  @Published public private(set) var history: [AlertEvent] = []

  private let ruleStore: AlertRuleStore
  private let historyStore: AlertHistoryStore
  private let onTestAlert: (AlertEvent) -> Void
  private let onRequestNotificationPermission: (@escaping (Bool) -> Void) -> Void

  public init(
    ruleStore: AlertRuleStore,
    historyStore: AlertHistoryStore,
    onTestAlert: @escaping (AlertEvent) -> Void = { _ in },
    onRequestNotificationPermission: @escaping (@escaping (Bool) -> Void) -> Void = { _ in }
  ) {
    self.ruleStore = ruleStore
    self.historyStore = historyStore
    self.onTestAlert = onTestAlert
    self.onRequestNotificationPermission = onRequestNotificationPermission
    reload()
  }

  public func reload() {
    rules = ruleStore.loadRules()
    history = historyStore.list(limit: 200)
  }

  public func addCPUAlert(threshold: Double, duration: TimeInterval) {
    let draft = AlertDraft(
      metric: .cpuUsagePercent,
      comparison: .greaterThan,
      threshold: threshold,
      duration: duration,
      cooldown: 60,
      severity: .warning
    )
    _ = addAlert(draft: draft)
  }

  public func addPresetAlerts() {
    var updated = ruleStore.loadRules()
    let presets = Self.defaultPresets

    for preset in presets {
      if updated.contains(where: { $0.matchesPreset(preset) }) {
        continue
      }
      let rule = AlertRule(
        name: preset.metric.formatRuleName(comparison: preset.comparison, threshold: preset.threshold),
        metric: preset.metric,
        comparison: preset.comparison,
        threshold: preset.threshold,
        duration: preset.duration,
        cooldown: preset.cooldown,
        severity: preset.severity,
        isEnabled: true
      )
      updated.append(rule)
    }

    ruleStore.saveRules(updated)
    reload()
  }

  @discardableResult
  public func addAlert(draft: AlertDraft) -> AlertRule {
    var updated = ruleStore.loadRules()
    let rule = AlertRule(
      name: draft.metric.formatRuleName(comparison: draft.comparison, threshold: draft.threshold),
      metric: draft.metric,
      comparison: draft.comparison,
      threshold: draft.threshold,
      duration: draft.duration,
      cooldown: draft.cooldown,
      severity: draft.severity,
      isEnabled: true
    )
    updated.append(rule)
    ruleStore.saveRules(updated)
    reload()
    return rule
  }

  public func toggle(rule: AlertRule) {
    var updated = ruleStore.loadRules()
    if let index = updated.firstIndex(where: { $0.id == rule.id }) {
      updated[index].isEnabled.toggle()
    }
    ruleStore.saveRules(updated)
    reload()
  }

  public func updateAlert(ruleId: UUID, draft: AlertDraft) {
    var updated = ruleStore.loadRules()
    guard let index = updated.firstIndex(where: { $0.id == ruleId }) else { return }
    let isEnabled = updated[index].isEnabled
    updated[index] = AlertRule(
      id: ruleId,
      name: draft.metric.formatRuleName(comparison: draft.comparison, threshold: draft.threshold),
      metric: draft.metric,
      comparison: draft.comparison,
      threshold: draft.threshold,
      duration: draft.duration,
      cooldown: draft.cooldown,
      severity: draft.severity,
      isEnabled: isEnabled
    )
    ruleStore.saveRules(updated)
    reload()
  }

  @discardableResult
  public func duplicateAlert(ruleId: UUID) -> AlertRule? {
    var updated = ruleStore.loadRules()
    guard let rule = updated.first(where: { $0.id == ruleId }) else { return nil }
    let copy = AlertRule(
      name: rule.metric.formatRuleName(comparison: rule.comparison, threshold: rule.threshold),
      metric: rule.metric,
      comparison: rule.comparison,
      threshold: rule.threshold,
      duration: rule.duration,
      cooldown: rule.cooldown,
      severity: rule.severity,
      isEnabled: rule.isEnabled
    )
    updated.append(copy)
    ruleStore.saveRules(updated)
    reload()
    return copy
  }

  public func deleteAlert(ruleId: UUID) {
    let updated = ruleStore.loadRules().filter { $0.id != ruleId }
    ruleStore.saveRules(updated)
    reload()
  }

  public func testAlert(draft: AlertDraft, ruleId: UUID?) {
    onRequestNotificationPermission { [weak self] granted in
      guard granted else { return }
      let message = "Teste: \(draft.metric.formatRuleName(comparison: draft.comparison, threshold: draft.threshold))"
      let event = AlertEvent(ruleId: ruleId ?? UUID(), timestamp: Date(), severity: draft.severity, message: message)
      self?.onTestAlert(event)
    }
  }
}

private extension AlertsViewModel {
  static let defaultPresets: [AlertPreset] = [
    AlertPreset(metric: .cpuUsagePercent, comparison: .greaterThan, threshold: 80, duration: 20, cooldown: 120, severity: .warning),
    AlertPreset(metric: .cpuUsagePercent, comparison: .greaterThan, threshold: 95, duration: 15, cooldown: 300, severity: .critical),
    AlertPreset(metric: .memoryUsedPercent, comparison: .greaterThan, threshold: 85, duration: 30, cooldown: 120, severity: .warning),
    AlertPreset(metric: .diskFreePercent, comparison: .lessThan, threshold: 15, duration: 60, cooldown: 3600, severity: .warning),
    AlertPreset(metric: .diskFreePercent, comparison: .lessThan, threshold: 8, duration: 60, cooldown: 3600, severity: .critical),
    AlertPreset(metric: .networkDownloadKBps, comparison: .greaterThan, threshold: 5000, duration: 20, cooldown: 120, severity: .warning),
    AlertPreset(metric: .networkUploadKBps, comparison: .greaterThan, threshold: 2000, duration: 20, cooldown: 120, severity: .warning),
    AlertPreset(metric: .batteryChargePercent, comparison: .lessThan, threshold: 20, duration: 60, cooldown: 1800, severity: .warning),
    AlertPreset(metric: .batteryChargePercent, comparison: .lessThan, threshold: 10, duration: 60, cooldown: 1800, severity: .critical),
    AlertPreset(metric: .cpuTempC, comparison: .greaterThan, threshold: 90, duration: 20, cooldown: 120, severity: .warning),
    AlertPreset(metric: .gpuTempC, comparison: .greaterThan, threshold: 90, duration: 20, cooldown: 120, severity: .warning),
    AlertPreset(metric: .fanMaxRPM, comparison: .lessThan, threshold: 800, duration: 30, cooldown: 120, severity: .warning)
  ]
}

private struct AlertPreset: Equatable {
  let metric: AlertMetric
  let comparison: AlertComparison
  let threshold: Double
  let duration: TimeInterval
  let cooldown: TimeInterval
  let severity: AlertSeverity
}

private extension AlertRule {
  func matchesPreset(_ preset: AlertPreset) -> Bool {
    metric == preset.metric &&
      comparison == preset.comparison &&
      threshold == preset.threshold &&
      duration == preset.duration &&
      cooldown == preset.cooldown &&
      severity == preset.severity
  }
}

public struct AlertDraft {
  public var metric: AlertMetric
  public var comparison: AlertComparison
  public var threshold: Double
  public var duration: TimeInterval
  public var cooldown: TimeInterval
  public var severity: AlertSeverity

  public init(
    metric: AlertMetric,
    comparison: AlertComparison,
    threshold: Double,
    duration: TimeInterval,
    cooldown: TimeInterval,
    severity: AlertSeverity
  ) {
    self.metric = metric
    self.comparison = comparison
    self.threshold = threshold
    self.duration = duration
    self.cooldown = cooldown
    self.severity = severity
  }
}
