import AppKit
import SwiftUI

final class SettingsWindowController {
  private var window: NSWindow?
  private let rootView: SettingsView
  private let navigation: SettingsNavigationModel

  init(rootView: SettingsView, navigation: SettingsNavigationModel) {
    self.rootView = rootView
    self.navigation = navigation
  }

  func show(tab: SettingsTab? = nil) {
    if let tab {
      Task { @MainActor in
        await Task.yield()
        navigation.selectedTab = tab
      }
    }

    if window == nil {
      let hosting = NSHostingController(rootView: rootView)
      let window = NSWindow(contentViewController: hosting)
      window.title = "Ajustes"
      window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      window.setContentSize(NSSize(width: 920, height: 720))
      window.minSize = NSSize(width: 720, height: 560)
      window.setFrameAutosaveName("PulseMac.SettingsWindow")
      window.toolbarStyle = .unified
      window.center()
      self.window = window
    }

    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
