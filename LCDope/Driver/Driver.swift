

import AppKit
import JavaScriptCore

struct Frame {
	public var data: [[UInt32]]
	public var back: UInt32
#if TARGET_LOGS
	public var logs: [LogEntry]
#endif
}

func driver(_ js: String, for name: String, on date: Date, with size: (w: Int, h: Int)) -> Frame {
#if TARGET_LOGS
	Logger.clear() // clear old logs before new stuff
#endif
	var lcd = Matrix(m: size.w, n: size.h, UInt32(0))
	let context = JSContext()! // ostrich algorithm
	JSBridge.provide(to: context)
	var backlight: UInt32 = 0x000000
	let _back: @convention(block) (JSValue) -> Void = { c in backlight = c.toColor() }
	let _pixel: @convention(block) (Int, Int, JSValue) -> Void = { x, y, color in
		if x < 0 || x >= size.w || y < 0 || y >= size.h { return }
		lcd[Int(y)][Int(x)] = color.toColor()
	}
	let _fill: @convention(block) (JSValue) -> Void = { color in
		lcd = Matrix(m: size.w, n: size.h, color.toColor())
	}
	JSFetch.provide(to: context)
	JSStorage.loadLocalStorage(to: context, url: name)
	context.setObject(_back,  for: "backlight")
	context.setObject(_pixel, for: "pixel")
	context.setObject(_fill,  for: "fill")
	context.setObject(size.w, for: "WIDTH")
	context.setObject(size.h, for: "HEIGHT")
	context.setObject(date,   for: "DATE")
	context.evaluateScript("""
        (async () => {
            try { \(js) }
            catch (e) { console.error(e); }
        })();
    """) // allow top-level await
	JSStorage.storeLocalStorage(from: context, url: name)
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
