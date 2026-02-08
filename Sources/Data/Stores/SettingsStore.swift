import Foundation
import PulseMacDomain

public struct AppSettings: Codable, Equatable {
  public var samplingInterval: SamplingInterval
  public var retentionDays: Int
  public var notificationsEnabled: Bool
  public var doNotDisturbEnabled: Bool
  public var dndStartMinutes: Int
  public var dndEndMinutes: Int
  public var showDisk: Bool
  public var showNetwork: Bool
  public var showBattery: Bool
  public var showMenuBar: Bool
  public var showDock: Bool

  public init(
    samplingInterval: SamplingInterval,
    retentionDays: Int,
    notificationsEnabled: Bool,
    doNotDisturbEnabled: Bool,
    dndStartMinutes: Int,
    dndEndMinutes: Int,
    showDisk: Bool,
    showNetwork: Bool,
    showBattery: Bool,
    showMenuBar: Bool,
    showDock: Bool
  ) {
    self.samplingInterval = samplingInterval
    self.retentionDays = retentionDays
    self.notificationsEnabled = notificationsEnabled
    self.doNotDisturbEnabled = doNotDisturbEnabled
    self.dndStartMinutes = dndStartMinutes
    self.dndEndMinutes = dndEndMinutes
    self.showDisk = showDisk
    self.showNetwork = showNetwork
    self.showBattery = showBattery
    self.showMenuBar = showMenuBar
    self.showDock = showDock
  }

  private enum CodingKeys: String, CodingKey {
    case samplingInterval
    case retentionDays
    case notificationsEnabled
    case doNotDisturbEnabled
    case dndStartMinutes
    case dndEndMinutes
    case showDisk
    case showNetwork
    case showBattery
    case showMenuBar
    case showDock
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    samplingInterval = try container.decodeIfPresent(SamplingInterval.self, forKey: .samplingInterval) ?? .twoSeconds
    retentionDays = try container.decodeIfPresent(Int.self, forKey: .retentionDays) ?? 7
    notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
    doNotDisturbEnabled = try container.decodeIfPresent(Bool.self, forKey: .doNotDisturbEnabled) ?? false
    dndStartMinutes = try container.decodeIfPresent(Int.self, forKey: .dndStartMinutes) ?? 1320
    dndEndMinutes = try container.decodeIfPresent(Int.self, forKey: .dndEndMinutes) ?? 420
    showDisk = try container.decodeIfPresent(Bool.self, forKey: .showDisk) ?? true
    showNetwork = try container.decodeIfPresent(Bool.self, forKey: .showNetwork) ?? true
    showBattery = try container.decodeIfPresent(Bool.self, forKey: .showBattery) ?? true
    showMenuBar = try container.decodeIfPresent(Bool.self, forKey: .showMenuBar) ?? true
    showDock = try container.decodeIfPresent(Bool.self, forKey: .showDock) ?? true
  }
}

public final class SettingsStore {
  private let defaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let key = "pulsemac.settings"

  public init(suiteName: String) {
    defaults = UserDefaults(suiteName: suiteName) ?? .standard
  }

  public func load() -> AppSettings {
    guard let data = defaults.data(forKey: key), let settings = try? decoder.decode(AppSettings.self, from: data) else {
      return AppSettings(
        samplingInterval: .twoSeconds,
        retentionDays: 7,
        notificationsEnabled: false,
        doNotDisturbEnabled: false,
        dndStartMinutes: 1320,
        dndEndMinutes: 420,
        showDisk: true,
        showNetwork: true,
        showBattery: true,
        showMenuBar: true,
        showDock: true
      )
    }
    return settings
  }

  public func save(_ settings: AppSettings) {
    guard let data = try? encoder.encode(settings) else { return }
    defaults.set(data, forKey: key)
  }
}
