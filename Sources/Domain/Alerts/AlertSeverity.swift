import Foundation

public enum AlertSeverity: String, Codable, CaseIterable {
  case info
  case warning
  case critical

  public var label: String {
    switch self {
    case .info:
      "Info"
    case .warning:
      "Aviso"
    case .critical:
      "Critico"
    }
  }
}
