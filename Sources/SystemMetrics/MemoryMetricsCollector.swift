import Darwin.Mach
import Foundation
import PulseMacDomain

public final class MemoryMetricsCollector: MemoryMetricsProviding {
  public init() {}

  public func read() -> MemoryMetrics {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

    let result = withUnsafeMutablePointer(to: &stats) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }

    let total = ProcessInfo.processInfo.physicalMemory

    guard result == KERN_SUCCESS else {
      return MemoryMetrics(usedBytes: 0, totalBytes: total)
    }

    let pageSize = UInt64(vm_kernel_page_size)
    let usedPages = stats.active_count + stats.inactive_count + stats.wire_count + stats.compressor_page_count
    let usedBytes = UInt64(usedPages) * pageSize

    return MemoryMetrics(usedBytes: usedBytes, totalBytes: total)
  }
}
