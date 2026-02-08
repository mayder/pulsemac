import Foundation
import PulseMacDomain
import Security
import UserNotifications

public final class UserNotificationClient: NSObject, NotificationClient {
  private let center: UNUserNotificationCenter

  override public init() {
    center = UNUserNotificationCenter.current()
    super.init()
  }

  public func configureCategories() {
    let actions = [
      UNNotificationAction(identifier: "snooze_10m", title: "Soneca 10m", options: []),
      UNNotificationAction(identifier: "mute_1h", title: "Silenciar 1h", options: []),
      UNNotificationAction(identifier: "open_app", title: "Abrir App", options: [.foreground])
    ]
    let category = UNNotificationCategory(identifier: "pulsemac.alert", actions: actions, intentIdentifiers: [], options: [])
    center.setNotificationCategories([category])
  }

  public func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void = { _ in }) {
    DispatchQueue.main.async { [weak self] in
      self?.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error {
          let message = "PulseMac notificacao: falha ao solicitar permissao: \(error.localizedDescription)"
          print(message)
          DiagnosticsLogger.shared.record(message, context: "Notificacoes")
        }
        completion(granted)
      }
    }
  }

  public func fetchAuthorizationStatusLabel(completion: @escaping (String) -> Void) {
    center.getNotificationSettings { settings in
      completion(Self.label(for: settings.authorizationStatus))
    }
  }

  public func fetchEntitlementStatusLabel() -> String {
    let sandboxEnabled = Self.entitlementEnabled("com.apple.security.app-sandbox")
    if !sandboxEnabled {
      return "Nao aplicavel (sem sandbox)"
    }
    let enabled = Self.entitlementEnabled("com.apple.security.user-notifications")
    return enabled ? "Entitlement ok" : "Entitlement ausente"
  }

  private static func label(for status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "Nao solicitado"
    case .denied:
      return "Negado"
    case .authorized:
      return "Autorizado"
    case .provisional:
      return "Provisorio"
    case .ephemeral:
      return "Temporario"
    @unknown default:
      return "Desconhecido"
    }
  }

  public func notify(event: AlertEvent) {
    let notificationId = "rule-\(event.ruleId.uuidString)"
    let content = UNMutableNotificationContent()
    content.title = "PulseMac"
    content.body = event.message
    content.sound = .default
    content.categoryIdentifier = "pulsemac.alert"
    var userInfo: [String: String] = [
      "ruleId": event.ruleId.uuidString,
      "eventId": event.id.uuidString
    ]
    if let metric = event.metric?.rawValue {
      userInfo["metric"] = metric
    }
    content.userInfo = userInfo

    center.removePendingNotificationRequests(withIdentifiers: [notificationId])
    center.removeDeliveredNotifications(withIdentifiers: [notificationId])

    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: nil)
    center.add(request) { _ in }
  }

  public func sendTestNotification(completion: ((Bool) -> Void)? = nil) {
    requestAuthorizationIfNeeded { [weak self] granted in
      guard let self else {
        completion?(false)
        return
      }
      guard granted else {
        completion?(false)
        return
      }
      let notificationId = "pulsemac-test-notification"
      let content = UNMutableNotificationContent()
      content.title = "PulseMac"
      content.body = "Teste de notificacao"
      content.sound = .default
      content.categoryIdentifier = "pulsemac.alert"
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      center.removePendingNotificationRequests(withIdentifiers: [notificationId])
      center.removeDeliveredNotifications(withIdentifiers: [notificationId])
      let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
      center.add(request) { error in
        if let error {
          let message = "PulseMac notificacao: falha ao agendar teste: \(error.localizedDescription)"
          print(message)
          DiagnosticsLogger.shared.record(message, context: "Notificacoes")
        }
      }
      completion?(true)
    }
  }

  private static func entitlementEnabled(_ key: String) -> Bool {
    guard let task = SecTaskCreateFromSelf(nil) else { return false }
    let value = SecTaskCopyValueForEntitlement(task, key as CFString, nil)
    return (value as? Bool) == true
  }
}
