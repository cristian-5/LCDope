
import SwiftUI

enum LogType {
	case log, error, info, warning, debug
	var background: Color? {
		([
			  .debug: .Logger.Background.debug,
		      .error: .Logger.Background.error,
			    .log: nil,
			   .info: .Logger.Background.info,
			.warning: .Logger.Background.warning
		] as [LogType: Color?])[self]!
	}
	var foreground: Color? {
		([
			  .debug: .Logger.Foreground.debug,
			  .error: .Logger.Foreground.error,
			    .log: nil,
			   .info: .Logger.Foreground.info,
			.warning: .Logger.Foreground.warning
		] as [LogType: Color?])[self]!
	}
}

struct LogEntry {
	let id = UUID()
	let stamp = Date().timeIntervalSince1970
	let message: String
	let type: LogType
}

class Logger {
	
	private static var entries: [LogEntry] = []
	
	static func append(_ message: String, type: LogType = .log) {
		// TODO: limit usage to Windows
		entries.append(LogEntry(message: message, type: type))
	}
	static func log(_ message: String)     { append(message, type: .log)     }
	static func error(_ message: String)   { append(message, type: .error)   }
	static func info(_ message: String)    { append(message, type: .info)    }
	static func warning(_ message: String) { append(message, type: .warning) }
	static func debug(_ message: String)   { append(message, type: .debug)   }
	static func clear() { entries.removeAll() }
	
	static func retreive() -> [LogEntry] {
		let backup = Array(entries)
		entries.removeAll()
		return backup
	}
	
}
