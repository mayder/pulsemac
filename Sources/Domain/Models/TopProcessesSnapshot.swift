import Foundation

public struct TopProcessesSnapshot: Codable, Equatable {
  public let topCpu: [ProcessSnapshot]
  public let topMemory: [ProcessSnapshot]

  public init(topCpu: [ProcessSnapshot], topMemory: [ProcessSnapshot]) {
    self.topCpu = topCpu
    self.topMemory = topMemory
  }
}
