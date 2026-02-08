import AppKit
import Foundation
import PulseMacDomain
import SwiftUI

public struct SettingsView: View {
  @ObservedObject private var settingsViewModel: SettingsViewModel
  @ObservedObject private var alertsViewModel: AlertsViewModel
  @ObservedObject private var metricsViewModel: MetricsDashboardViewModel
  @ObservedObject private var processesViewModel: ProcessesViewModel
  @ObservedObject private var impactViewModel: ImpactViewModel
  @ObservedObject private var navigation: SettingsNavigationModel

  init(
    settingsViewModel: SettingsViewModel,
    alertsViewModel: AlertsViewModel,
    metricsViewModel: MetricsDashboardViewModel,
    processesViewModel: ProcessesViewModel,
    impactViewModel: ImpactViewModel,
    navigation: SettingsNavigationModel
  ) {
    self.settingsViewModel = settingsViewModel
    self.alertsViewModel = alertsViewModel
    self.metricsViewModel = metricsViewModel
    self.processesViewModel = processesViewModel
    self.impactViewModel = impactViewModel
    self.navigation = navigation
  }

  public var body: some View {
    NavigationSplitView {
      List(selection: selectionBinding) {
        ForEach(SettingsTab.allCases) { tab in
          Label(tab.title, systemImage: tab.systemImage)
            .tag(tab)
        }
      }
      .listStyle(.sidebar)
      .frame(minWidth: 180)
    } detail: {
      Group {
        switch navigation.selectedTab {
        case .metrics:
          MetricsView(viewModel: metricsViewModel)
        case .processes:
          ProcessesView(viewModel: processesViewModel)
        case .alerts:
          AlertsView(viewModel: alertsViewModel)
        case .impact:
          ImpactView(viewModel: impactViewModel)
        case .preferences:
          PreferencesView(viewModel: settingsViewModel)
        case .about:
          AboutView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationSplitViewStyle(.balanced)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        if navigation.selectedTab == .processes {
          Button {
            processesViewModel.refresh(force: true)
          } label: {
            Label("Atualizar", systemImage: "arrow.clockwise")
          }
        } else if navigation.selectedTab == .impact {
          Button {
            impactViewModel.refresh()
          } label: {
            Label("Atualizar", systemImage: "arrow.clockwise")
          }
        }
      }
    }
    .tint(BrandStyle.accent)
  }

  private var selectionBinding: Binding<SettingsTab?> {
    Binding(
      get: { navigation.selectedTab },
      set: { newValue in
        guard let newValue else { return }
        guard navigation.selectedTab != newValue else { return }
        navigation.selectedTab = newValue
      }
    )
  }
}

private struct AboutView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        GlassCard {
          HStack(alignment: .center, spacing: 16) {
            logoView
            VStack(alignment: .leading, spacing: 4) {
              Text("PulseMac")
                .font(.title2)
                .fontWeight(.semibold)
              Text("Sistema de monitoramento offline para macOS")
                .foregroundColor(.secondary)
            }
            Spacer()
          }
        }

        CardSection("Sobre") {
          Text("Feito por Breno Mayder Cruz.")
          Text("Projeto independente, focado em performance e privacidade.")
            .foregroundColor(.secondary)
        }

        CardSection("Creditos") {
          Text("Design, arquitetura e implementacao: Breno Mayder Cruz.")
          Text("Sem telemetria, sem analytics, 100% offline.")
            .foregroundColor(.secondary)
        }
      }
      .padding(16)
    }
  }

  private var logoView: some View {
    Group {
      if let image = NSImage(named: "AppIcon") {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
      } else {
        Image(systemName: "waveform.path.ecg")
          .resizable()
          .scaledToFit()
          .foregroundColor(BrandStyle.accent)
          .padding(12)
      }
    }
    .frame(width: 56, height: 56)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(BrandStyle.surfaceAlt)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(BrandStyle.border, lineWidth: 1)
    )
  }
}

private struct ImpactView: View {
  @ObservedObject var viewModel: ImpactViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        GlassCard {
          HStack {
            SectionHeader("Impacto", subtitle: "Regras ativas e possiveis processos causadores.")
            Spacer()
          }
        }

        CardSection("Regras ativas") {
          if viewModel.activeRules.isEmpty {
            Text("Nenhuma regra ativa no momento.")
              .foregroundColor(.secondary)
          } else {
            VStack(alignment: .leading, spacing: 12) {
              ForEach(viewModel.activeRules) { item in
                GlassCard {
                  VStack(alignment: .leading, spacing: 8) {
                    HStack {
                      Text(item.name)
                        .font(.headline)
                      Spacer()
                      BadgePill(text: item.severityLabel, color: item.severityColor)
                    }

                    Text("\(item.metricLabel) \(item.comparisonSymbol) \(item.thresholdText)")
                      .foregroundColor(.secondary)
                      .font(.caption)
                    Text("Atual: \(item.currentValueText)")
                      .font(.callout)

                    if !item.suggestions.isEmpty {
                      Divider()
                      Text("Possiveis processos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                      VStack(alignment: .leading, spacing: 6) {
                        ForEach(item.suggestions) { suggestion in
                          VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                              .font(.callout)
                            Text(suggestion.detail)
                              .font(.caption)
                              .foregroundColor(.secondary)
                            if let path = suggestion.path {
                              Text(path)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            }
                          }
                        }
                      }
                    } else if let note = item.note {
                      Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                  }
                }
              }
            }
          }
        }

        if !viewModel.statusText.isEmpty {
          Text(viewModel.statusText)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)
        }
        Text(viewModel.lastUpdatedText)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(16)
    }
    .onAppear {
      DispatchQueue.main.async {
        viewModel.refreshIfNeeded()
      }
    }
  }
}

private struct ProcessesView: View {
  @ObservedObject var viewModel: ProcessesViewModel
  @State private var sortOrder: [KeyPathComparator<ProcessTableRow>] = [
    .init(\.cpuPercent, order: .reverse)
  ]
  @State private var searchText: String = ""
  @State private var selection: ProcessTableRow.ID?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      GlassCard {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            SectionHeader("Processos", subtitle: "Coleta sob demanda. Atualize quando precisar.")
          }
          Spacer()
          if viewModel.isLoading {
            ProgressView()
              .controlSize(.small)
          }
        }
      }

      HStack(alignment: .top, spacing: 12) {
        CardSection("Lista") {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Spacer()
              Text(viewModel.lastUpdatedText)
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Table(sortedRows, selection: $selection, sortOrder: $sortOrder) {
              TableColumn("Processo", value: \.name) { row in
                HStack(spacing: 8) {
                  AppIconView(image: row.icon)
                  Text(row.displayName)
                }
              }
              TableColumn("App") { row in
                Text(row.appNameText)
                  .foregroundColor(.secondary)
              }
              TableColumn("PID", value: \.pid) { row in
                Text(row.pidText)
                  .foregroundColor(.secondary)
              }
              TableColumn("CPU %", value: \.cpuPercent) { row in
                Text(row.cpuText)
              }
              TableColumn("Memoria", value: \.memoryBytes) { row in
                Text(row.memoryText)
              }
              TableColumn("Disco (R/W)") { row in
                Text(row.diskText)
                  .foregroundColor(.secondary)
              }
            }
            .frame(minHeight: 360)
          }
        }

        CardSection("Detalhes") {
          if let selected = selectedRow {
            VStack(alignment: .leading, spacing: 8) {
              Text(selected.displayName)
                .font(.headline)
              detailRow("PID", selected.pidText)
              detailRow("Processo", selected.name)
              if let app = selected.appName {
                detailRow("App", app)
              }
              if let bundleId = selected.bundleId {
                detailRow("Bundle ID", bundleId)
              }
              if let bundlePath = selected.bundlePath {
                detailRow("Bundle", bundlePath)
              }
              if let execPath = selected.executablePath {
                detailRow("Executavel", execPath)
              }
              if let parentPid = selected.parentPidText {
                detailRow("PID pai", parentPid)
              }

              HStack(spacing: 12) {
                if let revealURL = selected.revealURL {
                  Button {
                    NSWorkspace.shared.activateFileViewerSelecting([revealURL])
                  } label: {
                    Label("Revelar no Finder", systemImage: "folder")
                  }
                  .buttonStyle(.borderedProminent)
                }
                if let copyValue = selected.copyValue {
                  Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(copyValue, forType: .string)
                  } label: {
                    Label("Copiar caminho", systemImage: "doc.on.doc")
                  }
                  .buttonStyle(.bordered)
                }
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          } else {
            Text("Selecione um processo para ver detalhes.")
              .foregroundColor(.secondary)
          }
        }
        .frame(minWidth: 260, maxWidth: 320)
      }

      if !viewModel.statusText.isEmpty {
        Text(viewModel.statusText)
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
      }
    }
    .padding(16)
    .onAppear {
      DispatchQueue.main.async {
        viewModel.refreshIfNeeded()
      }
    }
    .onChange(of: viewModel.rows) { _ in
      DispatchQueue.main.async {
        ensureSelection()
      }
    }
    .onChange(of: selection) { _ in
      DispatchQueue.main.async {
        ensureSelection()
      }
    }
    .searchable(text: $searchText, placement: .toolbar, prompt: "Buscar processo")
  }

  private var filteredRows: [ProcessTableRow] {
    guard !searchText.isEmpty else { return viewModel.rows }
    return viewModel.rows.filter { row in
      row.name.localizedCaseInsensitiveContains(searchText)
        || row.appNameText.localizedCaseInsensitiveContains(searchText)
        || row.pidText.contains(searchText)
    }
  }

  private var sortedRows: [ProcessTableRow] {
    filteredRows.sorted(using: sortOrder)
  }

  private var selectedRow: ProcessTableRow? {
    guard let selection else { return nil }
    return viewModel.rows.first(where: { $0.id == selection })
  }

  private func detailRow(_ title: String, _ value: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(width: 90, alignment: .leading)
      Text(value)
        .font(.callout)
        .textSelection(.enabled)
      Spacer()
    }
  }

  private func ensureSelection() {
    guard !viewModel.rows.isEmpty else {
      selection = nil
      return
    }
    if let selection, viewModel.rows.contains(where: { $0.id == selection }) {
      return
    }
    selection = viewModel.rows.first?.id
  }
}

final class ProcessesViewModel: ObservableObject {
  @Published private(set) var rows: [ProcessTableRow] = []
  @Published private(set) var lastUpdatedText: String = "Nunca atualizado"
  @Published private(set) var statusText: String = ""
  @Published private(set) var isLoading: Bool = false

  private let provider: ProcessResourcesProviding
  private let limit: Int
  private let sampleDelay: TimeInterval
  private var didLoad: Bool = false

  init(provider: ProcessResourcesProviding, limit: Int = 0, sampleDelay: TimeInterval = 1.0) {
    self.provider = provider
    self.limit = limit
    self.sampleDelay = sampleDelay
  }

  func refreshIfNeeded() {
    guard !didLoad else { return }
    refresh(force: true)
  }

  func refresh(force: Bool) {
    guard !isLoading else { return }
    if didLoad, !force {
      return
    }
    isLoading = true
    statusText = "Coletando processos..."

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      _ = provider.readResources(limit: limit)
      Thread.sleep(forTimeInterval: sampleDelay)
      let snapshot = provider.readResources(limit: limit)
      let mapped = snapshot.map { item in
        ProcessTableRow(
          pid: item.pid,
          name: item.name,
          cpuPercent: item.cpuPercent,
          memoryBytes: item.memoryBytes,
          diskReadBytesPerSec: item.diskReadBytesPerSec,
          diskWriteBytesPerSec: item.diskWriteBytesPerSec,
          appName: item.appName,
          bundleId: item.bundleId,
          bundlePath: item.bundlePath,
          executablePath: item.executablePath,
          parentPid: item.parentPid
        )
      }

      DispatchQueue.main.async {
        self.rows = mapped
        self.isLoading = false
        self.didLoad = true
        if mapped.isEmpty {
          self.statusText = "Sem dados de processos no momento. Verifique se o App Sandbox esta desativado."
        } else {
          self.statusText = ""
        }
        self.lastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: Date()))"
      }
    }
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter
  }()
}

struct ProcessTableRow: Identifiable, Equatable {
  let pid: Int32
  let name: String
  let cpuPercent: Double
  let memoryBytes: UInt64
  let diskReadBytesPerSec: Double
  let diskWriteBytesPerSec: Double
  let appName: String?
  let bundleId: String?
  let bundlePath: String?
  let executablePath: String?
  let parentPid: Int32?

  var id: Int32 {
    pid
  }

  var pidText: String {
    "\(pid)"
  }

  var parentPidText: String? {
    parentPid.map { "\($0)" }
  }

  var cpuText: String {
    if cpuPercent <= 0 {
      return "0%"
    }
    if cpuPercent < 0.01 {
      return "<0.01%"
    }
    if cpuPercent < 1 {
      return String(format: "%.2f%%", cpuPercent)
    }
    return String(format: "%.1f%%", cpuPercent)
  }

  var memoryText: String {
    Self.formatBytes(memoryBytes)
  }

  var diskText: String {
    if diskReadBytesPerSec <= 0, diskWriteBytesPerSec <= 0 {
      return "--"
    }
    let read = Self.formatRate(diskReadBytesPerSec)
    let write = Self.formatRate(diskWriteBytesPerSec)
    return "\(read) ↓ / \(write) ↑"
  }

  var displayName: String {
    appName ?? name
  }

  var appNameText: String {
    appName ?? "Sistema"
  }

  var icon: NSImage? {
    if let bundlePath {
      return NSWorkspace.shared.icon(forFile: bundlePath)
    }
    if let executablePath {
      return NSWorkspace.shared.icon(forFile: executablePath)
    }
    return nil
  }

  var revealURL: URL? {
    if let bundlePath {
      return URL(fileURLWithPath: bundlePath)
    }
    if let executablePath {
      return URL(fileURLWithPath: executablePath)
    }
    return nil
  }

  var copyValue: String? {
    bundlePath ?? executablePath
  }

  static func formatBytes(_ bytes: UInt64) -> String {
    let gigaBytes = Double(bytes) / 1_073_741_824.0
    if gigaBytes >= 1 {
      return String(format: "%.1f GB", gigaBytes)
    }
    let megaBytes = Double(bytes) / 1_048_576.0
    if megaBytes >= 1 {
      return String(format: "%.0f MB", megaBytes)
    }
    let kiloBytes = Double(bytes) / 1024.0
    return String(format: "%.0f KB", kiloBytes)
  }

  static func formatRate(_ bytesPerSec: Double) -> String {
    let kiloBytes = bytesPerSec / 1024.0
    let megaBytes = kiloBytes / 1024.0
    if megaBytes >= 1 {
      return String(format: "%.1f MB/s", megaBytes)
    }
    return String(format: "%.0f KB/s", kiloBytes)
  }
}

private struct AppIconView: View {
  let image: NSImage?

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
      } else {
        Image(systemName: "app.fill")
          .resizable()
          .scaledToFit()
          .foregroundColor(.secondary)
      }
    }
    .frame(width: 16, height: 16)
  }
}

final class ImpactViewModel: ObservableObject {
  @Published private(set) var activeRules: [ImpactRuleItem] = []
  @Published private(set) var lastUpdatedText: String = "Nunca atualizado"
  @Published private(set) var statusText: String = ""
  @Published private(set) var isLoading: Bool = false

  private let ruleStore: AlertRuleStore
  private let metricsStore: MetricsSnapshotStore
  private let processProvider: ProcessResourcesProviding
  private let sampleDelay: TimeInterval
  private var didLoad = false

  init(
    ruleStore: AlertRuleStore,
    metricsStore: MetricsSnapshotStore,
    processProvider: ProcessResourcesProviding,
    sampleDelay: TimeInterval = 1.0
  ) {
    self.ruleStore = ruleStore
    self.metricsStore = metricsStore
    self.processProvider = processProvider
    self.sampleDelay = sampleDelay
  }

  func refreshIfNeeded() {
    guard !didLoad else { return }
    refresh()
  }

  func refresh() {
    guard !isLoading else { return }
    isLoading = true
    statusText = "Coletando impacto..."

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      let rules = ruleStore.loadRules().filter(\.isEnabled)
      guard let snapshot = metricsStore.load() else {
        DispatchQueue.main.async {
          self.activeRules = []
          self.statusText = "Sem snapshot ainda. Aguarde alguns segundos."
          self.lastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: Date()))"
          self.isLoading = false
          self.didLoad = true
        }
        return
      }

      var baseItems: [ImpactRuleItem] = []
      var needsProcessData = false

      for rule in rules {
        guard let value = rule.metric.value(from: snapshot) else { continue }
        let isActive = rule.comparison.isSatisfied(value: value, threshold: rule.threshold)
        guard isActive else { continue }

        let item = ImpactRuleItem(
          id: rule.id,
          name: rule.name,
          metric: rule.metric,
          metricLabel: rule.metric.label,
          comparisonSymbol: rule.comparison.symbol,
          thresholdText: rule.metric.formatValue(rule.threshold),
          currentValueText: rule.metric.formatValue(value),
          severityLabel: rule.severity.label,
          suggestions: [],
          note: nil
        )
        baseItems.append(item)

        if [.cpuUsagePercent, .memoryUsedPercent, .diskFreePercent].contains(rule.metric) {
          needsProcessData = true
        }
      }

      var processes: [ProcessResourceSnapshot] = []
      if needsProcessData {
        _ = processProvider.readResources(limit: 0)
        Thread.sleep(forTimeInterval: sampleDelay)
        processes = processProvider.readResources(limit: 0)
      }

      let enriched = baseItems.map { item -> ImpactRuleItem in
        var item = item
        switch item.metric {
        case .cpuUsagePercent:
          item.suggestions = self.topCpuProcesses(processes)
          if item.suggestions.isEmpty {
            item.note = "Sem dados de CPU por processo."
          }
        case .memoryUsedPercent:
          item.suggestions = self.topMemoryProcesses(processes)
          if item.suggestions.isEmpty {
            item.note = "Sem dados de memoria por processo."
          }
        case .diskFreePercent:
          item.suggestions = self.topDiskProcesses(processes)
          if item.suggestions.isEmpty {
            item.note = "Sem atividade de disco por processo."
          }
        default:
          item.note = "Nao ha mapeamento por processo para esta metrica."
        }
        return item
      }

      DispatchQueue.main.async {
        self.activeRules = enriched
        self.statusText = enriched.isEmpty ? "Nenhuma regra ativa no momento." : ""
        self.lastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: Date()))"
        self.isLoading = false
        self.didLoad = true
      }
    }
  }

  private func topCpuProcesses(_ processes: [ProcessResourceSnapshot]) -> [ImpactProcessSuggestion] {
    let sorted = processes.sorted { $0.cpuPercent > $1.cpuPercent }
    return sorted.prefix(4).map { process in
      ImpactProcessSuggestion(
        title: process.appName ?? process.name,
        detail: "CPU \(formatPercent(process.cpuPercent))",
        path: process.bundlePath ?? process.executablePath
      )
    }
  }

  private func topMemoryProcesses(_ processes: [ProcessResourceSnapshot]) -> [ImpactProcessSuggestion] {
    let sorted = processes.sorted { $0.memoryBytes > $1.memoryBytes }
    return sorted.prefix(4).map { process in
      ImpactProcessSuggestion(
        title: process.appName ?? process.name,
        detail: "Mem \(ProcessTableRow.formatBytes(process.memoryBytes))",
        path: process.bundlePath ?? process.executablePath
      )
    }
  }

  private func topDiskProcesses(_ processes: [ProcessResourceSnapshot]) -> [ImpactProcessSuggestion] {
    let sorted = processes.sorted { ($0.diskReadBytesPerSec + $0.diskWriteBytesPerSec) >
      ($1.diskReadBytesPerSec + $1.diskWriteBytesPerSec)
    }
    let filtered = sorted.filter { $0.diskReadBytesPerSec > 0 || $0.diskWriteBytesPerSec > 0 }
    return filtered.prefix(4).map { process in
      ImpactProcessSuggestion(
        title: process.appName ?? process.name,
        detail: "Disco \(ProcessTableRow.formatRate(process.diskReadBytesPerSec)) ↓ / \(ProcessTableRow.formatRate(process.diskWriteBytesPerSec)) ↑",
        path: process.bundlePath ?? process.executablePath
      )
    }
  }

  private func formatPercent(_ value: Double) -> String {
    if value < 0.01, value > 0 {
      return "<0.01%"
    }
    if value < 1 {
      return String(format: "%.2f%%", value)
    }
    return String(format: "%.1f%%", value)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter
  }()
}

struct ImpactRuleItem: Identifiable, Equatable {
  let id: UUID
  let name: String
  let metric: AlertMetric
  let metricLabel: String
  let comparisonSymbol: String
  let thresholdText: String
  let currentValueText: String
  let severityLabel: String
  var suggestions: [ImpactProcessSuggestion]
  var note: String?

  var severityColor: Color {
    switch severityLabel.lowercased() {
    case "critico":
      .red
    case "aviso":
      .orange
    default:
      .blue
    }
  }
}

struct ImpactProcessSuggestion: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let detail: String
  let path: String?
}
