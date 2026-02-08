import AppKit
import Combine
import Foundation
import SwiftUI

final class MenuBarController {
  private let statusItem: NSStatusItem
  private let popover: NSPopover
  private let menu: NSMenu
  private var cancellables: Set<AnyCancellable> = []
  private let openSettingsAction: (SettingsTab) -> Void
  private let statusFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

  init(
    viewModel: MenuBarViewModel,
    metricsViewModel: MetricsDashboardViewModel,
    openSettingsAction: @escaping (SettingsTab) -> Void
  ) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    popover = NSPopover()
    menu = NSMenu()
    self.openSettingsAction = openSettingsAction

    setupPopover(viewModel: metricsViewModel)
    setupMenu()
    setupButton()
    bindStatusTitle(viewModel: viewModel)
  }

  func setVisible(_ isVisible: Bool) {
    statusItem.isVisible = isVisible
  }

  private func setupPopover(viewModel: MetricsDashboardViewModel) {
    popover.behavior = .transient
    popover.contentSize = NSSize(width: 260, height: 260)
    popover.contentViewController = NSHostingController(
      rootView: MenuBarPopoverView(
        viewModel: viewModel,
        onOpenAlerts: { [weak self] in self?.openSettingsTab(.alerts) },
        onOpenSettings: { [weak self] in self?.openSettingsTab(.preferences) }
      )
    )
  }

  private func setupMenu() {
    let settingsItem = NSMenuItem(title: "Ajustes...", action: #selector(openSettings), keyEquivalent: ",")
    settingsItem.target = self
    menu.addItem(settingsItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "Sair", action: #selector(quit), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
  }

  private func setupButton() {
    guard let button = statusItem.button else { return }
    let image = NSImage(named: "MenuBarIcon") ?? NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "PulseMac")
    image?.isTemplate = true
    button.image = image
    button.imagePosition = .imageLeft
    button.title = ""
    button.toolTip = "PulseMac"
    button.action = #selector(handleClick)
    button.target = self
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    applyFixedLength()
  }

  private func bindStatusTitle(viewModel: MenuBarViewModel) {
    viewModel.$cpuText
      .combineLatest(viewModel.$memoryText)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] cpu, memory in
        self?.updateStatusTitle("\(cpu) | \(memory)")
      }
      .store(in: &cancellables)
  }

  private func updateStatusTitle(_ text: String) {
    guard let button = statusItem.button else { return }
    let attributes: [NSAttributedString.Key: Any] = [
      .font: statusFont,
      .foregroundColor: NSColor.labelColor
    ]
    button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
  }

  private func applyFixedLength() {
    guard let button = statusItem.button else { return }
    let physicalMemoryGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
    let maxMemoryGB = (physicalMemoryGB * 10).rounded(.up) / 10
    let sample = String(format: "CPU 100%% | RAM %.1f GB", maxMemoryGB)
    let width = (sample as NSString).size(withAttributes: [.font: statusFont]).width
    let imageWidth = button.image?.size.width ?? 0
    statusItem.length = width + imageWidth + 18
  }

  @objc private func handleClick() {
    guard let event = NSApp.currentEvent else { return }
    if event.type == .rightMouseUp {
      statusItem.menu = menu
      statusItem.button?.performClick(nil)
      statusItem.menu = nil
      return
    }

    if popover.isShown {
      popover.performClose(nil)
    } else if let button = statusItem.button {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
  }

  @objc private func openSettings() {
    openSettingsTab(.preferences)
  }

  private func openSettingsTab(_ tab: SettingsTab) {
    popover.performClose(nil)
    openSettingsAction(tab)
  }

  @objc private func quit() {
    NSApplication.shared.terminate(nil)
  }
}
