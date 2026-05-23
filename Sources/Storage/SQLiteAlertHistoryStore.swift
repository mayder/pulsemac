import Foundation
import PulseMacDomain
import SQLite3

public final class SQLiteAlertHistoryStore: AlertHistoryStore {
  private let queue = DispatchQueue(label: "pulsemac.sqlite.alerts")
  private var database: OpaquePointer?
  private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

  public init(fileURL: URL) {
    openDatabase(at: fileURL)
    createTableIfNeeded()
  }

  deinit {
    if let database {
      sqlite3_close(database)
    }
  }

  public func record(event: AlertEvent) {
    queue.sync {
      let sql = "INSERT INTO alert_history (id, rule_id, ts, severity, message) VALUES (?, ?, ?, ?, ?);"
      var statement: OpaquePointer?
      guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { return }
      defer { sqlite3_finalize(statement) }

      sqlite3_bind_text(statement, 1, event.id.uuidString, -1, sqliteTransient)
      sqlite3_bind_text(statement, 2, event.ruleId.uuidString, -1, sqliteTransient)
      sqlite3_bind_double(statement, 3, event.timestamp.timeIntervalSince1970)
      sqlite3_bind_text(statement, 4, event.severity.rawValue, -1, sqliteTransient)
      sqlite3_bind_text(statement, 5, event.message, -1, sqliteTransient)

      _ = sqlite3_step(statement)
    }
  }

  public func list(limit: Int) -> [AlertEvent] {
    queue.sync {
      let sql = "SELECT id, rule_id, ts, severity, message FROM alert_history ORDER BY ts DESC LIMIT ?;"
      var statement: OpaquePointer?
      guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
      defer { sqlite3_finalize(statement) }

      sqlite3_bind_int(statement, 1, Int32(limit))

      var events: [AlertEvent] = []
      while sqlite3_step(statement) == SQLITE_ROW {
        guard
          let idCString = sqlite3_column_text(statement, 0),
          let ruleCString = sqlite3_column_text(statement, 1),
          let severityCString = sqlite3_column_text(statement, 3),
          let messageCString = sqlite3_column_text(statement, 4)
        else { continue }

        let id = UUID(uuidString: String(cString: idCString)) ?? UUID()
        let ruleId = UUID(uuidString: String(cString: ruleCString)) ?? UUID()
        let timestampValue = sqlite3_column_double(statement, 2)
        let severity = AlertSeverity(rawValue: String(cString: severityCString)) ?? .info
        let message = String(cString: messageCString)

        let event = AlertEvent(id: id, ruleId: ruleId, timestamp: Date(timeIntervalSince1970: timestampValue), severity: severity, message: message)
        events.append(event)
      }
      return events
    }
  }

  public func clearAll() {
    queue.sync {
      let sql = "DELETE FROM alert_history;"
      _ = sqlite3_exec(database, sql, nil, nil, nil)
    }
  }

  private func openDatabase(at url: URL) {
    queue.sync {
      _ = FileManager.default.createFile(atPath: url.path, contents: nil)
      if sqlite3_open(url.path, &database) != SQLITE_OK {
        database = nil
      }
    }
  }

  private func createTableIfNeeded() {
    queue.sync {
      let sql = """
      CREATE TABLE IF NOT EXISTS alert_history (
        id TEXT PRIMARY KEY,
        rule_id TEXT NOT NULL,
        ts REAL NOT NULL,
        severity TEXT NOT NULL,
        message TEXT NOT NULL
      );
      """
      _ = sqlite3_exec(database, sql, nil, nil, nil)
    }
  }
}
