import SwiftUI

struct WidgetsPreviewView: View {
  @ObservedObject var viewModel: MetricsDashboardViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        GlassCard {
          HStack(alignment: .center) {
            SectionHeader("Widgets", subtitle: "Pre-visualizacao dos tamanhos disponiveis.")
            Spacer()
            if !viewModel.lastUpdatedText.isEmpty {
              Text(viewModel.lastUpdatedText)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }

        CardSection("Preview") {
          HStack(alignment: .top, spacing: 16) {
            widgetCard(CGSize(width: 150, height: 150)) {
              smallContent
            }

            widgetCard(CGSize(width: 300, height: 150)) {
              mediumContent
            }

            widgetCard(CGSize(width: 300, height: 200)) {
              largeContent
            }
          }
        }

        CardSection("Detalhes") {
          VStack(alignment: .leading, spacing: 6) {
            Text("Widgets nao atualizam em tempo real.")
            Text("Atualizacao aproximada: a cada 5 minutos.")
              .foregroundColor(.secondary)
          }
          .font(.callout)
        }
      }
      .padding(16)
    }
  }

  private var smallContent: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("CPU")
        .font(.caption)
        .foregroundColor(.secondary)
      Text(cpuText)
        .font(.title3)
      Text("RAM")
        .font(.caption)
        .foregroundColor(.secondary)
      Text(memoryText)
        .font(.title3)
    }
  }

  private var mediumContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("CPU")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(cpuText)
        }
        Spacer()
        VStack(alignment: .leading, spacing: 4) {
          Text("RAM")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(memoryText)
        }
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("Disco livre")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(diskText)
      }
    }
  }

  private var largeContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("PulseMac")
        .font(.headline)
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("CPU")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(cpuText)
        }
        Spacer()
        VStack(alignment: .leading, spacing: 4) {
          Text("RAM")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(memoryText)
        }
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("Disco livre")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(diskText)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("Rede")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(networkText)
      }
    }
  }

  private func widgetCard(
    _ size: CGSize,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      content()
    }
    .padding(12)
    .frame(width: size.width, height: size.height, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(BrandStyle.surfaceAlt)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(BrandStyle.border.opacity(0.6), lineWidth: 1)
    )
  }

  private var cpuText: String {
    String(format: "%.0f%%", viewModel.cpuPercent)
  }

  private var memoryText: String {
    if let used = viewModel.memoryUsedGB {
      return String(format: "%.1f GB", used)
    }
    return "--"
  }

  private var diskText: String {
    if let free = viewModel.diskFreeGB {
      return String(format: "%.1f GB", free)
    }
    return "--"
  }

  private var networkText: String {
    guard let download = viewModel.networkDownloadKBps,
          let upload = viewModel.networkUploadKBps
    else { return "--" }
    let downloadText = formatRate(download)
    let uploadText = formatRate(upload)
    return "\(downloadText) ↓ / \(uploadText) ↑"
  }

  private func formatRate(_ kiloBytesPerSec: Double) -> String {
    let megaBytes = kiloBytesPerSec / 1024.0
    if megaBytes >= 1 {
      return String(format: "%.1f MB/s", megaBytes)
    }
    return String(format: "%.0f KB/s", kiloBytesPerSec)
  }
}
