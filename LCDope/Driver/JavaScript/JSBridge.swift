
import JavaScriptCore

class JSBridge {

	private static let bridgePath = Bundle.main.path(forResource: "JSBridge", ofType: "js")
	private static var bridgeClass = try! String(contentsOfFile: bridgePath!, encoding: .utf8)
	
	static func provide(to context: JSContext) {
		context.exceptionHandler = { context, exception in
			print("JS Exception:", exception?.toString() ?? "unknown")
		}
		context.evaluateScript(bridgeClass)
		let __btoa: @convention(block) (String) -> String = { string in
			string.data(using: .utf8)?.base64EncodedString() ?? ""
		}
		let __atob: @convention(block) (String) -> String = { base64String in
			guard let data = Data(base64Encoded: base64String),
				  let decodedString = String(data: data, encoding: .utf8) else {
				return ""
			}
			return decodedString
		}
#if TARGET_LOGS // add flag to App Target build settings (but not Widget Target)
		let   __log: @convention(block) (String) -> Void = { message in Logger.log(message) }
		let __error: @convention(block) (String) -> Void = { message in Logger.error(message) }
		let  __info: @convention(block) (String) -> Void = { message in Logger.info(message) }
		let  __warn: @convention(block) (String) -> Void = { message in Logger.warning(message) }
		let __debug: @convention(block) (String) -> Void = { message in Logger.debug(message) }
		context.setObject(__log,   for: "__log")
		context.setObject(__error, for: "__error")
		context.setObject(__info,  for: "__info")
		context.setObject(__warn,  for: "__warn")
		context.setObject(__debug, for: "__debug")
#else
		context.evaluateScript(
			"const __log = () => undefined; const __error = __log, __info = __log, __warn = __log, __debug = __log;"
		)
#endif
		context.setObject(__btoa,  for: "btoa")
		context.setObject(__atob,  for: "atob")
	}
	
}
