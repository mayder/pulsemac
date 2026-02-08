import Foundation
import PulseMacDomain

public final class NotificationGate: NotificationClient {
  private let client: UserNotificationClient
  private let muteStore: AlertMuteStore
  public var isEnabled: Bool
  public private(set) var dndEnabled: Bool
  public private(set) var dndStartMinutes: Int
  public private(set) var dndEndMinutes: Int

  public init(
    client: UserNotificationClient,
    muteStore: AlertMuteStore,
    isEnabled: Bool,
    dndEnabled: Bool,
    dndStartMinutes: Int,
    dndEndMinutes: Int
  ) {
    self.client = client
    self.muteStore = muteStore
    self.isEnabled = isEnabled
    self.dndEnabled = dndEnabled
    self.dndStartMinutes = dndStartMinutes
    self.dndEndMinutes = dndEndMinutes
  }

  public func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void = { _ in }) {
    client.requestAuthorizationIfNeeded(completion: completion)
  }

  public func fetchAuthorizationStatusLabel(completion: @escaping (String) -> Void) {
    client.fetchAuthorizationStatusLabel(completion: completion)
  }

  public func fetchEntitlementStatusLabel() -> String {
    client.fetchEntitlementStatusLabel()
  }

  public func configureCategories() {
    client.configureCategories()
  }

  public func updateSchedule(enabled: Bool, startMinutes: Int, endMinutes: Int) {
    dndEnabled = enabled
    dndStartMinutes = startMinutes
    dndEndMinutes = endMinutes
  }

  public func notify(event: AlertEvent) {
    guard isEnabled else { return }
    if dndEnabled, isWithinDoNotDisturb(Date()) { return }
    if muteStore.isMuted(ruleId: event.ruleId) { return }
    client.notify(event: event)
  }

  private func isWithinDoNotDisturb(_ date: Date) -> Bool {
    if dndStartMinutes == dndEndMinutes { return false }
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
    if dndStartMinutes < dndEndMinutes {
      return minutes >= dndStartMinutes && minutes < dndEndMinutes
    }
    return minutes >= dndStartMinutes || minutes < dndEndMinutes
  }
}
