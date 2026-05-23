import PulseMacDomain
import SwiftUI

public struct PreferencesView: View {
  @ObservedObject private var viewModel: SettingsViewModel

  public init(viewModel: SettingsViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CardSection("Amostragem") {
          FieldRow("Intervalo") {
            Picker("", selection: $viewModel.samplingInterval) {
              ForEach(SamplingInterval.allCases, id: \.self) { interval in
                Text(interval.label).tag(interval)
              }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fieldContainer()
            .onChange(of: viewModel.samplingInterval) { _ in
              scheduleSave()
            }
          }
        }

        CardSection("Retencao") {
          FieldRow("Dias") {
            Stepper(value: $viewModel.retentionDays, in: 1 ... 60) {
              Text(String(viewModel.retentionDays))
                .frame(width: 60, alignment: .trailing)
            }
            .onChange(of: viewModel.retentionDays) { _ in
              scheduleSave()
            }
          }
        }

        CardSection("Notificacoes") {
          Toggle("Ativar notificacoes", isOn: $viewModel.notificationsEnabled)
            .onChange(of: viewModel.notificationsEnabled) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)
          if !viewModel.notificationStatusText.isEmpty {
            Text(viewModel.notificationStatusText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          if !viewModel.notificationEntitlementText.isEmpty {
            Text(viewModel.notificationEntitlementText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Button {
            viewModel.requestNotificationPermissionAndTest()
          } label: {
            Label("Testar notificacao", systemImage: "bell.badge")
          }
          .buttonStyle(.borderedProminent)
          Button {
            viewModel.openSystemNotificationSettings()
          } label: {
            Label("Abrir ajustes do macOS", systemImage: "gearshape")
          }
          .buttonStyle(.bordered)
        }

        CardSection("Nao perturbe") {
          Toggle("Ativar horario", isOn: $viewModel.doNotDisturbEnabled)
            .onChange(of: viewModel.doNotDisturbEnabled) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)

          FieldRow("Horario") {
            HStack(spacing: 8) {
              DatePicker("", selection: $viewModel.dndStartTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .fieldContainer()
              Text("ate")
                .font(.caption)
                .foregroundColor(BrandStyle.label)
              DatePicker("", selection: $viewModel.dndEndTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .fieldContainer()
            }
            .onChange(of: viewModel.dndStartTime) { _ in
              scheduleSave()
            }
            .onChange(of: viewModel.dndEndTime) { _ in
              scheduleSave()
            }
          }
        }

        CardSection("Modulos") {
          Toggle("Disco", isOn: $viewModel.showDisk)
            .onChange(of: viewModel.showDisk) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)
          Toggle("Rede", isOn: $viewModel.showNetwork)
            .onChange(of: viewModel.showNetwork) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)
          Toggle("Bateria", isOn: $viewModel.showBattery)
            .onChange(of: viewModel.showBattery) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)
          Toggle("Barra de menus", isOn: $viewModel.showMenuBar)
            .onChange(of: viewModel.showMenuBar) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)
          Toggle("Exibir no Dock", isOn: $viewModel.showDock)
            .onChange(of: viewModel.showDock) { _ in
              scheduleSave()
            }
            .toggleStyle(.switch)
        }

        CardSection("Diagnostico") {
          Button {
            viewModel.exportDiagnostics()
          } label: {
            Label("Exportar diagnostico (JSON)", systemImage: "square.and.arrow.down")
          }
          .buttonStyle(.borderedProminent)
          if !viewModel.diagnosticsStatusText.isEmpty {
            Text(viewModel.diagnosticsStatusText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Button {
            viewModel.exportQuickReport()
          } label: {
            Label("Exportar resumo (JSON)", systemImage: "doc.text")
          }
          .buttonStyle(.bordered)
          if !viewModel.quickReportStatusText.isEmpty {
            Text(viewModel.quickReportStatusText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Text("Arquivo local, sem upload.")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        CardSection("Acoes rapidas") {
          HStack(spacing: 12) {
            if viewModel.notificationsEnabled {
              Button {
                viewModel.pauseAlerts()
              } label: {
                Label("Pausar alertas", systemImage: "pause.circle")
              }
              .buttonStyle(.bordered)
            } else {
              Button {
                viewModel.resumeAlerts()
              } label: {
                Label("Retomar alertas", systemImage: "play.circle")
              }
              .buttonStyle(.borderedProminent)
            }

            Button {
              viewModel.clearAlertHistory()
            } label: {
              Label("Limpar historico", systemImage: "trash")
            }
            .buttonStyle(.bordered)

            Button {
              viewModel.openDiagnosticsFolder()
            } label: {
              Label("Abrir pasta do app", systemImage: "folder")
            }
            .buttonStyle(.bordered)
          }

          if !viewModel.quickActionsStatusText.isEmpty {
            Text(viewModel.quickActionsStatusText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        CardSection("Diagnostico avancado") {
          HStack {
            Text("Status interno")
              .font(.subheadline)
            Spacer()
            Button {
              viewModel.refreshAdvancedDiagnostics()
            } label: {
              Label("Atualizar", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
          }

          VStack(spacing: 8) {
            ForEach(viewModel.advancedDiagnosticsRows) { row in
              HStack(alignment: .top, spacing: 12) {
                Text(row.title)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(width: 160, alignment: .leading)
                Text(row.value)
                  .font(.caption)
                  .foregroundColor(.primary)
                  .textSelection(.enabled)
                Spacer()
              }
            }
          }

          if !viewModel.advancedDiagnosticsUpdatedText.isEmpty {
            Text(viewModel.advancedDiagnosticsUpdatedText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(12)
  }

  private func scheduleSave() {
    DispatchQueue.main.async {
      viewModel.save()
    }
  }
}
