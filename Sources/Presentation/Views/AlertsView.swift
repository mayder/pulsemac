import PulseMacDomain
import SwiftUI

public struct AlertsView: View {
  @ObservedObject private var viewModel: AlertsViewModel

  @State private var selectedRuleId: UUID?
  @State private var draft = AlertDraft(
    metric: .cpuUsagePercent,
    comparison: .greaterThan,
    threshold: AlertMetric.cpuUsagePercent.defaultThreshold,
    duration: 20,
    cooldown: 60,
    severity: .warning
  )
  @State private var hasLoadedInitialSelection = false
  @State private var historyQuery: String = ""
  @State private var historySeverity: HistorySeverityFilter = .all
  @State private var historyRange: HistoryRange = .last7Days
  @State private var historyOnlySelectedRule: Bool = false

  public init(viewModel: AlertsViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 12) {
          SectionHeader("Regras", subtitle: "Alertas configurados")
          Spacer()
          Button {
            viewModel.reload()
          } label: {
            Label("Atualizar", systemImage: "arrow.clockwise")
          }
          .buttonStyle(.bordered)
        }

        summaryCard

        List(selection: $selectedRuleId) {
          if viewModel.rules.isEmpty {
            Text("Nenhuma regra criada")
              .foregroundColor(.secondary)
          } else {
            ForEach(viewModel.rules) { rule in
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(rule.name)
                  Text(rule.severity.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                  get: { rule.isEnabled },
                  set: { _ in viewModel.toggle(rule: rule) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
              }
              .tag(rule.id)
            }
          }
        }
        .frame(minWidth: 240, maxWidth: 260)
        .listStyle(.inset)

        HStack(spacing: 8) {
          Button {
            startNewDraft()
          } label: {
            Label("Novo", systemImage: "plus")
          }
          .buttonStyle(.borderedProminent)

          Menu {
            Button {
              duplicateSelected()
            } label: {
              Label("Duplicar", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) {
              deleteSelected()
            } label: {
              Label("Excluir", systemImage: "trash")
            }
          } label: {
            Label("Acoes", systemImage: "ellipsis.circle")
          }
          .buttonStyle(.bordered)
        }

        Button {
          viewModel.addPresetAlerts()
        } label: {
          Label("Inserir pre-definidos", systemImage: "wand.and.stars")
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, alignment: .leading)
        Text("CPU, memoria, disco, rede, bateria, temperatura e fans.")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Divider()

      VStack(alignment: .leading, spacing: 12) {
        SectionHeader(selectedRuleId == nil ? "Novo alerta" : "Editar alerta")

        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            CardSection("Regra") {
              VStack(alignment: .leading, spacing: 10) {
                FieldRow("Metrica") {
                  Picker("", selection: $draft.metric) {
                    ForEach(AlertMetric.allCases, id: \.self) { metric in
                      Text(metric.label).tag(metric)
                    }
                  }
                  .labelsHidden()
                  .pickerStyle(.menu)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .fieldContainer()
                  .onChange(of: draft.metric) { metric in
                    draft.comparison = metric.defaultComparison
                    if !metric.range.contains(draft.threshold) {
                      draft.threshold = metric.defaultThreshold
                    }
                  }
                }

                FieldRow("Comparacao") {
                  Picker("", selection: $draft.comparison) {
                    ForEach(AlertComparison.allCases, id: \.self) { comparison in
                      Text(comparison.label).tag(comparison)
                    }
                  }
                  .labelsHidden()
                  .pickerStyle(.menu)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .fieldContainer()
                }

                FieldRow("Limite") {
                  HStack(spacing: 12) {
                    Slider(value: $draft.threshold, in: draft.metric.range, step: draft.metric.step)
                    Text(draft.metric.formatValue(draft.threshold))
                      .frame(width: 70, alignment: .trailing)
                      .foregroundColor(BrandStyle.label)
                  }
                }

                FieldRow("Duracao") {
                  HStack(spacing: 12) {
                    Slider(value: $draft.duration, in: 5 ... 300, step: 5)
                    Text("\(Int(draft.duration))s")
                      .frame(width: 70, alignment: .trailing)
                      .foregroundColor(BrandStyle.label)
                  }
                }

                FieldRow("Cooldown") {
                  HStack(spacing: 12) {
                    Slider(value: $draft.cooldown, in: 30 ... 900, step: 30)
                    Text("\(Int(draft.cooldown))s")
                      .frame(width: 70, alignment: .trailing)
                      .foregroundColor(BrandStyle.label)
                  }
                }

                FieldRow("Severidade") {
                  Picker("", selection: $draft.severity) {
                    ForEach(AlertSeverity.allCases, id: \.self) { severity in
                      Text(severity.label).tag(severity)
                    }
                  }
                  .labelsHidden()
                  .pickerStyle(.menu)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .fieldContainer()
                }

                if draft.metric.needsData {
                  Text("Se este Mac nao disponibilizar, o alerta nao dispara.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
            }

            CardSection("Acoes") {
              Button {
                viewModel.testAlert(draft: draft, ruleId: selectedRuleId)
              } label: {
                Label("Testar alerta", systemImage: "bell.badge")
              }
              .buttonStyle(.borderedProminent)
              Text("Se nao aparecer, ative Notificacoes em Ajustes e no macOS.")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            CardSection("Historico") {
              VStack(alignment: .leading, spacing: 8) {
                FieldRow("Severidade") {
                  Picker("", selection: $historySeverity) {
                    ForEach(HistorySeverityFilter.allCases, id: \.self) { filter in
                      Text(filter.label).tag(filter)
                    }
                  }
                  .labelsHidden()
                  .pickerStyle(.menu)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .fieldContainer()
                }

                FieldRow("Periodo") {
                  Picker("", selection: $historyRange) {
                    ForEach(HistoryRange.allCases, id: \.self) { range in
                      Text(range.label).tag(range)
                    }
                  }
                  .labelsHidden()
                  .pickerStyle(.menu)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .fieldContainer()
                }

                Toggle("Somente regra selecionada", isOn: $historyOnlySelectedRule)
                  .disabled(selectedRuleId == nil)
                  .toggleStyle(.switch)
              }

              Divider()

              if filteredHistory.isEmpty {
                Text("Sem eventos")
                  .foregroundColor(.secondary)
              } else {
                LazyVStack(alignment: .leading, spacing: 6) {
                  ForEach(filteredHistory) { event in
                    VStack(alignment: .leading, spacing: 2) {
                      Text(event.message)
                      Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    Divider()
                  }
                }
              }
            }
          }
          .padding(.trailing, 4)
        }

        HStack(spacing: 8) {
          Button {
            saveDraft()
          } label: {
            Label(selectedRuleId == nil ? "Criar" : "Salvar", systemImage: "checkmark.circle")
          }
          .buttonStyle(.borderedProminent)
          Button {
            resetDraftToSelection()
          } label: {
            Label("Cancelar", systemImage: "xmark.circle")
          }
          .buttonStyle(.bordered)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12)
    .tint(BrandStyle.accent)
    .searchable(text: $historyQuery, placement: .toolbar, prompt: "Buscar no historico")
    .onAppear {
      loadInitialSelection()
    }
    .onChange(of: selectedRuleId) { _ in
      resetDraftToSelection()
    }
    .onChange(of: viewModel.rules) { _ in
      ensureSelectionIsValid()
    }
  }

  private var summaryCard: some View {
    GlassCard {
      let total = viewModel.rules.count
      let active = viewModel.rules.filter(\.isEnabled).count
      let inactive = total - active
      let recentEvents = viewModel.history.filter { event in
        event.timestamp >= Date().addingTimeInterval(-Self.day)
      }.count

      let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
      ]
      LazyVGrid(columns: columns, spacing: 12) {
        InfoPill("Regras", value: "\(total)")
        InfoPill("Ativas", value: "\(active)")
        InfoPill("Desativadas", value: "\(inactive)")
        InfoPill("Eventos 24h", value: "\(recentEvents)")
      }

      if let lastEvent = viewModel.history.sorted(by: { $0.timestamp > $1.timestamp }).first {
        Divider()
        VStack(alignment: .leading, spacing: 4) {
          Text("Ultimo evento")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(lastEvent.message)
            .lineLimit(2)
          Text(Self.eventFormatter.string(from: lastEvent.timestamp))
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
  }

  private var filteredHistory: [AlertEvent] {
    let now = Date()
    let query = historyQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return viewModel.history
      .sorted { $0.timestamp > $1.timestamp }
      .filter { event in
        if historyOnlySelectedRule, let selectedRuleId {
          if event.ruleId != selectedRuleId { return false }
        }
        if let severity = historySeverity.severity {
          if event.severity != severity { return false }
        }
        if let cutoff = historyRange.cutoffDate(from: now) {
          if event.timestamp < cutoff { return false }
        }
        if !query.isEmpty {
          if !event.message.lowercased().contains(query) { return false }
        }
        return true
      }
  }

  private func loadInitialSelection() {
    guard !hasLoadedInitialSelection else { return }
    hasLoadedInitialSelection = true
    if let first = viewModel.rules.first {
      selectedRuleId = first.id
      draft = draft(from: first)
    }
  }

  private func ensureSelectionIsValid() {
    if let selectedRuleId, viewModel.rules.contains(where: { $0.id == selectedRuleId }) {
      return
    }
    if let first = viewModel.rules.first {
      selectedRuleId = first.id
      draft = draft(from: first)
    } else {
      selectedRuleId = nil
      startNewDraft()
    }
  }

  private func resetDraftToSelection() {
    if let selectedRuleId, let rule = viewModel.rules.first(where: { $0.id == selectedRuleId }) {
      draft = draft(from: rule)
    } else {
      startNewDraft()
    }
  }

  private func startNewDraft() {
    selectedRuleId = nil
    draft = AlertDraft(
      metric: .cpuUsagePercent,
      comparison: .greaterThan,
      threshold: AlertMetric.cpuUsagePercent.defaultThreshold,
      duration: 20,
      cooldown: 60,
      severity: .warning
    )
  }

  private func saveDraft() {
    if let selectedRuleId {
      viewModel.updateAlert(ruleId: selectedRuleId, draft: draft)
    } else {
      let rule = viewModel.addAlert(draft: draft)
      selectedRuleId = rule.id
    }
  }

  private func duplicateSelected() {
    guard let currentId = selectedRuleId,
          let rule = viewModel.duplicateAlert(ruleId: currentId) else { return }
    selectedRuleId = rule.id
    draft = draft(from: rule)
  }

  private func deleteSelected() {
    guard let selectedRuleId else { return }
    viewModel.deleteAlert(ruleId: selectedRuleId)
  }

  private func draft(from rule: AlertRule) -> AlertDraft {
    AlertDraft(
      metric: rule.metric,
      comparison: rule.comparison,
      threshold: rule.threshold,
      duration: rule.duration,
      cooldown: rule.cooldown,
      severity: rule.severity
    )
  }

  private static let day: TimeInterval = 60 * 60 * 24
  private static let eventFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
  }()
}

private extension AlertMetric {
  var needsData: Bool {
    switch self {
    case .cpuTempC,
         .gpuTempC,
         .fanMaxRPM,
         .diskFreePercent,
         .networkDownloadKBps,
         .networkUploadKBps,
         .batteryChargePercent:
      true
    case .cpuUsagePercent, .memoryUsedPercent:
      false
    }
  }
}

private enum HistoryRange: String, CaseIterable, Identifiable {
  case last24Hours
  case last7Days
  case last30Days
  case all

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .last24Hours:
      "24h"
    case .last7Days:
      "7 dias"
    case .last30Days:
      "30 dias"
    case .all:
      "Tudo"
    }
  }

  func cutoffDate(from now: Date) -> Date? {
    switch self {
    case .last24Hours:
      now.addingTimeInterval(-Self.day)
    case .last7Days:
      now.addingTimeInterval(-(Self.day * 7))
    case .last30Days:
      now.addingTimeInterval(-(Self.day * 30))
    case .all:
      nil
    }
  }

  private static let day: TimeInterval = 60 * 60 * 24
}

private enum HistorySeverityFilter: String, CaseIterable, Identifiable {
  case all
  case info
  case warning
  case critical

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .all:
      "Todas"
    case .info:
      "Info"
    case .warning:
      "Warning"
    case .critical:
      "Critico"
    }
  }

  var severity: AlertSeverity? {
    switch self {
    case .all:
      nil
    case .info:
      .info
    case .warning:
      .warning
    case .critical:
      .critical
    }
  }
}
