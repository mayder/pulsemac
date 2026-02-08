import SwiftUI

public struct MenuBarPopoverView: View {
  @ObservedObject private var viewModel: MetricsDashboardViewModel
  private let onOpenAlerts: () -> Void
  private let onOpenSettings: () -> Void

  public init(
    viewModel: MetricsDashboardViewModel,
    onOpenAlerts: @escaping () -> Void,
    onOpenSettings: @escaping () -> Void
  ) {
    self.viewModel = viewModel
    self.onOpenAlerts = onOpenAlerts
    self.onOpenSettings = onOpenSettings
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image("BrandLogo")
          .resizable()
          .renderingMode(.original)
          .scaledToFit()
          .frame(height: 20)
        Spacer()
      }
      Divider()
      VStack(alignment: .leading, spacing: 4) {
        Text(viewModel.cpuText)
        Text(viewModel.memoryText)
        Text(viewModel.diskText)
        Text(viewModel.networkText)
        Text(viewModel.batteryText)
        if viewModel.hasThermalData {
          Text(viewModel.thermalText)
        }
        if viewModel.hasFanData {
          Text(viewModel.fansText)
        }
        Text(viewModel.lastUpdatedText)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      Divider()
      HStack(spacing: 8) {
        Button("Alertas") {
          onOpenAlerts()
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .frame(maxWidth: .infinity)
        Button("Ajustes") {
          onOpenSettings()
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
      }
    }
    .padding(12)
    .frame(width: 260)
  }
}
