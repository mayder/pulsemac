import Foundation

public struct AlertRuleState: Equatable, Codable {
  public var conditionBeganAt: Date?
  public var lastTriggeredAt: Date?

  public init(conditionBeganAt: Date? = nil, lastTriggeredAt: Date? = nil) {
    self.conditionBeganAt = conditionBeganAt
    self.lastTriggeredAt = lastTriggeredAt
  }
}
