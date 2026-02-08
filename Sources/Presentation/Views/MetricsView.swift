import PulseMacDomain
import SwiftUI

public struct MetricsView: View {
  @ObservedObject private var viewModel: MetricsDashboardViewModel
  @State private var selectedProcessId: Int32?
  @State private var showSensorsHelp: Bool = false
  @State private var showPowermetricsLog: Bool = false

  public init(viewModel: MetricsDashboardViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          Image("BrandSymbol")
            .resizable()
            .renderingMode(.original)
            .frame(width: 24, height: 24)
          SectionHeader("Metricas", subtitle: "Visao geral do sistema")
          Spacer()
          Text(viewModel.lastUpdatedText)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        MetricsCategoryPicker(selected: $viewModel.selectedCategory)

        Group {
          switch viewModel.selectedCategory {
          case .overview:
            overviewSection
          case .cpu:
            cpuSection
          case .memory:
            memorySection
          case .disk:
            diskSection
          case .network:
            networkSection
          case .battery:
            batterySection
          case .sensors:
            sensorsSection
          }
        }
      }
      .padding(16)
    }
    .sheet(isPresented: $showSensorsHelp) {
      SensorsHelpView()
    }
    .sheet(isPresented: $showPowermetricsLog) {
      PowermetricsLogView(text: viewModel.powermetricsRawOutput)
    }
    .onAppear {
      DispatchQueue.main.async {
        ensureSelectedProcess()
      }
    }
    .onChange(of: viewModel.processOverview) { _ in
      DispatchQueue.main.async {
        ensureSelectedProcess()
      }
    }
  }

  private func ensureSelectedProcess() {
    guard selectedProcessId != nil else {
      selectedProcessId = viewModel.processOverview.first?.id
      return
    }
    if let selectedProcessId {
      let exists = viewModel.processOverview.contains(where: { $0.id == selectedProcessId })
      if exists {
        return
      }
    }
    selectedProcessId = viewModel.processOverview.first?.id
  }

  private var selectedProcessDetail: ProcessDetail? {
    guard let selectedProcessId else { return nil }
    guard let row = viewModel.processOverview.first(where: { $0.id == selectedProcessId }) else { return nil }
    guard let history = viewModel.processHistory[selectedProcessId] else { return nil }
    return ProcessDetail(name: row.name, cpuText: row.cpuText, memoryText: row.memoryText, history: history)
  }

  private var overviewMemorySubtitle: String {
    "Uso atual"
  }

  private var overviewDiskSubtitle: String {
    "Livre"
  }

  private var overviewBatterySubtitle: String {
    "Estado"
  }

  private var memorySubtitleDetailed: String {
    guard let used = viewModel.memoryUsedGB,
          let free = viewModel.memoryFreeGB,
          let total = viewModel.memoryTotalGB else { return "Uso" }
    return String(format: "Usado %.1f GB • Livre %.1f GB de %.1f GB", used, free, total)
  }

  private var diskSubtitleDetailed: String {
    guard let used = viewModel.diskUsedGB,
          let free = viewModel.diskFreeGB,
          let total = viewModel.diskTotalGB else { return "Livre" }
    return String(format: "Livre %.1f GB • Usado %.1f GB de %.1f GB", free, used, total)
  }

  private var batterySubtitleDetailed: String {
    "Fonte \(viewModel.batterySourceText)"
  }

  private var overviewSection: some View {
    GroupBox("Monitor") {
      VStack(alignment: .leading, spacing: 12) {
        let columns = [
          GridItem(.flexible(), spacing: 12),
          GridItem(.flexible(), spacing: 12)
        ]

        LazyVGrid(columns: columns, spacing: 12) {
          MetricGaugeView(
            title: "CPU",
            value: viewModel.cpuPercent,
            valueText: String(format: "%.0f%%", viewModel.cpuPercent),
            range: 0 ... 100,
            color: .pink,
            history: viewModel.cpuHistory,
            subtitle: "Uso"
          )
          MetricGaugeView(
            title: "RAM",
            value: viewModel.memoryPercent,
            valueText: String(format: "%.0f%%", viewModel.memoryPercent),
            range: 0 ... 100,
            color: .blue,
            history: viewModel.memoryHistory,
            subtitle: overviewMemorySubtitle
          )
          MetricGaugeView(
            title: "Disco livre",
            value: viewModel.diskFreePercent,
            valueText: viewModel.diskFreePercent.map { String(format: "%.0f%%", $0) } ?? "--",
            range: 0 ... 100,
            color: .green,
            history: viewModel.diskHistory,
            subtitle: overviewDiskSubtitle
          )
          MetricGaugeView(
            title: "Bateria",
            value: viewModel.batteryPercent,
            valueText: viewModel.batteryPercent.map { String(format: "%.0f%%", $0) } ?? "--",
            range: 0 ... 100,
            color: .orange,
            history: viewModel.batteryHistory,
            subtitle: overviewBatterySubtitle
          )
        }
      }
    }
  }

  private var cpuSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      GroupBox("CPU") {
        MetricGaugeView(
          title: "CPU",
          value: viewModel.cpuPercent,
          valueText: String(format: "%.0f%%", viewModel.cpuPercent),
          range: 0 ... 100,
          color: .pink,
          history: viewModel.cpuHistory,
          subtitle: "Uso atual"
        )
      }
      GroupBox("Processos (CPU)") {
        processList(rows: viewModel.topCpuProcesses, valueText: { $0.cpuText })
      }
    }
  }

  private var memorySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      GroupBox("Memoria") {
        MetricGaugeView(
          title: "RAM",
          value: viewModel.memoryPercent,
          valueText: String(format: "%.0f%%", viewModel.memoryPercent),
          range: 0 ... 100,
          color: .blue,
          history: viewModel.memoryHistory,
          subtitle: memorySubtitleDetailed
        )
      }
      GroupBox("Detalhes") {
        let columns = [
          GridItem(.flexible(), spacing: 12),
          GridItem(.flexible(), spacing: 12)
        ]
        LazyVGrid(columns: columns, spacing: 12) {
          InfoPill("Memoria usada", value: memoryUsedText, accent: .blue)
          InfoPill("Memoria livre", value: memoryFreeText, accent: .blue)
          InfoPill("Memoria total", value: memoryTotalText, accent: .blue)
          InfoPill("Uso %", value: memoryPercentText, accent: .blue)
        }
      }
      GroupBox("Processos (Memoria)") {
        processList(rows: viewModel.topMemoryProcesses, valueText: { $0.memoryText })
      }
    }
  }

  private var diskSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      GroupBox("Disco") {
        MetricGaugeView(
          title: "Disco livre",
          value: viewModel.diskFreePercent,
          valueText: viewModel.diskFreePercent.map { String(format: "%.0f%%", $0) } ?? "--",
          range: 0 ... 100,
          color: .green,
          history: viewModel.diskHistory,
          subtitle: diskSubtitleDetailed
        )
      }
      GroupBox("Detalhes") {
        let columns = [
          GridItem(.flexible(), spacing: 12),
          GridItem(.flexible(), spacing: 12)
        ]
        LazyVGrid(columns: columns, spacing: 12) {
          InfoPill("Disco usado", value: diskUsedText, accent: .green)
          InfoPill("Disco livre", value: diskFreeText, accent: .green)
        }
      }
    }
  }

  private var networkSection: some View {
    GroupBox("Rede (KB/s)") {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 12) {
          InfoPill(
            "Download",
            value: viewModel.networkDownloadKBps.map { String(format: "%.0f KB/s", $0) } ?? "--",
            accent: .blue
          )
          InfoPill(
            "Upload",
            value: viewModel.networkUploadKBps.map { String(format: "%.0f KB/s", $0) } ?? "--",
            accent: .purple
          )
        }

        VStack(alignment: .leading, spacing: 4) {
          SparklineView(
            values: viewModel.networkDownloadHistory,
            minValue: 0,
            maxValue: max(viewModel.networkDownloadHistory.max() ?? 0, 1),
            lineColor: .blue,
            dense: true,
            showFill: true
          )
          SparklineView(
            values: viewModel.networkUploadHistory,
            minValue: 0,
            maxValue: max(viewModel.networkUploadHistory.max() ?? 0, 1),
            lineColor: .purple,
            dense: true,
            showFill: true
          )
        }
      }
    }
  }

  private var batterySection: some View {
    GroupBox("Bateria") {
      MetricGaugeView(
        title: "Bateria",
        value: viewModel.batteryPercent,
        valueText: viewModel.batteryPercent.map { String(format: "%.0f%%", $0) } ?? "--",
        range: 0 ... 100,
        color: .orange,
        history: viewModel.batteryHistory,
        subtitle: batterySubtitleDetailed
      )
    }
  }

  private var sensorsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      GroupBox("Sensores") {
        HStack(spacing: 12) {
          InfoPill("Temperatura", value: viewModel.thermalDetailText)
          InfoPill("Fans", value: viewModel.fansDetailText)
        }
      }

      GroupBox("Diagnostico de sensores") {
        if viewModel.thermalDiagnosticsRows.isEmpty {
          Text(viewModel.thermalDiagnosticsMessage.isEmpty ? "Diagnostico indisponivel." : viewModel.thermalDiagnosticsMessage)
            .foregroundColor(.secondary)
        } else {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.thermalDiagnosticsRows) { row in
              HStack(alignment: .top, spacing: 12) {
                Text(row.title)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(width: 110, alignment: .leading)
                Text(row.value)
                  .font(.callout)
                  .textSelection(.enabled)
                Spacer()
              }
            }
          }
          if !viewModel.thermalDiagnosticsMessage.isEmpty {
            Text(viewModel.thermalDiagnosticsMessage)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }

      GroupBox("Powermetrics (manual)") {
        VStack(alignment: .leading, spacing: 8) {
          Text("Opcao manual para ler sensores com permissao de administrador.")
            .font(.caption)
            .foregroundColor(.secondary)
          HStack(spacing: 12) {
            InfoPill("Temperatura", value: viewModel.powermetricsTemperatureText)
            InfoPill("Fans", value: viewModel.powermetricsFansText)
            InfoPill("Pressao termica", value: viewModel.powermetricsPressureText)
          }
          if !viewModel.powermetricsLastUpdatedText.isEmpty {
            Text(viewModel.powermetricsLastUpdatedText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          if !viewModel.powermetricsStatusText.isEmpty {
            Text(viewModel.powermetricsStatusText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          HStack(spacing: 12) {
            Button {
              viewModel.requestPowermetricsFallback()
            } label: {
              Label("Ler via powermetrics (sudo)", systemImage: "lock.open")
            }
            .buttonStyle(.borderedProminent)

            Button {
              showSensorsHelp = true
            } label: {
              Label("Saiba mais", systemImage: "info.circle")
            }
            .buttonStyle(.bordered)

            if !viewModel.powermetricsRawOutput.isEmpty {
              Button {
                showPowermetricsLog = true
              } label: {
                Label("Ver log", systemImage: "doc.text")
              }
              .buttonStyle(.bordered)
            }
          }
        }
      }
    }
  }

  private func processList(rows: [ProcessRow], valueText: @escaping (ProcessRow) -> String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      if rows.isEmpty {
        Text("Sem dados")
          .foregroundColor(.secondary)
      } else {
        ForEach(rows) { row in
          HStack {
            Text(row.name)
            Spacer()
            Text(valueText(row))
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var memoryUsedText: String {
    guard let value = viewModel.memoryUsedGB else { return "--" }
    return String(format: "%.1f GB", value)
  }

  private var memoryFreeText: String {
    guard let value = viewModel.memoryFreeGB else { return "--" }
    return String(format: "%.1f GB", value)
  }

  private var memoryTotalText: String {
    guard let value = viewModel.memoryTotalGB else { return "--" }
    return String(format: "%.1f GB", value)
  }

  private var memoryPercentText: String {
    String(format: "%.0f%%", viewModel.memoryPercent)
  }

  private var diskUsedText: String {
    guard let value = viewModel.diskUsedGB else { return "--" }
    return String(format: "%.1f GB", value)
  }

  private var diskFreeText: String {
    guard let value = viewModel.diskFreeGB else { return "--" }
    return String(format: "%.1f GB", value)
  }
}

private struct MetricsCategoryPicker: View {
  @Binding var selected: MetricsCategory

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(MetricsCategory.allCases) { item in
          Button {
            selected = item
          } label: {
            Label(item.title, systemImage: item.systemImage)
              .font(.subheadline)
              .foregroundColor(selected == item ? .white : BrandStyle.label)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                RoundedRectangle(cornerRadius: 10)
                  .fill(selected == item ? BrandStyle.accent : BrandStyle.surface)
              )
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

private struct ProcessDetail {
  let name: String
  let cpuText: String
  let memoryText: String
  let history: ProcessHistory
}

private struct MetricGaugeView: View {
  let title: String
  let value: Double?
  let valueText: String
  let range: ClosedRange<Double>
  let color: Color
  let history: [Double]
  let subtitle: String

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
        RingGaugeView(
          value: value,
          range: range,
          valueText: valueText,
          color: color
        )
        SparklineView(
          values: history,
          minValue: range.lowerBound,
          maxValue: range.upperBound,
          lineColor: color,
          dense: false,
          showFill: true
        )
        Text(subtitle)
          .font(.caption2)
          .foregroundColor(BrandStyle.label)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SparklineView: View {
  let values: [Double]
  let minValue: Double
  let maxValue: Double
  let lineColor: Color
  var dense: Bool = false
  var showFill: Bool = true

  var body: some View {
    GeometryReader { _ in
      ZStack {
        Canvas { context, size in
          guard values.count > 1 else { return }

          if dense {
            drawGrid(in: size, context: &context)
          }

          let points = normalizedPoints(in: size)
          guard let first = points.first, let last = points.last else { return }

          var line = Path()
          line.move(to: first)
          line.addLines(points)

          if showFill {
            var fill = line
            fill.addLine(to: CGPoint(x: last.x, y: size.height))
            fill.addLine(to: CGPoint(x: first.x, y: size.height))
            fill.closeSubpath()
            let fillGradient = Gradient(colors: [lineColor.opacity(0.25), lineColor.opacity(0.01)])
            context.fill(
              fill,
              with: .linearGradient(
                fillGradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: size.height)
              )
            )
          }

          let strokeGradient = Gradient(colors: [lineColor.opacity(0.4), lineColor])
          context.stroke(
            line,
            with: .linearGradient(
              strokeGradient,
              startPoint: CGPoint(x: 0, y: 0),
              endPoint: CGPoint(x: size.width, y: size.height)
            ),
            style: StrokeStyle(lineWidth: dense ? 2.2 : 1.8, lineCap: .round, lineJoin: .round)
          )

          let dotSize: CGFloat = dense ? 4.5 : 4
          let dotRect = CGRect(x: last.x - dotSize / 2, y: last.y - dotSize / 2, width: dotSize, height: dotSize)
          context.fill(Path(ellipseIn: dotRect), with: .color(lineColor))
        }

        if values.count < 2 {
          Text("Sem dados")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(height: dense ? 44 : 36)
  }

  private func normalizedPoints(in size: CGSize) -> [CGPoint] {
    guard values.count > 1 else { return [] }
    let range = max(maxValue - minValue, 1)
    let stepX = size.width / CGFloat(values.count - 1)
    return values.enumerated().map { index, value in
      let clamped = min(max(value, minValue), maxValue)
      let normalized = (clamped - minValue) / range
      let yPoint = size.height * (1 - CGFloat(normalized))
      let xPoint = CGFloat(index) * stepX
      return CGPoint(x: xPoint, y: yPoint)
    }
  }

  private func drawGrid(in size: CGSize, context: inout GraphicsContext) {
    let stroke = StrokeStyle(lineWidth: 0.6, lineCap: .round)
    let color = BrandStyle.border.opacity(0.25)
    let verticalCount = 5
    let horizontalCount = 3

    for index in 0 ..< verticalCount {
      let xPosition = size.width * CGFloat(index) / CGFloat(verticalCount - 1)
      var path = Path()
      path.move(to: CGPoint(x: xPosition, y: 0))
      path.addLine(to: CGPoint(x: xPosition, y: size.height))
      context.stroke(path, with: .color(color), style: stroke)
    }

    for index in 0 ..< horizontalCount {
      let yPosition = size.height * CGFloat(index) / CGFloat(horizontalCount - 1)
      var path = Path()
      path.move(to: CGPoint(x: 0, y: yPosition))
      path.addLine(to: CGPoint(x: size.width, y: yPosition))
      context.stroke(path, with: .color(color), style: stroke)
    }
  }
}

private struct SensorsHelpView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Sensores no macOS")
            .font(.title3)
            .fontWeight(.semibold)
          Spacer()
          Button("Fechar") {
            dismiss()
          }
          .buttonStyle(.bordered)
        }
        Text("Em Macs Apple Silicon (ex.: M4 Pro), o macOS pode nao expor sensores de temperatura e fans para apps comuns.")
        Text("Por isso, os dados podem aparecer como indisponiveis mesmo com o SMC aberto.")
          .foregroundColor(.secondary)
        Text("Alternativa")
          .font(.headline)
        Text("Use o botao \"Ler via powermetrics (sudo)\" para uma leitura manual. Isso pede permissao de administrador e nao funciona sem senha.")
          .foregroundColor(.secondary)
        Text("Em alguns Macs, o powermetrics mostra apenas a pressao termica e nao expõe temperaturas ou fans.")
          .foregroundColor(.secondary)
        Text("Se aparecer \"unrecognized sampler\", este macOS nao suporta o sampler informado e a leitura pode falhar.")
          .foregroundColor(.secondary)
        Text("Privacidade")
          .font(.headline)
        Text("A leitura e local, sem rede. Nada e enviado para fora.")
          .foregroundColor(.secondary)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(minWidth: 480, minHeight: 320)
  }
}

private struct PowermetricsLogView: View {
  let text: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Log do powermetrics")
          .font(.headline)
        Spacer()
        Button("Fechar") {
          dismiss()
        }
        .buttonStyle(.bordered)
      }
      .padding(16)

      ScrollView {
        Text(text.isEmpty ? "Sem log." : text)
          .font(.system(.caption, design: .monospaced))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(16)
      }
    }
    .frame(minWidth: 600, minHeight: 360)
  }
}

private struct RingGaugeView: View {
  let value: Double?
  let range: ClosedRange<Double>
  let valueText: String
  let color: Color

  var body: some View {
    let progress = normalizedValue
    let displayText = value == nil ? "--" : valueText

    ZStack {
      Circle()
        .stroke(BrandStyle.border.opacity(0.4), lineWidth: 10)

      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [color.opacity(0.25), color, color.opacity(0.9)]),
            center: .center
          ),
          style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
        )
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text(displayText)
          .font(.title3)
          .fontWeight(.semibold)
          .monospacedDigit()
        Text("Atual")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .frame(height: 88)
  }

  private var normalizedValue: Double {
    guard let value else { return 0 }
    let span = max(range.upperBound - range.lowerBound, 1)
    let clamped = min(max(value, range.lowerBound), range.upperBound)
    return (clamped - range.lowerBound) / span
  }
}
