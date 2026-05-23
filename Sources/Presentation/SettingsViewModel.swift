import Combine
import Foundation
import PulseMacData
import PulseMacDomain

public final class SettingsViewModel: ObservableObject {
  @Published public var samplingInterval: SamplingInterval
  @Published public var retentionDays: Int
  @Published public var notificationsEnabled: Bool
  @Published public var doNotDisturbEnabled: Bool
  @Published public var dndStartTime: Date
  @Published public var dndEndTime: Date
  @Published public var showDisk: Bool
  @Published public var showNetwork: Bool
  @Published public var showBattery: Bool
  @Published public var showMenuBar: Bool
  @Published public var showDock: Bool
  @Published public var diagnosticsStatusText: String = ""
  @Published public var quickReportStatusText: String = ""
  @Published public var quickActionsStatusText: String = ""
  @Published public var notificationStatusText: String = ""
  @Published public var notificationEntitlementText: String = ""
  @Published public var advancedDiagnosticsRows: [AdvancedDiagnosticRow] = []
  @Published public var advancedDiagnosticsUpdatedText: String = ""

  private let store: SettingsStore
  private let onIntervalChange: (SamplingInterval) -> Void
  private let onSettingsChange: (AppSettings) -> Void
  private let onRequestNotificationPermission: (@escaping (Bool) -> Void) -> Void
  private let onFetchNotificationStatus: (@escaping (String) -> Void) -> Void
  private let onFetchNotificationEntitlement: () -> String
  private let onOpenSystemNotificationSettings: () -> Void
  private let onTestNotification: () -> Void
  private let onExportDiagnostics: () -> DiagnosticsExportOutcome
  private let onExportQuickReport: () -> DiagnosticsExportOutcome
  private let onClearAlertHistory: () -> Void
  private let onOpenDiagnosticsFolder: () -> Void
  private let onFetchAdvancedDiagnostics: (@escaping ([AdvancedDiagnosticRow]) -> Void) -> Void
  private var lastNotificationsEnabled: Bool

  public init(
    store: SettingsStore,
    onIntervalChange: @escaping (SamplingInterval) -> Void,
    onSettingsChange: @escaping (AppSettings) -> Void,
    onRequestNotificationPermission: @escaping (@escaping (Bool) -> Void) -> Void,
    onFetchNotificationStatus: @escaping (@escaping (String) -> Void) -> Void,
    onFetchNotificationEntitlement: @escaping () -> String,
    onOpenSystemNotificationSettings: @escaping () -> Void,
    onTestNotification: @escaping () -> Void,
    onExportDiagnostics: @escaping () -> DiagnosticsExportOutcome,
    onExportQuickReport: @escaping () -> DiagnosticsExportOutcome,
    onClearAlertHistory: @escaping () -> Void,
    onOpenDiagnosticsFolder: @escaping () -> Void,
    onFetchAdvancedDiagnostics: @escaping (@escaping ([AdvancedDiagnosticRow]) -> Void) -> Void
  ) {
    let settings = store.load()
    self.store = store
    self.onIntervalChange = onIntervalChange
    self.onSettingsChange = onSettingsChange
    self.onRequestNotificationPermission = onRequestNotificationPermission
    self.onFetchNotificationStatus = onFetchNotificationStatus
    self.onFetchNotificationEntitlement = onFetchNotificationEntitlement
    self.onOpenSystemNotificationSettings = onOpenSystemNotificationSettings
    self.onTestNotification = onTestNotification
    self.onExportDiagnostics = onExportDiagnostics
    self.onExportQuickReport = onExportQuickReport
    self.onClearAlertHistory = onClearAlertHistory
    self.onOpenDiagnosticsFolder = onOpenDiagnosticsFolder
    self.onFetchAdvancedDiagnostics = onFetchAdvancedDiagnostics
    samplingInterval = settings.samplingInterval
    retentionDays = settings.retentionDays
    notificationsEnabled = settings.notificationsEnabled
    doNotDisturbEnabled = settings.doNotDisturbEnabled
    dndStartTime = Self.date(fromMinutes: settings.dndStartMinutes)
    dndEndTime = Self.date(fromMinutes: settings.dndEndMinutes)
    showDisk = settings.showDisk
    showNetwork = settings.showNetwork
    showBattery = settings.showBattery
    showMenuBar = settings.showMenuBar
    showDock = settings.showDock
    lastNotificationsEnabled = settings.notificationsEnabled
    refreshNotificationStatus()
    refreshAdvancedDiagnostics()
  }

  public func save() {
    let startMinutes = Self.minutes(from: dndStartTime)
    let endMinutes = Self.minutes(from: dndEndTime)
    let settings = AppSettings(
      samplingInterval: samplingInterval,
      retentionDays: retentionDays,
      notificationsEnabled: notificationsEnabled,
      doNotDisturbEnabled: doNotDisturbEnabled,
      dndStartMinutes: startMinutes,
      dndEndMinutes: endMinutes,
      showDisk: showDisk,
      showNetwork: showNetwork,
      showBattery: showBattery,
      showMenuBar: showMenuBar,
      showDock: showDock
    )
    store.save(settings)
    onIntervalChange(samplingInterval)
    onSettingsChange(settings)
    if notificationsEnabled, notificationsEnabled != lastNotificationsEnabled {
      onRequestNotificationPermission { _ in }
      refreshNotificationStatus()
    }
    lastNotificationsEnabled = notificationsEnabled
  }

  public func requestNotificationPermissionAndTest() {
    DispatchQueue.main.async { [weak self] in
      self?.diagnosticsStatusText = "Solicitando permissao..."
    }
    onRequestNotificationPermission { [weak self] granted in
      self?.refreshNotificationStatus()
      guard granted else {
        DispatchQueue.main.async {
          self?.diagnosticsStatusText = "Permissao negada. Abra as Notificacoes do macOS."
        }
        return
      }
      DispatchQueue.main.async {
        self?.onTestNotification()
        self?.diagnosticsStatusText = "Notificacao enviada para teste."
      }
    }
  }

  public func openSystemNotificationSettings() {
    onOpenSystemNotificationSettings()
  }

  public func exportDiagnostics() {
    let result = onExportDiagnostics()
    switch result {
    case let .success(url):
      diagnosticsStatusText = "Exportado: \(url.lastPathComponent)"
    case .canceled:
      diagnosticsStatusText = "Exportacao cancelada"
    case let .failure(message):
      diagnosticsStatusText = message
    }
  }

  public func exportQuickReport() {
    let result = onExportQuickReport()
    switch result {
    case let .success(url):
      quickReportStatusText = "Resumo exportado: \(url.lastPathComponent)"
    case .canceled:
      quickReportStatusText = "Exportacao cancelada"
    case let .failure(message):
      quickReportStatusText = message
    }
  }

  public func pauseAlerts() {
    guard notificationsEnabled else {
      quickActionsStatusText = "Alertas ja estao pausados."
      return
    }
    notificationsEnabled = false
    save()
    quickActionsStatusText = "Alertas pausados."
  }

  public func resumeAlerts() {
    guard !notificationsEnabled else {
      quickActionsStatusText = "Alertas ja estao ativos."
      return
    }
    notificationsEnabled = true
    save()
    quickActionsStatusText = "Alertas ativados."
  }

  public func clearAlertHistory() {
    onClearAlertHistory()
    quickActionsStatusText = "Historico limpo."
  }

  public func openDiagnosticsFolder() {
    onOpenDiagnosticsFolder()
    quickActionsStatusText = "Pasta aberta."
  }

  public func refreshAdvancedDiagnostics() {
    onFetchAdvancedDiagnostics { [weak self] rows in
      DispatchQueue.main.async {
        self?.advancedDiagnosticsRows = rows
        self?.advancedDiagnosticsUpdatedText = "Atualizado: \(Self.timeString(from: Date()))"
      }
    }
  }

  private func refreshNotificationStatus() {
    onFetchNotificationStatus { [weak self] text in
      DispatchQueue.main.async {
        self?.notificationStatusText = "Status: \(text)"
        self?.notificationEntitlementText = "Entitlement: \(self?.onFetchNotificationEntitlement() ?? "Desconhecido")"
      }
    }
  }

  private static func date(fromMinutes minutes: Int) -> Date {
    let calendar = Calendar.current
    let now = Date()
    let hour = max(min(minutes / 60, 23), 0)
    let minute = max(min(minutes % 60, 59), 0)
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
  }

  private static func minutes(from date: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    return (components.hour ?? 0) * 60 + (components.minute ?? 0)
  }

  private static func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }
}

public enum DiagnosticsExportOutcome {
  case success(URL)
  case canceled
  case failure(String)
}

public struct AdvancedDiagnosticRow: Identifiable {
  public let id: String
  public let title: String
  public let value: String

  public init(title: String, value: String) {
    self.title = title
    self.value = value
    id = title
  }
}
