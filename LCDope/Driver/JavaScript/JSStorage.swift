
import JavaScriptCore

class JSStorage {
	
	/// Loads data from UserDefaults and inject it into JSContext's localStorage
	static func loadLocalStorage(to context: JSContext, url: String) {
		if let json = UserDefaults.standard.string(forKey: "\(url).localStorage") {
			context.evaluateScript("localStorage.__load(\(json))")
		}
	}
	
	/// Saves the current state of JSContext's localStorage to UserDefaults
	static func storeLocalStorage(from context: JSContext, url: String) {
		let json = context.evaluateScript("JSON.stringify(localStorage.__store())").toString()!
		UserDefaults.standard.set(json, forKey: "\(url).localStorage")
		UserDefaults.standard.synchronize()
	}
	
}
