import PulseMacData
import PulseMacDomain
import SwiftUI
import WidgetKit

struct MetricsEntry: TimelineEntry {
  let date: Date
  let snapshot: MetricSnapshot?
}

struct MetricsProvider: TimelineProvider {
  private let store = AppGroupMetricsStore(suiteName: "group.com.pulsemac.shared")

  func placeholder(in context: Context) -> MetricsEntry {
    MetricsEntry(date: Date(), snapshot: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (MetricsEntry) -> Void) {
    completion(MetricsEntry(date: Date(), snapshot: store.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MetricsEntry>) -> Void) {
    let entry = MetricsEntry(date: Date(), snapshot: store.load())
    let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

struct MetricsWidgetView: View {
  let entry: MetricsEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .systemSmall:
      smallView
    case .systemMedium:
      mediumView
    default:
      largeView
    }
  }

  private var smallView: some View {
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
    .padding(12)
  }

  private var mediumView: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Text("CPU")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(cpuText)
            .font(.title3)
        }
        Spacer()
        VStack(alignment: .leading, spacing: 6) {
          Text("RAM")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(memoryText)
            .font(.title3)
        }
      }
      VStack(alignment: .leading, spacing: 6) {
        Text("Disco livre")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(diskText)
          .font(.title3)
      }
    }
    .padding(12)
  }

  private var largeView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("PulseMac")
        .font(.headline)
      HStack {
        VStack(alignment: .leading) {
          Text("CPU")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(cpuText)
        }
        Spacer()
        VStack(alignment: .leading) {
          Text("RAM")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(memoryText)
        }
      }
      Spacer()
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
      Text("Atualiza em ate 5m")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    .padding(12)
  }

  private var cpuText: String {
    guard let cpu = entry.snapshot?.cpu.usagePercent else { return "--" }
    return String(format: "%.0f%%", cpu)
  }

  private var memoryText: String {
    guard let used = entry.snapshot?.memory.usedBytes else { return "--" }
    let usedGB = Double(used) / 1_073_741_824.0
    return String(format: "%.1f GB", usedGB)
  }

  private var diskText: String {
    guard let free = entry.snapshot?.disk?.freeBytes else { return "--" }
    let freeGB = Double(free) / 1_073_741_824.0
    return String(format: "%.1f GB", freeGB)
  }

  private var networkText: String {
    guard let network = entry.snapshot?.network else { return "--" }
    let downloadRate = formatRate(network.downloadBytesPerSec)
    let uploadRate = formatRate(network.uploadBytesPerSec)
    return "\(downloadRate) ↓ / \(uploadRate) ↑"
  }

  private func formatRate(_ bytesPerSec: Double) -> String {
    let kiloBytes = bytesPerSec / 1024.0
    let megaBytes = kiloBytes / 1024.0
    if megaBytes >= 1 {
      return String(format: "%.1f MB/s", megaBytes)
    }
    return String(format: "%.0f KB/s", kiloBytes)
  }
}

@main
struct PulseMacWidget: Widget {
  let kind: String = "PulseMacWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MetricsProvider()) { entry in
      MetricsWidgetView(entry: entry)
    }
    .configurationDisplayName("PulseMac")
    .description("CPU, RAM, Disco e Rede (atualizacao nao em tempo real)")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
