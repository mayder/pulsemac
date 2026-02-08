import Foundation

public enum MetricsCategory: String, CaseIterable, Identifiable {
  case overview
  case cpu
  case memory
  case disk
  case network
  case battery
  case sensors

  public var id: String {
    rawValue
  }

  public var title: String {
    switch self {
    case .overview:
      "Visao geral"
    case .cpu:
      "CPU"
    case .memory:
      "Memoria"
    case .disk:
      "Disco"
    case .network:
      "Rede"
    case .battery:
      "Bateria"
    case .sensors:
      "Sensores"
    }
  }

  public var systemImage: String {
    switch self {
    case .overview:
      "square.grid.2x2"
    case .cpu:
      "cpu"
    case .memory:
      "memorychip"
    case .disk:
      "internaldrive"
    case .network:
      "network"
    case .battery:
      "battery.100"
    case .sensors:
      "thermometer.medium"
    }
  }
}
