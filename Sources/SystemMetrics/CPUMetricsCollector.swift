import Darwin.Mach
import Foundation
import PulseMacDomain

public final class CPUMetricsCollector: CPUMetricsProviding {
  private var previous: host_cpu_load_info_data_t?

  public init() {}

  public func read() -> CPUMetrics {
    var cpuInfo = host_cpu_load_info()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

    let result = withUnsafeMutablePointer(to: &cpuInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
      }
    }

    guard result == KERN_SUCCESS else {
      return CPUMetrics(usagePercent: 0)
    }

    let user = Double(cpuInfo.cpu_ticks.0)
    let system = Double(cpuInfo.cpu_ticks.1)
    let idle = Double(cpuInfo.cpu_ticks.2)
    let nice = Double(cpuInfo.cpu_ticks.3)

    defer { previous = cpuInfo }

    guard let prev = previous else {
      return CPUMetrics(usagePercent: 0)
    }

    let prevUser = Double(prev.cpu_ticks.0)
    let prevSystem = Double(prev.cpu_ticks.1)
    let prevIdle = Double(prev.cpu_ticks.2)
    let prevNice = Double(prev.cpu_ticks.3)

    let diffUser = user - prevUser
    let diffSystem = system - prevSystem
    let diffIdle = idle - prevIdle
    let diffNice = nice - prevNice

    let total = diffUser + diffSystem + diffIdle + diffNice
    let usage = total > 0 ? ((total - diffIdle) / total) * 100.0 : 0

    return CPUMetrics(usagePercent: usage)
  }
}
