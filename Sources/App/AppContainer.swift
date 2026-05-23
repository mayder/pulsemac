import AppKit
import Combine
import Foundation
import PulseMacData
import PulseMacDomain
import Security
import UniformTypeIdentifiers

final class AppContainer {
  let appGroupId = "group.com.pulsemac.shared"
  static let settingsDidChangeNotification = Notification.Name("PulseMac.settingsDidChange")

  let settingsStore: SettingsStore
  let favoritesStore: FavoritesStore
  let ruleStore: AlertRuleDefaultsStore
  let historyStore: SQLiteAlertHistoryStore
  let alertMuteStore: AlertMuteStore
  let notificationClient: UserNotificationClient
  let notificationGate: NotificationGate
  let metricsSampler: MetricsSampler
  let metricsHistoryStore: AppGroupMetricsHistoryStore
  let alertEngine: AlertEngine
  let diagnosticsExporter: DiagnosticsExporter
  let menuBarViewModel: MenuBarViewModel
  let metricsViewModel: MetricsDashboardViewModel
  let settingsViewModel: SettingsViewModel
  let alertsViewModel: AlertsViewModel
  let processesViewModel: ProcessesViewModel
  let impactViewModel: ImpactViewModel
  let logsViewModel: SystemLogsViewModel

  init() {
    let metricsStore = AppGroupMetricsStore(suiteName: appGroupId)
    settingsStore = SettingsStore(suiteName: appGroupId)
    favoritesStore = FavoritesStore(suiteName: appGroupId)
    ruleStore = AlertRuleDefaultsStore(suiteName: appGroupId)
    alertMuteStore = AlertMuteStore(suiteName: appGroupId)

    let dbURL = AppContainer.alertsDatabaseURL()
    historyStore = SQLiteAlertHistoryStore(fileURL: dbURL)

    let settings = settingsStore.load()
    notificationClient = UserNotificationClient()
    notificationGate = NotificationGate(
      client: notificationClient,
      muteStore: alertMuteStore,
      isEnabled: settings.notificationsEnabled,
      dndEnabled: settings.doNotDisturbEnabled,
      dndStartMinutes: settings.dndStartMinutes,
      dndEndMinutes: settings.dndEndMinutes
    )

    metricsHistoryStore = AppGroupMetricsHistoryStore(suiteName: appGroupId, retentionDays: settings.retentionDays)

    let cpuCollector = CPUMetricsCollector()
    let memoryCollector = MemoryMetricsCollector()
    let diskCollector = DiskMetricsCollector()
    let networkCollector = NetworkMetricsCollector()
    let batteryCollector = BatteryMetricsCollector()
    let topProcessesCollector = TopProcessesCollector()
    let processResourcesCollector = TopProcessesCollector()
    let impactProcessCollector = TopProcessesCollector()
    let thermalCollector = ThermalMetricsCollector()
    let powermetricsProvider = PowermetricsFallbackProvider()
    let logReader = UnifiedLogReader()
    metricsSampler = MetricsSampler(
      cpuProvider: cpuCollector,
      memoryProvider: memoryCollector,
      diskProvider: diskCollector,
      networkProvider: networkCollector,
      batteryProvider: batteryCollector,
      topProcessesProvider: topProcessesCollector,
      thermalProvider: thermalCollector,
      snapshotStore: metricsStore,
      historyStore: metricsHistoryStore
    )
    metricsSampler.updateOptions(showDisk: settings.showDisk, showNetwork: settings.showNetwork, showBattery: settings.showBattery)

    alertEngine = AlertEngine(
      ruleStore: ruleStore,
      historyStore: historyStore,
      notificationClient: notificationGate
    )

    let exporter = DiagnosticsExporter(
      settingsStore: settingsStore,
      ruleStore: ruleStore,
      historyStore: historyStore,
      metricsStore: metricsStore
    )
    diagnosticsExporter = exporter

    menuBarViewModel = MenuBarViewModel()
    metricsViewModel = MetricsDashboardViewModel(
      powermetricsProvider: powermetricsProvider,
      historyStore: metricsHistoryStore,
      processResourcesProvider: processResourcesCollector
    )
    alertsViewModel = AlertsViewModel(
      ruleStore: ruleStore,
      historyStore: historyStore,
      onTestAlert: { [weak notificationGate] event in
        notificationGate?.notify(event: event)
      },
      onRequestNotificationPermission: { [weak notificationGate] completion in
        DispatchQueue.main.async {
          NSApp.activate(ignoringOtherApps: true)
          notificationGate?.requestAuthorizationIfNeeded(completion: completion)
        }
      }
    )
    processesViewModel = ProcessesViewModel(provider: processResourcesCollector, favoritesStore: favoritesStore)
    impactViewModel = ImpactViewModel(
      ruleStore: ruleStore,
      metricsStore: metricsStore,
      processProvider: impactProcessCollector
    )
    logsViewModel = SystemLogsViewModel(provider: logReader)
    let appGroupIdentifier = appGroupId
    settingsViewModel = SettingsViewModel(
      store: settingsStore,
      onIntervalChange: { [weak metricsSampler] interval in
        metricsSampler?.start(interval: interval)
      },
      onSettingsChange: { [weak metricsSampler, weak notificationGate, weak metricsViewModel, weak metricsHistoryStore] updated in
        metricsSampler?.updateOptions(showDisk: updated.showDisk, showNetwork: updated.showNetwork, showBattery: updated.showBattery)
        notificationGate?.isEnabled = updated.notificationsEnabled
        notificationGate?.updateSchedule(
          enabled: updated.doNotDisturbEnabled,
          startMinutes: updated.dndStartMinutes,
          endMinutes: updated.dndEndMinutes
        )
        metricsViewModel?.updateVisibility(showDisk: updated.showDisk, showNetwork: updated.showNetwork, showBattery: updated.showBattery)
        metricsHistoryStore?.updateRetentionDays(updated.retentionDays)
        NotificationCenter.default.post(name: AppContainer.settingsDidChangeNotification, object: updated)
      },
      onRequestNotificationPermission: { [weak notificationGate] completion in
        DispatchQueue.main.async {
          NSApp.activate(ignoringOtherApps: true)
          notificationGate?.requestAuthorizationIfNeeded(completion: completion)
        }
      },
      onFetchNotificationStatus: { [weak notificationGate] completion in
        notificationGate?.fetchAuthorizationStatusLabel(completion: completion)
      },
      onFetchNotificationEntitlement: { [weak notificationGate] in
        notificationGate?.fetchEntitlementStatusLabel() ?? "Desconhecido"
      },
      onOpenSystemNotificationSettings: {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
      },
      onTestNotification: { [weak notificationClient] in
        notificationClient?.sendTestNotification()
      },
      onExportDiagnostics: { [weak exporter] in
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "PulseMac-diagnostico-\(Self.timestampString()).json"
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return .canceled }
        guard let exporter else { return .failure("Exportador indisponivel") }
        do {
          try exporter.export(to: url)
          return .success(url)
        } catch {
          return .failure("Falha ao exportar: \(error.localizedDescription)")
        }
      },
      onExportQuickReport: { [weak exporter] in
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "PulseMac-resumo-\(Self.timestampString()).json"
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return .canceled }
        guard let exporter else { return .failure("Exportador indisponivel") }
        do {
          try exporter.exportQuickReport(to: url)
          return .success(url)
        } catch {
          return .failure("Falha ao exportar: \(error.localizedDescription)")
        }
      },
      onClearAlertHistory: { [weak historyStore] in
        historyStore?.clearAll()
      },
      onOpenDiagnosticsFolder: {
        let directory = Self.alertsDatabaseURL().deletingLastPathComponent()
        NSWorkspace.shared.open(directory)
      },
      onFetchAdvancedDiagnostics: { [appGroupIdentifier, weak notificationGate] completion in
        let appInfo = DiagnosticsAppInfo.current()
        let sandboxEnabled = Self.entitlementEnabled("com.apple.security.app-sandbox")
        let notificationsEntitlement = sandboxEnabled
          ? (Self.entitlementEnabled("com.apple.security.user-notifications") ? "Entitlement ok" : "Entitlement ausente")
          : "Nao aplicavel"

        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        let appGroupStatus = appGroupURL == nil ? "Indisponivel" : "OK (\(appGroupURL?.lastPathComponent ?? "--"))"

        var rows: [AdvancedDiagnosticRow] = [
          AdvancedDiagnosticRow(title: "Versao", value: "\(appInfo.version) (\(appInfo.build))"),
          AdvancedDiagnosticRow(title: "Bundle ID", value: appInfo.bundleId),
          AdvancedDiagnosticRow(title: "Sandbox", value: sandboxEnabled ? "Ativo" : "Desativado"),
          AdvancedDiagnosticRow(title: "Entitlement notificacoes", value: notificationsEntitlement),
          AdvancedDiagnosticRow(title: "App Group", value: appGroupStatus),
          AdvancedDiagnosticRow(title: "App Group ID", value: appGroupIdentifier)
        ]

        if let lastError = DiagnosticsLogger.shared.snapshot() {
          let timestamp = Self.timeString(from: lastError.recordedAt)
          rows.append(AdvancedDiagnosticRow(title: "Ultimo erro", value: "\(lastError.message) (\(timestamp))"))
        } else {
          rows.append(AdvancedDiagnosticRow(title: "Ultimo erro", value: "Nenhum"))
        }

        guard let notificationGate else {
          rows.append(AdvancedDiagnosticRow(title: "Permissao notificacoes", value: "Desconhecido"))
          completion(rows)
          return
        }

        notificationGate.fetchAuthorizationStatusLabel { status in
          var finalRows = rows
          finalRows.insert(AdvancedDiagnosticRow(title: "Permissao notificacoes", value: status), at: 3)
          completion(finalRows)
        }
      }
    )
    metricsViewModel.updateVisibility(showDisk: settings.showDisk, showNetwork: settings.showNetwork, showBattery: settings.showBattery)
  }

  private static func alertsDatabaseURL() -> URL {
    let fileManager = FileManager.default
    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
    let dir = base.appendingPathComponent("PulseMac", isDirectory: true)
    if !fileManager.fileExists(atPath: dir.path) {
      try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir.appendingPathComponent("alerts.sqlite")
  }

  private static func timestampString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: Date())
  }

  private static func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }

  private static func entitlementEnabled(_ key: String) -> Bool {
    guard let task = SecTaskCreateFromSelf(nil) else { return false }
    let value = SecTaskCopyValueForEntitlement(task, key as CFString, nil)
    if let boolValue = value as? Bool {
      return boolValue
    }
    if let arrayValue = value as? [Any] {
      return !arrayValue.isEmpty
    }
    return false
  }
}
