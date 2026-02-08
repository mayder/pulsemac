import Foundation

public final class AlertMuteStore {
  private let defaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let key = "pulsemac.alert.mutes"

  public init(suiteName: String) {
    defaults = UserDefaults(suiteName: suiteName) ?? .standard
  }

  public func mute(ruleId: UUID, until: Date) {
    var map = loadMap()
    map[ruleId.uuidString] = until
    saveMap(map)
  }

  public func clear(ruleId: UUID) {
    var map = loadMap()
    map.removeValue(forKey: ruleId.uuidString)
    saveMap(map)
  }

  public func isMuted(ruleId: UUID, now: Date = Date()) -> Bool {
    var map = loadMap()
    guard let until = map[ruleId.uuidString] else { return false }
    if until > now {
      return true
    }
    map.removeValue(forKey: ruleId.uuidString)
    saveMap(map)
    return false
  }

  private func loadMap() -> [String: Date] {
    guard let data = defaults.data(forKey: key),
          let decoded = try? decoder.decode([String: Date].self, from: data) else { return [:] }
    return decoded
  }

  private func saveMap(_ map: [String: Date]) {
    guard let data = try? encoder.encode(map) else { return }
    defaults.set(data, forKey: key)
  }
}
