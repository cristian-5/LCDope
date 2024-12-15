
import JavaScriptCore

class JSFetch {
	
	static func provide(to context: JSContext) {
		let fetch: @convention(block) (JSValue, JSValue?) -> JSValue = { input, initOptions in
			return JSValue(newPromiseIn: context, fromExecutor: { resolve, reject in
				guard let urlString = input.isString ? input.toString() :
						input.getObject(for: "url").toString(),
					  let url = URL(string: urlString) else {
					reject!.call(withArguments: ["Invalid URL or Request"])
					return
				}
				var request = URLRequest(url: url)
				if let initOptions = initOptions, initOptions.isObject {
					if let method = initOptions.getObject(for: "method").toString() {
						request.httpMethod = method.uppercased()
					}
					let headers = initOptions.getObject(for: "headers")
					if headers.isObject {
						let headerKeys = headers.toDictionary().keys
						for key in headerKeys {
							if let value = headers.getObject(for: key).toString() {
								request.addValue(value, forHTTPHeaderField: key as! String)
							}
						}
					}
					if let body = initOptions.getObject(for: "body").toString() {
						request.httpBody = body.data(using: .utf8)
					}
				}
				// perform the network request:
				let task = URLSession.shared.dataTask(with: request) { data, response, error in
					if let error = error {
						reject!.call(withArguments: [error.localizedDescription])
						return
					}
					guard let httpResponse = response as? HTTPURLResponse, let data = data else {
						reject!.call(withArguments: ["No data or invalid response"])
						return
					}
					// INFO: DO NOT CHANGE THE NEXT LINE, it's the ONLY way to construct!!!
					let responseConstructor = context.evaluateScript("Response")!
					let responseBody = String(data: data, encoding: .utf8) ?? ""
					let responseObject = responseConstructor.construct(withArguments: [
						responseBody, httpResponse.statusCode, httpResponse.allHeaderFields, url.absoluteString
					])
					resolve!.call(withArguments: [responseObject!])
				}
				task.resume()
			})!
		}
		context.setObject(fetch, for: "fetch")
	}
	
}
