import Foundation

public struct AlertEvent: Codable, Equatable, Identifiable {
  public let id: UUID
  public let ruleId: UUID
  public let timestamp: Date
  public let severity: AlertSeverity
  public let message: String
  public let metric: AlertMetric?

  public init(
    id: UUID = UUID(),
    ruleId: UUID,
    timestamp: Date,
    severity: AlertSeverity,
    message: String,
    metric: AlertMetric? = nil
  ) {
    self.id = id
    self.ruleId = ruleId
    self.timestamp = timestamp
    self.severity = severity
    self.message = message
    self.metric = metric
  }
}
