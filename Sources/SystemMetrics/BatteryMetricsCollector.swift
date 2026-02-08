import Foundation
import IOKit.ps
import PulseMacDomain

public final class BatteryMetricsCollector: BatteryMetricsProviding {
  public init() {}

  public func read() -> BatteryMetrics? {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
    guard let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }

    for source in sources {
      guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else { continue }
      guard let type = description[kIOPSTypeKey as String] as? String else { continue }
      if type != kIOPSInternalBatteryType { continue }

      let current = description[kIOPSCurrentCapacityKey as String] as? Double ?? 0
      let max = description[kIOPSMaxCapacityKey as String] as? Double ?? 0
      let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false

      let powerState = description[kIOPSPowerSourceStateKey as String] as? String ?? ""
      let sourceType: PowerSource = if powerState == kIOPSACPowerValue {
        .acPower
      } else if powerState == kIOPSBatteryPowerValue {
        .battery
      } else {
        .unknown
      }

      let percent = max > 0 ? (current / max) * 100.0 : 0
      return BatteryMetrics(chargePercent: percent, isCharging: isCharging, powerSource: sourceType)
    }

    return nil
  }
}
