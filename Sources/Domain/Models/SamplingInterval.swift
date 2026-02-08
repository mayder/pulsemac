import Foundation

public enum SamplingInterval: TimeInterval, CaseIterable, Codable {
  case oneSecond = 1
  case twoSeconds = 2
  case fiveSeconds = 5
  case tenSeconds = 10

  public var label: String {
    switch self {
    case .oneSecond:
      "1s"
    case .twoSeconds:
      "2s"
    case .fiveSeconds:
      "5s"
    case .tenSeconds:
      "10s"
    }
  }
}
