import Foundation

public protocol NotificationClient {
  func notify(event: AlertEvent)
}
