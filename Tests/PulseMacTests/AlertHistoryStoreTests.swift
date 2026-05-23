import PulseMacDomain
import XCTest

final class AlertHistoryStoreTests: XCTestCase {
  func testInMemoryStorePersists() {
    let store = InMemoryHistoryStore()
    let event = AlertEvent(ruleId: UUID(), timestamp: Date(), severity: .info, message: "Teste")

    store.record(event: event)
    let list = store.list(limit: 10)

    XCTAssertEqual(list.count, 1)
    XCTAssertEqual(list.first?.message, "Teste")
  }

  func testInMemoryStoreClears() {
    let store = InMemoryHistoryStore()
    let event = AlertEvent(ruleId: UUID(), timestamp: Date(), severity: .info, message: "Teste")

    store.record(event: event)
    store.clearAll()

    XCTAssertEqual(store.list(limit: 10).count, 0)
  }
}

private final class InMemoryHistoryStore: AlertHistoryStore {
  private var events: [AlertEvent] = []

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
