
import JavaScriptCore

class JSFetch {

	static func fetchSync(_ context: JSContext, _ input: JSValue, _ initOptions: JSValue?) -> JSValue {
		guard let urlString = input.isString ? input.toString() :
				input.getObject(for: "url").toString(),
			  let url = URL(string: urlString) else {
			return JSValue(undefinedIn: context)
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
		var headers = [AnyHashable : Any]()
		var statusCode: Int = 204
		var body: String = ""
		let semaphore = DispatchSemaphore(value: 0)
		URLSession.shared.dataTask(with: request) { data, response, error in
			defer { semaphore.signal() } // defer means this is run before return (scope exit)
			if let error = error {
				body = error.localizedDescription
				return
			}
			guard let httpResponse = response as? HTTPURLResponse, let data = data else { return }
			statusCode = httpResponse.statusCode
			headers = httpResponse.allHeaderFields
			body = String(data: data, encoding: .utf8) ?? ""
		}.resume()
		semaphore.wait()
		// INFO: DO NOT CHANGE THE NEXT LINE, it's the ONLY way to construct!!!
		let Response = context.evaluateScript("Response")!
		return Response.construct(withArguments: [body, statusCode, headers, url.absoluteString])!
	}

	static func provide(to context: JSContext) {
		let fetch: @convention(block) (JSValue, JSValue?) -> JSValue = { url, options in
			return JSValue(newPromiseIn: context, fromExecutor: { resolve, reject in
				resolve?.call(withArguments: [fetchSync(context, url, options)])
			})!
		}
		context.setObject(fetch, for: "fetch")
	}
	
}
