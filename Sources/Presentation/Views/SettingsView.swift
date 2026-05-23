import AppKit
import Foundation
import PulseMacData
import PulseMacDomain
import SwiftUI

public struct SettingsView: View {
  @ObservedObject private var settingsViewModel: SettingsViewModel
  @ObservedObject private var alertsViewModel: AlertsViewModel
  @ObservedObject private var metricsViewModel: MetricsDashboardViewModel
  @ObservedObject private var processesViewModel: ProcessesViewModel
  @ObservedObject private var impactViewModel: ImpactViewModel
  @ObservedObject private var logsViewModel: SystemLogsViewModel
  @ObservedObject private var navigation: SettingsNavigationModel

  init(
    settingsViewModel: SettingsViewModel,
    alertsViewModel: AlertsViewModel,
    metricsViewModel: MetricsDashboardViewModel,
    processesViewModel: ProcessesViewModel,
    impactViewModel: ImpactViewModel,
    logsViewModel: SystemLogsViewModel,
    navigation: SettingsNavigationModel
  ) {
    self.settingsViewModel = settingsViewModel
    self.alertsViewModel = alertsViewModel
    self.metricsViewModel = metricsViewModel
    self.processesViewModel = processesViewModel
    self.impactViewModel = impactViewModel
    self.logsViewModel = logsViewModel
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
        case .logs:
          SystemLogsView(viewModel: logsViewModel)
        case .widgets:
          WidgetsPreviewView(viewModel: metricsViewModel)
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
        } else if navigation.selectedTab == .logs {
          Button {
            logsViewModel.refresh()
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
  private let appInfo = DiagnosticsAppInfo.current()
  private let systemInfo = DiagnosticsSystemInfo.current()

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

        CardSection("Aplicativo") {
          InfoPill("Bundle", value: appInfo.bundleId)
          InfoPill("Versao", value: appInfo.version)
          InfoPill("Build", value: appInfo.build)
        }

        CardSection("Sistema") {
          InfoPill("macOS", value: systemInfo.osVersion)
          InfoPill("Modelo", value: systemInfo.modelIdentifier ?? "--")
          InfoPill("CPU", value: systemInfo.cpuBrand ?? "--")
          InfoPill("Nucleos", value: "\(systemInfo.cpuCount)")
          InfoPill("Memoria", value: ProcessTableRow.formatBytes(systemInfo.memoryBytes))
          InfoPill("Locale", value: systemInfo.locale)
          InfoPill("TimeZone", value: systemInfo.timeZone)
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
      viewModel.refreshIfNeeded()
    }
  }
}

private struct ProcessesView: View {
  private enum DisplayMode: String, CaseIterable, Identifiable {
    case processes
    case apps
    case favorites

    var id: String {
      rawValue
    }

    var title: String {
      switch self {
      case .processes:
        "Processos"
      case .apps:
        "Apps"
      case .favorites:
        "Favoritos"
      }
    }
  }

  @ObservedObject var viewModel: ProcessesViewModel
  @State private var sortOrder: [KeyPathComparator<ProcessTableRow>] = [
    .init(\.cpuPercent, order: .reverse)
  ]
  @State private var appSortOrder: [KeyPathComparator<AppAggregateRow>] = [
    .init(\.cpuPercent, order: .reverse)
  ]
  @State private var favoriteSortOrder: [KeyPathComparator<FavoriteProcessRow>] = [
    .init(\.cpuPercent, order: .reverse)
  ]
  @State private var searchText: String = ""
  @State private var selection: ProcessTableRow.ID?
  @State private var appSelection: AppAggregateRow.ID?
  @State private var favoriteSelection: FavoriteProcessRow.ID?
  @State private var displayMode: DisplayMode = .processes

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerCard
      summaryCard
      contentRow

      if !viewModel.statusText.isEmpty {
        Text(viewModel.statusText)
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
      }
    }
    .padding(16)
    .onAppear {
      viewModel.refreshIfNeeded()
    }
    .onChange(of: viewModel.rows) { _ in
      if displayMode == .processes {
        ensureSelection()
      } else if displayMode == .apps {
        ensureAppSelection()
      } else {
        ensureFavoriteSelection()
      }
    }
    .onChange(of: viewModel.favoriteRows) { _ in
      if displayMode == .favorites {
        ensureFavoriteSelection()
      }
    }
    .onChange(of: displayMode) { _ in
      if displayMode == .processes {
        ensureSelection()
      } else if displayMode == .apps {
        ensureAppSelection()
      } else {
        ensureFavoriteSelection()
      }
    }
    .searchable(text: $searchText, placement: .toolbar, prompt: "Buscar processo")
  }

  private var headerCard: some View {
    GlassCard {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          SectionHeader("Processos", subtitle: "Coleta sob demanda. Atualize quando precisar.")
        }
        Spacer()
        if !searchText.isEmpty {
          Button {
            searchText = ""
          } label: {
            Label("Limpar busca", systemImage: "xmark.circle")
          }
          .buttonStyle(.bordered)
        }
        Button {
          viewModel.refresh(force: true)
        } label: {
          Label("Atualizar", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.borderedProminent)
        Picker("Modo", selection: $displayMode) {
          ForEach(DisplayMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
        if viewModel.isLoading {
          ProgressView()
            .controlSize(.small)
        }
      }
    }
  }

  private var summaryCard: some View {
    GlassCard {
      let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
      ]
      LazyVGrid(columns: columns, spacing: 12) {
        InfoPill("Processos", value: "\(viewModel.rows.count)")
        InfoPill("Apps", value: "\(viewModel.appRows.count)")
        InfoPill("Favoritos", value: "\(viewModel.favoriteRows.count)")
        InfoPill("Favoritos ativos", value: "\(viewModel.favoriteRows.filter(\.isRunning).count)")
      }
    }
  }

  private var contentRow: some View {
    HStack(alignment: .top, spacing: 12) {
      listCard
      detailsCard
    }
  }

  private var listCard: some View {
    CardSection("Lista") {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Spacer()
          Text(viewModel.lastUpdatedText)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        listTable
          .frame(minHeight: 360)
      }
    }
  }

  @ViewBuilder private var listTable: some View {
    if displayMode == .processes {
      processesTable
    } else if displayMode == .apps {
      appsTable
    } else {
      favoritesTable
    }
  }

  private var processesTable: some View {
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
  }

  private var appsTable: some View {
    Table(sortedAppRows, selection: $appSelection, sortOrder: $appSortOrder) {
      TableColumn("App", value: \.appName) { row in
        HStack(spacing: 8) {
          AppIconView(image: row.icon)
          Text(row.appName)
        }
      }
      TableColumn("Processos", value: \.processCount) { row in
        Text(row.processesText)
          .foregroundColor(.secondary)
      }
      TableColumn("CPU %", value: \.cpuPercent) { row in
        Text(row.cpuText)
      }
      TableColumn("Memoria", value: \.memoryBytes) { row in
        Text(row.memoryText)
      }
      TableColumn("Disco (R/W)", value: \.diskTotalBytesPerSec) { row in
        Text(row.diskText)
          .foregroundColor(.secondary)
      }
    }
  }

  private var favoritesTable: some View {
    Table(sortedFavoriteRows, selection: $favoriteSelection, sortOrder: $favoriteSortOrder) {
      TableColumn("Favorito", value: \.name) { row in
        HStack(spacing: 8) {
          AppIconView(image: row.icon)
          VStack(alignment: .leading, spacing: 2) {
            Text(row.displayName)
            if let appName = row.appName {
              Text(appName)
                .font(.caption2)
                .foregroundColor(.secondary)
            }
          }
        }
      }
      TableColumn("Status", value: \.statusLabel) { row in
        Text(row.statusLabel)
          .foregroundColor(row.isRunning ? .secondary : .secondary)
      }
      TableColumn("CPU %", value: \.cpuPercent) { row in
        Text(row.cpuText)
      }
      TableColumn("Memoria", value: \.memoryBytes) { row in
        Text(row.memoryText)
      }
      TableColumn("Disco (R/W)", value: \.diskTotalBytesPerSec) { row in
        Text(row.diskText)
          .foregroundColor(.secondary)
      }
      TableColumn("Alertas") { row in
        Toggle("", isOn: Binding(get: { row.alertEnabled }, set: { enabled in
          viewModel.updateFavoriteAlert(row.id, enabled: enabled)
        }))
        .labelsHidden()
      }
      .width(80)
    }
  }

  private var detailsCard: some View {
    CardSection("Detalhes") {
      detailsContent
    }
    .frame(minWidth: 260, maxWidth: 320)
  }

  @ViewBuilder private var detailsContent: some View {
    if displayMode == .processes {
      if let selected = selectedRow {
        processDetails(selected)
      } else {
        Text("Selecione um processo para ver detalhes.")
          .foregroundColor(.secondary)
      }
    } else if displayMode == .apps {
      if let selected = selectedAppRow {
        appDetails(selected)
      } else {
        Text("Selecione um app para ver detalhes.")
          .foregroundColor(.secondary)
      }
    } else if let selected = selectedFavoriteRow {
      favoriteDetails(selected)
    } else {
      Text("Selecione um favorito para ver detalhes.")
        .foregroundColor(.secondary)
    }
  }

  private func processDetails(_ selected: ProcessTableRow) -> some View {
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
        Button {
          viewModel.toggleFavorite(process: selected)
        } label: {
          Label(viewModel.isFavorite(process: selected) ? "Remover favorito" : "Favoritar", systemImage: "star")
        }
        .buttonStyle(.bordered)
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
  }

  private func appDetails(_ selected: AppAggregateRow) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(selected.appName)
        .font(.headline)
      detailRow("Processos", selected.processesText)
      if let bundleId = selected.bundleId {
        detailRow("Bundle ID", bundleId)
      }
      if let bundlePath = selected.bundlePath {
        detailRow("Bundle", bundlePath)
      }
      if let execPath = selected.executablePath {
        detailRow("Executavel", execPath)
      }

      HStack(spacing: 12) {
        Button {
          viewModel.toggleFavorite(app: selected)
        } label: {
          Label(viewModel.isFavorite(app: selected) ? "Remover favorito" : "Favoritar", systemImage: "star")
        }
        .buttonStyle(.bordered)
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
  }

  private func favoriteDetails(_ selected: FavoriteProcessRow) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(selected.displayName)
        .font(.headline)
      detailRow("Status", selected.statusLabel)
      if let appName = selected.appName {
        detailRow("App", appName)
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

      HStack(spacing: 12) {
        Button {
          viewModel.removeFavorite(id: selected.id)
        } label: {
          Label("Remover favorito", systemImage: "star.slash")
        }
        .buttonStyle(.bordered)

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

  private var filteredAppRows: [AppAggregateRow] {
    guard !searchText.isEmpty else { return viewModel.appRows }
    return viewModel.appRows.filter { row in
      row.appName.localizedCaseInsensitiveContains(searchText)
        || (row.bundleId?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
  }

  private var sortedAppRows: [AppAggregateRow] {
    filteredAppRows.sorted(using: appSortOrder)
  }

  private var selectedAppRow: AppAggregateRow? {
    guard let appSelection else { return nil }
    return viewModel.appRows.first(where: { $0.id == appSelection })
  }

  private var filteredFavoriteRows: [FavoriteProcessRow] {
    guard !searchText.isEmpty else { return viewModel.favoriteRows }
    return viewModel.favoriteRows.filter { row in
      row.displayName.localizedCaseInsensitiveContains(searchText)
        || (row.appName?.localizedCaseInsensitiveContains(searchText) ?? false)
        || (row.bundleId?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
  }

  private var sortedFavoriteRows: [FavoriteProcessRow] {
    filteredFavoriteRows.sorted(using: favoriteSortOrder)
  }

  private var selectedFavoriteRow: FavoriteProcessRow? {
    guard let favoriteSelection else { return nil }
    return viewModel.favoriteRows.first(where: { $0.id == favoriteSelection })
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

  private func ensureAppSelection() {
    guard !viewModel.appRows.isEmpty else {
      appSelection = nil
      return
    }
    if let appSelection, viewModel.appRows.contains(where: { $0.id == appSelection }) {
      return
    }
    appSelection = viewModel.appRows.first?.id
  }

  private func ensureFavoriteSelection() {
    guard !viewModel.favoriteRows.isEmpty else {
      favoriteSelection = nil
      return
    }
    if let favoriteSelection, viewModel.favoriteRows.contains(where: { $0.id == favoriteSelection }) {
      return
    }
    favoriteSelection = viewModel.favoriteRows.first?.id
  }
}

private struct SystemLogsView: View {
  @ObservedObject var viewModel: SystemLogsViewModel
  @State private var selectedEntryId: UUID?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        headerCard
        controlsCard
        logsCard

        if !viewModel.statusText.isEmpty {
          Text(viewModel.statusText)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        if !viewModel.lastUpdatedText.isEmpty {
          Text(viewModel.lastUpdatedText)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .padding(16)
    }
    .searchable(text: $viewModel.query, placement: .toolbar, prompt: "Buscar nos logs")
    .onChange(of: viewModel.selectedRange) { _ in
      viewModel.resetAndRefresh()
    }
  }

  private var headerCard: some View {
    GlassCard {
      HStack {
        SectionHeader("Logs do sistema", subtitle: "Coleta sob demanda. Use filtros para reduzir ruido.")
        Spacer()
        if viewModel.isLoading {
          ProgressView()
            .controlSize(.small)
        }
      }
    }
  }

  private var controlsCard: some View {
    GlassCard {
      HStack(spacing: 12) {
        Picker("Periodo", selection: $viewModel.selectedRange) {
          ForEach(LogTimeRange.allCases) { range in
            Text(range.label).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)

        Picker("Nivel", selection: $viewModel.selectedLevel) {
          ForEach(SystemLogLevelFilter.allCases) { level in
            Text(level.label).tag(level)
          }
        }
        .frame(width: 160)

        Spacer()

        Button {
          viewModel.refresh()
        } label: {
          Label("Atualizar", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.borderedProminent)

        Button {
          viewModel.loadMore()
        } label: {
          Label("Carregar mais", systemImage: "plus")
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private var logsCard: some View {
    CardSection("Eventos") {
      VStack(alignment: .leading, spacing: 8) {
        if viewModel.filteredEntries.isEmpty {
          Text("Sem logs para o periodo selecionado.")
            .font(.caption)
            .foregroundColor(.secondary)
        } else {
          Table(viewModel.filteredEntries, selection: $selectedEntryId) {
            TableColumn("Hora") { entry in
              Text(Self.dateFormatter.string(from: entry.date))
                .monospacedDigit()
            }
            .width(120)
            TableColumn("Nivel") { entry in
              Text(entry.level.label)
            }
            .width(90)
            TableColumn("Processo") { entry in
              Text(entry.process ?? "--")
            }
            .width(140)
            TableColumn("Subsystema") { entry in
              Text(entry.subsystem ?? "--")
            }
            .width(160)
            TableColumn("Categoria") { entry in
              Text(entry.category ?? "--")
            }
            .width(140)
            TableColumn("Mensagem") { entry in
              Text(entry.message)
                .lineLimit(2)
            }
          }
          .frame(minHeight: 360)
        }
      }
    }
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}

final class ProcessesViewModel: ObservableObject {
  @Published private(set) var rows: [ProcessTableRow] = []
  @Published private(set) var appRows: [AppAggregateRow] = []
  @Published private(set) var favoriteRows: [FavoriteProcessRow] = []
  @Published private(set) var lastUpdatedText: String = "Nunca atualizado"
  @Published private(set) var statusText: String = ""
  @Published private(set) var isLoading: Bool = false

  private let provider: ProcessResourcesProviding
  private let favoritesStore: FavoritesStoring
  private var favorites: [ProcessFavorite]
  private let limit: Int
  private let sampleDelay: TimeInterval
  private var didLoad: Bool = false

  init(
    provider: ProcessResourcesProviding,
    favoritesStore: FavoritesStoring,
    limit: Int = 0,
    sampleDelay: TimeInterval = 1.0
  ) {
    self.provider = provider
    self.favoritesStore = favoritesStore
    self.limit = limit
    self.sampleDelay = sampleDelay
    favorites = favoritesStore.load()
    favoriteRows = Self.buildFavorites(from: favorites, rows: [])
  }

  func refreshIfNeeded() {
    guard !didLoad else { return }
    DispatchQueue.main.async { [weak self] in
      self?.refresh(force: true)
    }
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
        self.appRows = Self.aggregateApps(from: mapped)
        self.favoriteRows = Self.buildFavorites(from: self.favorites, rows: mapped)
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

  func toggleFavorite(process: ProcessTableRow) {
    let favoriteId = process.favoriteId
    if let index = favorites.firstIndex(where: { $0.id == favoriteId }) {
      favorites.remove(at: index)
    } else {
      favorites.append(process.toFavorite(alertEnabled: false))
    }
    persistFavorites()
  }

  func toggleFavorite(app: AppAggregateRow) {
    let favoriteId = app.favoriteId
    if let index = favorites.firstIndex(where: { $0.id == favoriteId }) {
      favorites.remove(at: index)
    } else {
      favorites.append(app.toFavorite(alertEnabled: false))
    }
    persistFavorites()
  }

  func removeFavorite(id: String) {
    favorites.removeAll { $0.id == id }
    persistFavorites()
  }

  func updateFavoriteAlert(_ id: String, enabled: Bool) {
    guard let index = favorites.firstIndex(where: { $0.id == id }) else { return }
    favorites[index].alertEnabled = enabled
    persistFavorites()
  }

  func isFavorite(process: ProcessTableRow) -> Bool {
    favorites.contains(where: { $0.id == process.favoriteId })
  }

  func isFavorite(app: AppAggregateRow) -> Bool {
    favorites.contains(where: { $0.id == app.favoriteId })
  }

  private func persistFavorites() {
    favoritesStore.save(favorites)
    favoriteRows = Self.buildFavorites(from: favorites, rows: rows)
  }

  private static func aggregateApps(from rows: [ProcessTableRow]) -> [AppAggregateRow] {
    let grouped = Dictionary(grouping: rows) { row -> String in
      if let bundleId = row.bundleId {
        return bundleId
      }
      if let bundlePath = row.bundlePath {
        return bundlePath
      }
      if let execPath = row.executablePath {
        return execPath
      }
      return "system:\(row.name)"
    }

    return grouped.map { key, rows in
      let appName = rows.compactMap(\.appName).first ?? rows.first?.displayName ?? "Sistema"
      let bundleId = rows.compactMap(\.bundleId).first
      let bundlePath = rows.compactMap(\.bundlePath).first
      let executablePath = rows.compactMap(\.executablePath).first
      let cpu = rows.reduce(0) { $0 + $1.cpuPercent }
      let memory = rows.reduce(UInt64(0)) { $0 + $1.memoryBytes }
      let read = rows.reduce(0) { $0 + $1.diskReadBytesPerSec }
      let write = rows.reduce(0) { $0 + $1.diskWriteBytesPerSec }
      return AppAggregateRow(
        id: key,
        appName: appName,
        processCount: rows.count,
        cpuPercent: cpu,
        memoryBytes: memory,
        diskReadBytesPerSec: read,
        diskWriteBytesPerSec: write,
        bundleId: bundleId,
        bundlePath: bundlePath,
        executablePath: executablePath
      )
    }
  }

  private static func buildFavorites(from favorites: [ProcessFavorite], rows: [ProcessTableRow]) -> [FavoriteProcessRow] {
    let map = Dictionary(uniqueKeysWithValues: rows.map { ($0.favoriteId, $0) })
    return favorites.map { favorite in
      if let row = map[favorite.id] {
        return FavoriteProcessRow(
          id: favorite.id,
          name: row.name,
          appName: row.appName ?? favorite.appName,
          bundleId: row.bundleId ?? favorite.bundleId,
          bundlePath: row.bundlePath ?? favorite.bundlePath,
          executablePath: row.executablePath ?? favorite.executablePath,
          cpuPercent: row.cpuPercent,
          memoryBytes: row.memoryBytes,
          diskReadBytesPerSec: row.diskReadBytesPerSec,
          diskWriteBytesPerSec: row.diskWriteBytesPerSec,
          hasMetrics: true,
          isRunning: true,
          alertEnabled: favorite.alertEnabled
        )
      }
      return FavoriteProcessRow(
        id: favorite.id,
        name: favorite.name,
        appName: favorite.appName,
        bundleId: favorite.bundleId,
        bundlePath: favorite.bundlePath,
        executablePath: favorite.executablePath,
        cpuPercent: 0,
        memoryBytes: 0,
        diskReadBytesPerSec: 0,
        diskWriteBytesPerSec: 0,
        hasMetrics: false,
        isRunning: false,
        alertEnabled: favorite.alertEnabled
      )
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

  var favoriteId: String {
    if let bundleId {
      return "bundle:\(bundleId)"
    }
    if let bundlePath {
      return "bundlePath:\(bundlePath)"
    }
    if let executablePath {
      return "exec:\(executablePath)"
    }
    return "proc:\(name)"
  }

  func toFavorite(alertEnabled: Bool) -> ProcessFavorite {
    ProcessFavorite(
      id: favoriteId,
      name: name,
      appName: appName,
      bundleId: bundleId,
      bundlePath: bundlePath,
      executablePath: executablePath,
      alertEnabled: alertEnabled
    )
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

struct AppAggregateRow: Identifiable, Equatable {
  let id: String
  let appName: String
  let processCount: Int
  let cpuPercent: Double
  let memoryBytes: UInt64
  let diskReadBytesPerSec: Double
  let diskWriteBytesPerSec: Double
  let bundleId: String?
  let bundlePath: String?
  let executablePath: String?

  var processesText: String {
    "\(processCount)"
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
    ProcessTableRow.formatBytes(memoryBytes)
  }

  var diskText: String {
    if diskReadBytesPerSec <= 0, diskWriteBytesPerSec <= 0 {
      return "--"
    }
    let read = ProcessTableRow.formatRate(diskReadBytesPerSec)
    let write = ProcessTableRow.formatRate(diskWriteBytesPerSec)
    return "\(read) ↓ / \(write) ↑"
  }

  var diskTotalBytesPerSec: Double {
    diskReadBytesPerSec + diskWriteBytesPerSec
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

  var favoriteId: String {
    if let bundleId {
      return "bundle:\(bundleId)"
    }
    if let bundlePath {
      return "bundlePath:\(bundlePath)"
    }
    if let executablePath {
      return "exec:\(executablePath)"
    }
    return "app:\(appName)"
  }

  func toFavorite(alertEnabled: Bool) -> ProcessFavorite {
    ProcessFavorite(
      id: favoriteId,
      name: appName,
      appName: appName,
      bundleId: bundleId,
      bundlePath: bundlePath,
      executablePath: executablePath,
      alertEnabled: alertEnabled
    )
  }
}

struct FavoriteProcessRow: Identifiable, Equatable {
  let id: String
  let name: String
  let appName: String?
  let bundleId: String?
  let bundlePath: String?
  let executablePath: String?
  let cpuPercent: Double
  let memoryBytes: UInt64
  let diskReadBytesPerSec: Double
  let diskWriteBytesPerSec: Double
  let hasMetrics: Bool
  let isRunning: Bool
  let alertEnabled: Bool

  var displayName: String {
    appName ?? name
  }

  var statusLabel: String {
    isRunning ? "Ativo" : "Inativo"
  }

  var cpuText: String {
    guard hasMetrics else { return "--" }
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
    guard hasMetrics else { return "--" }
    return ProcessTableRow.formatBytes(memoryBytes)
  }

  var diskText: String {
    guard hasMetrics else { return "--" }
    if diskReadBytesPerSec <= 0, diskWriteBytesPerSec <= 0 {
      return "--"
    }
    return "\(ProcessTableRow.formatRate(diskReadBytesPerSec)) ↓ / \(ProcessTableRow.formatRate(diskWriteBytesPerSec)) ↑"
  }

  var diskTotalBytesPerSec: Double {
    diskReadBytesPerSec + diskWriteBytesPerSec
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
    DispatchQueue.main.async { [weak self] in
      self?.refresh()
    }
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

enum SystemLogLevelFilter: String, CaseIterable, Identifiable {
  case all
  case errorFault
  case error
  case fault
  case notice
  case info
  case debug

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .all:
      "Todos"
    case .errorFault:
      "Erro/Falha"
    case .error:
      "Erro"
    case .fault:
      "Falha"
    case .notice:
      "Notice"
    case .info:
      "Info"
    case .debug:
      "Debug"
    }
  }

  func matches(_ level: SystemLogLevel) -> Bool {
    switch self {
    case .all:
      true
    case .errorFault:
      level == .error || level == .fault
    case .error:
      level == .error
    case .fault:
      level == .fault
    case .notice:
      level == .notice
    case .info:
      level == .info
    case .debug:
      level == .debug
    }
  }
}

enum LogTimeRange: String, CaseIterable, Identifiable {
  case fifteenMinutes
  case oneHour
  case sixHours
  case oneDay

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .fifteenMinutes:
      "15m"
    case .oneHour:
      "1h"
    case .sixHours:
      "6h"
    case .oneDay:
      "24h"
    }
  }

  var seconds: TimeInterval {
    switch self {
    case .fifteenMinutes:
      15 * 60
    case .oneHour:
      60 * 60
    case .sixHours:
      6 * 60 * 60
    case .oneDay:
      24 * 60 * 60
    }
  }

  func sinceDate() -> Date {
    Date().addingTimeInterval(-seconds)
  }
}

final class SystemLogsViewModel: ObservableObject {
  @Published private(set) var entries: [SystemLogEntry] = []
  @Published private(set) var lastUpdatedText: String = ""
  @Published private(set) var statusText: String = "Clique em Atualizar para ler os logs."
  @Published private(set) var isLoading: Bool = false
  @Published var query: String = ""
  @Published var selectedLevel: SystemLogLevelFilter = .errorFault
  @Published var selectedRange: LogTimeRange = .oneHour

  private let provider: SystemLogProviding
  private var limit: Int = 200

  init(provider: SystemLogProviding) {
    self.provider = provider
  }

  func refresh() {
    guard !isLoading else { return }
    isLoading = true
    statusText = "Coletando logs..."
    let since = selectedRange.sinceDate()
    let currentLimit = limit

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      let items = provider.readEntries(since: since, limit: currentLimit)
      let sorted = items.sorted { $0.date > $1.date }
      DispatchQueue.main.async {
        self.entries = sorted
        self.lastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: Date()))"
        self.statusText = sorted.isEmpty ? "Sem logs para o periodo selecionado." : ""
        self.isLoading = false
      }
    }
  }

  func resetAndRefresh() {
    limit = 200
    refresh()
  }

  func loadMore() {
    limit += 200
    refresh()
  }

  var filteredEntries: [SystemLogEntry] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return entries.filter { entry in
      guard selectedLevel.matches(entry.level) else { return false }
      guard !trimmed.isEmpty else { return true }
      if entry.message.lowercased().contains(trimmed) { return true }
      if entry.process?.lowercased().contains(trimmed) == true { return true }
      if entry.subsystem?.lowercased().contains(trimmed) == true { return true }
      if entry.category?.lowercased().contains(trimmed) == true { return true }
      return false
    }
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter
  }()
}
