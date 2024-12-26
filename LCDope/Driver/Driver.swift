

import AppKit
import Network
import CoreLocation
import JavaScriptCore

struct Frame {
	public var data: [[UInt32]]
	public var back: UInt32
#if TARGET_LOGS
	public var logs: [LogEntry]
#endif
}

func driver(_ js: String, for name: String, on date: Date, with size: (w: Int, h: Int), in place: [Double] = []) -> Frame {
#if TARGET_LOGS
	Logger.clear() // clear old logs before new stuff
#endif
	var lcd = Matrix(m: size.w, n: size.h, UInt32(0))
	var touched = Matrix(m: size.w, n: size.h, false)
	let context = JSContext()! // ostrich algorithm
	context.setObject(date, for: "__DATE")
	let _loc:  @convention(block) () -> [Double] = { return place }
	let _lang: @convention(block) () -> [String] = { return Locale.preferredLanguages }
	let _online: @convention(block) () -> Bool = {
		let monitor = NWPathMonitor()
		let queue = DispatchQueue.global(qos: .userInteractive)
		let semaphore = DispatchSemaphore(value: 0)
		var isOnline = false
		monitor.pathUpdateHandler = { path in
			isOnline = (path.status == .satisfied)
			semaphore.signal() // Release the semaphore when the result is ready
		}
		monitor.start(queue: queue)
		semaphore.wait() // Wait for the network status to be determined
		monitor.cancel() // Stop monitoring to clean up resources
		return isOnline
	}
	context.setObject(_loc,    for: "__navigator_location")
	context.setObject(_lang,   for: "__navigator_languages")
	context.setObject(_online, for: "__navigator_online")
	JSBridge.provide(to: context)
	var backlight: UInt32 = 0x000000
	let _back: @convention(block) (JSValue) -> Void = { c in backlight = c.toColor() }
	let _pixel: @convention(block) (Int, Int, JSValue) -> Void = { x, y, color in
		if x < 0 || x >= size.w || y < 0 || y >= size.h { return }
		lcd[Int(y)][Int(x)] = color.toColor()
		touched[Int(y)][Int(x)] = true
	}
	let _fill: @convention(block) (JSValue) -> Void = { color in
		lcd = Matrix(m: size.w, n: size.h, color.toColor())
	}
	let _clear: @convention(block) () -> Void = {
		touched = Matrix(m: size.w, n: size.h, false)
	}
	JSFetch.provide(to: context)
	JSStorage.loadLocalStorage(to: context, url: name)
	context.setObject(_back,  for: "__lcd_backlight")
	context.setObject(_pixel, for: "__lcd_pixel")
	context.setObject(_fill,  for: "__lcd_fill")
	context.setObject(_clear, for: "__lcd_clear")
	context.setObject(size.w, for: "__LCD_WIDTH")
	context.setObject(size.h, for: "__LCD_HEIGHT")
	context.evaluateScript("""
        (async () => {
            try { \(js) }
            catch (e) { console.error(e); }
        })();
    """) // allow top-level await
	JSStorage.storeLocalStorage(from: context, url: name)
	for i in 0 ..< size.h {
		for j in 0 ..< size.w {
			if !touched[i][j] { lcd[i][j] = backlight }
		}
	}
#if TARGET_LOGS
	return Frame(data: lcd, back: backlight, logs: Logger.retreive())
#else
	return Frame(data: lcd, back: backlight) // Widget Target
#endif
}

func PlaceHolder(for size: (w: Int, h: Int)) -> Frame {
	var lcd = Matrix(m: size.w, n: size.h, UInt32(0))
	for i in 0 ..< size.h {
		for j in 0 ..< size.w {
			lcd[i][j] = (i / 4 % 2 != j / 4 % 2) ? 0x000000 : 0xFFFFFF
		}
	}
#if TARGET_LOGS
	return Frame(data: lcd, back: 0x000000, logs: [])
#else
	return Frame(data: lcd, back: 0x000000)
#endif
}
