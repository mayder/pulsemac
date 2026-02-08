import Combine
import Foundation
import PulseMacDomain

public final class MenuBarViewModel: ObservableObject {
  @Published public private(set) var cpuText: String = "CPU --"
  @Published public private(set) var memoryText: String = "RAM --"
  @Published public private(set) var lastUpdatedText: String = ""

  private var cancellables: Set<AnyCancellable> = []

  public init() {}

  public func bind(to publisher: AnyPublisher<MetricSnapshot, Never>) {
    publisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] snapshot in
        self?.cpuText = String(format: "CPU %.0f%%", snapshot.cpu.usagePercent)
        let usedGB = Double(snapshot.memory.usedBytes) / 1_073_741_824.0
        self?.memoryText = String(format: "RAM %.1f GB", usedGB)
        self?.lastUpdatedText = "Atualizado: \(Self.timeFormatter.string(from: snapshot.timestamp))"
      }
      .store(in: &cancellables)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter
  }()
}
