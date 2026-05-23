import Combine
import Foundation

public enum SettingsTab: String, CaseIterable, Identifiable {
  case metrics
  case processes
  case alerts
  case impact
  case logs
  case widgets
  case preferences
  case about

  public static var allCases: [SettingsTab] {
    [.metrics, .processes, .alerts, .impact, .logs, .widgets, .preferences, .about]
  }

  public var id: String {
    rawValue
  }

  public var title: String {
    switch self {
    case .metrics:
      "Metricas"
    case .alerts:
      "Alertas"
    case .processes:
      "Processos"
    case .impact:
      "Impacto"
    case .logs:
      "Logs"
    case .widgets:
      "Widgets"
    case .preferences:
      "Ajustes"
    case .about:
      "Sobre"
    }
  }

  public var systemImage: String {
    switch self {
    case .metrics:
      "gauge.high"
    case .processes:
      "list.bullet.rectangle"
    case .alerts:
      "bell"
    case .impact:
      "exclamationmark.triangle"
    case .logs:
      "doc.text.magnifyingglass"
    case .widgets:
      "rectangle.grid.2x2"
    case .preferences:
      "gearshape"
    case .about:
      "info.circle"
    }
  }
}

public final class SettingsNavigationModel: ObservableObject {
  @Published public var selectedTab: SettingsTab

  public init(selectedTab: SettingsTab = .metrics) {
    self.selectedTab = selectedTab
  }
}
