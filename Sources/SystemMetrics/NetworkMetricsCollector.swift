import Darwin
import Foundation
import PulseMacDomain

public final class NetworkMetricsCollector: NetworkMetricsProviding {
  private var lastTotal: (rx: UInt64, tx: UInt64)?
  private var lastTimestamp: Date?

  public init() {}

  public func read() -> NetworkMetrics? {
    let now = Date()
    let totals = readTotals()

    defer {
      lastTotal = totals
      lastTimestamp = now
    }

    guard let totals, let lastTotal, let lastTimestamp else {
      return NetworkMetrics(downloadBytesPerSec: 0, uploadBytesPerSec: 0)
    }

    let interval = now.timeIntervalSince(lastTimestamp)
    guard interval > 0 else { return NetworkMetrics(downloadBytesPerSec: 0, uploadBytesPerSec: 0) }

    let deltaRx = max(0, Double(totals.rx) - Double(lastTotal.rx))
    let deltaTx = max(0, Double(totals.tx) - Double(lastTotal.tx))

    return NetworkMetrics(downloadBytesPerSec: deltaRx / interval, uploadBytesPerSec: deltaTx / interval)
  }

  private func readTotals() -> (rx: UInt64, tx: UInt64)? {
    var totalRx: UInt64 = 0
    var totalTx: UInt64 = 0
    var addressPointer: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&addressPointer) == 0, let first = addressPointer else { return nil }

    var pointer: UnsafeMutablePointer<ifaddrs>? = first
    while let current = pointer {
      let flags = current.pointee.ifa_flags
      let isUp = (flags & UInt32(IFF_UP)) != 0
      let isRunning = (flags & UInt32(IFF_RUNNING)) != 0
      let isLoopback = (flags & UInt32(IFF_LOOPBACK)) != 0

      if isUp, isRunning, !isLoopback {
        if let data = current.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
          totalRx += UInt64(data.pointee.ifi_ibytes)
          totalTx += UInt64(data.pointee.ifi_obytes)
        }
      }

      pointer = current.pointee.ifa_next
    }

    freeifaddrs(first)
    return (rx: totalRx, tx: totalTx)
  }
}
