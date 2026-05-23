import AppKit
import Combine
import PulseMacData
import PulseMacDomain
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  private let container = AppContainer()
  private var menuBarController: MenuBarController?
  private var settingsWindowController: SettingsWindowController?
  private let settingsNavigation = SettingsNavigationModel(selectedTab: .metrics)
  private var cancellables: Set<AnyCancellable> = []
  private var settingsObserver: NSObjectProtocol?

  func applicationDidFinishLaunching(_ notification: Notification) {
    container.notificationGate.configureCategories()
    UNUserNotificationCenter.current().delegate = self

    container.menuBarViewModel.bind(to: container.metricsSampler.publisher)
    container.metricsViewModel.bind(to: container.metricsSampler.publisher)
    container.metricsSampler.publisher
      .sink { [weak self] snapshot in
        self?.container.alertEngine.process(snapshot: snapshot)
      }
      .store(in: &cancellables)

    let settings = container.settingsStore.load()
    applyDockVisibility(settings.showDock)
    if settings.notificationsEnabled {
      container.notificationGate.requestAuthorizationIfNeeded()
    }
    container.metricsSampler.start(interval: settings.samplingInterval)

    let settingsView = SettingsView(
      settingsViewModel: container.settingsViewModel,
      alertsViewModel: container.alertsViewModel,
      metricsViewModel: container.metricsViewModel,
      processesViewModel: container.processesViewModel,
      impactViewModel: container.impactViewModel,
      logsViewModel: container.logsViewModel,
      navigation: settingsNavigation
    )
    settingsWindowController = SettingsWindowController(rootView: settingsView, navigation: settingsNavigation)
    settingsWindowController?.show(tab: .metrics)
    configureMainMenu()

    menuBarController = MenuBarController(
      viewModel: container.menuBarViewModel,
      metricsViewModel: container.metricsViewModel,
      openSettingsAction: { [weak self] tab in
        self?.settingsWindowController?.show(tab: tab)
      }
    )
    menuBarController?.setVisible(settings.showMenuBar)
    settingsObserver = NotificationCenter.default.addObserver(
      forName: AppContainer.settingsDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let settings = notification.object as? AppSettings else { return }
      self?.menuBarController?.setVisible(settings.showMenuBar)
      self?.applyDockVisibility(settings.showDock)
    }
  }

  private func configureMainMenu() {
    let mainMenu = NSMenu()
    NSApp.mainMenu = mainMenu

    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu

    let aboutItem = NSMenuItem(title: "Sobre PulseMac", action: #selector(openAbout), keyEquivalent: "")
    aboutItem.target = self
    appMenu.addItem(aboutItem)
    appMenu.addItem(.separator())
    let settingsItem = NSMenuItem(title: "Ajustes...", action: #selector(openSettings), keyEquivalent: ",")
    settingsItem.target = self
    appMenu.addItem(settingsItem)
    appMenu.addItem(.separator())
    appMenu.addItem(NSMenuItem(title: "Sair PulseMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    let fileMenuItem = NSMenuItem()
    mainMenu.addItem(fileMenuItem)
    let fileMenu = NSMenu(title: "Arquivo")
    fileMenuItem.submenu = fileMenu

    let refreshItem = NSMenuItem(title: "Atualizar", action: #selector(refreshCurrentTab), keyEquivalent: "r")
    refreshItem.target = self
    fileMenu.addItem(refreshItem)
    let exportItem = NSMenuItem(title: "Exportar diagnostico...", action: #selector(exportDiagnostics), keyEquivalent: "e")
    exportItem.target = self
    fileMenu.addItem(exportItem)

    let viewMenuItem = NSMenuItem()
    mainMenu.addItem(viewMenuItem)
    let viewMenu = NSMenu(title: "Visualizar")
    viewMenuItem.submenu = viewMenu

    viewMenu.addItem(makeTabItem(title: "Metricas", tab: .metrics, key: "1"))
    viewMenu.addItem(makeTabItem(title: "Processos", tab: .processes, key: "2"))
    viewMenu.addItem(makeTabItem(title: "Alertas", tab: .alerts, key: "3"))
    viewMenu.addItem(makeTabItem(title: "Impacto", tab: .impact, key: "4"))
    viewMenu.addItem(makeTabItem(title: "Logs", tab: .logs, key: "7"))
    viewMenu.addItem(makeTabItem(title: "Widgets", tab: .widgets, key: "5"))
    viewMenu.addItem(makeTabItem(title: "Ajustes", tab: .preferences, key: "6"))

    let windowMenuItem = NSMenuItem()
    mainMenu.addItem(windowMenuItem)
    let windowMenu = NSMenu(title: "Janela")
    windowMenuItem.submenu = windowMenu
    NSApp.windowsMenu = windowMenu

    windowMenu.addItem(
      NSMenuItem(title: "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
    )
    windowMenu.addItem(
      NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
    )
    windowMenu.addItem(
      NSMenuItem(title: "Fechar", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    )
    windowMenu.addItem(.separator())
    let bringToFront = NSMenuItem(title: "Trazer tudo para frente", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
    bringToFront.target = NSApp
    windowMenu.addItem(bringToFront)
  }

  private func makeTabItem(title: String, tab: SettingsTab, key: String) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: #selector(openTab(_:)), keyEquivalent: key)
    item.target = self
    item.representedObject = tab
    return item
  }

  @objc private func openSettings() {
    settingsWindowController?.show(tab: .preferences)
  }

  @objc private func openAbout() {
    settingsWindowController?.show(tab: .about)
  }

  @objc private func openTab(_ sender: NSMenuItem) {
    guard let tab = sender.representedObject as? SettingsTab else { return }
    settingsWindowController?.show(tab: tab)
  }

  @objc private func refreshCurrentTab() {
    switch settingsNavigation.selectedTab {
    case .processes:
      container.processesViewModel.refresh(force: true)
    case .impact:
      container.impactViewModel.refresh()
    case .logs:
      container.logsViewModel.refresh()
    default:
      break
    }
  }

  @objc private func exportDiagnostics() {
    container.settingsViewModel.exportDiagnostics()
  }

  private func applyDockVisibility(_ showDock: Bool) {
    let policy: NSApplication.ActivationPolicy = showDock ? .regular : .accessory
    if NSApp.activationPolicy() != policy {
      NSApp.setActivationPolicy(policy)
    }
    settingsWindowController?.show()
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let action = response.actionIdentifier
    let userInfo = response.notification.request.content.userInfo
    if action == "snooze_10m" || action == "mute_1h" {
      guard let ruleIdString = userInfo["ruleId"] as? String,
            let ruleId = UUID(uuidString: ruleIdString)
      else {
        completionHandler()
        return
      }
      let now = Date()
      let interval: TimeInterval = action == "snooze_10m" ? 600 : 3600
      container.alertMuteStore.mute(ruleId: ruleId, until: now.addingTimeInterval(interval))
    } else if action == "open_app" || action == UNNotificationDefaultActionIdentifier {
      let metric = metricFromUserInfo(userInfo)
      if let category = metricsCategory(for: metric) {
        container.metricsViewModel.selectedCategory = category
      } else {
        container.metricsViewModel.selectedCategory = MetricsCategory.overview
      }
      settingsWindowController?.show(tab: .metrics)
    }
    completionHandler()
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    true
  }

  private func metricFromUserInfo(_ userInfo: [AnyHashable: Any]) -> AlertMetric? {
    guard let raw = userInfo["metric"] as? String else { return nil }
    return AlertMetric(rawValue: raw)
  }

  private func metricsCategory(for metric: AlertMetric?) -> MetricsCategory? {
    guard let metric else { return nil }
    switch metric {
    case .cpuUsagePercent:
      return .cpu
    case .memoryUsedPercent:
      return .memory
    case .diskFreePercent:
      return .disk
    case .networkDownloadKBps, .networkUploadKBps:
      return .network
    case .batteryChargePercent:
      return .battery
    case .cpuTempC, .gpuTempC, .fanMaxRPM:
      return .sensors
    }
  }
}

extension AppDelegate: NSUserInterfaceValidations {
  func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    if item.action == #selector(refreshCurrentTab) {
      return settingsNavigation.selectedTab == .processes
        || settingsNavigation.selectedTab == .impact
        || settingsNavigation.selectedTab == .logs
    }
    return true
  }
}
