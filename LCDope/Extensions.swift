
import AppKit
import SwiftUI
import JavaScriptCore

extension Date {

	var isAppleFoudationDay: Bool {
		let day = Calendar.current.component(.day, from: self)
		let month = Calendar.current.component(.month, from: self)
		return month == 4 && day == 1
	}

	var isCristianBirthDay: Bool {
		let day = Calendar.current.component(.day, from: self)
		let month = Calendar.current.component(.month, from: self)
		return month == 9 && day == 5
	}

}

extension Color {
	
	init(rgba: UInt32) {
		let a = CGFloat((rgba & 0xFF000000) >> 24) / 255.0
		let r = CGFloat((rgba & 0x00FF0000) >> 16) / 255.0
		let g = CGFloat((rgba & 0x0000FF00) >>  8) / 255.0
		let b = CGFloat( rgba & 0x000000FF) / 255.0
		self.init(red: r, green: g, blue: b, opacity: a)
	}
	
	init(rgb: UInt32) {
		let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
		let g = CGFloat((rgb & 0x00FF00) >>  8) / 255.0
		let b = CGFloat( rgb & 0x0000FF)        / 255.0
		self.init(red: r, green: g, blue: b, opacity: 1.0)
	}
	
	init(grayscale: Double) {
		self.init(red: grayscale, green: grayscale, blue: grayscale, opacity: 1.0)
	}
	
}

extension JSValue {
	
	var isValid: Bool { !self.isUndefined || !self.isNull }
	
	/// Converts a `Number` or a `String` to a rgb hex `UInt32` value.
	func toColor() -> UInt32 {
		if !self.isValid { return 0 }
		if self.isNumber { return self.toUInt32() }
		if !self.isString { return 0 }
		let from = self.toString().replacing(try! Regex("[^a-fA-F0-9]+"), with: "")
		return UInt32(from, radix: 16) ?? 0
	}
	
	/// Converts a number to a standard color channel value of `0 ... 0xFF`.
	func toChannel() -> UInt32 {
		if !self.isNumber { return 0 }
		if !self.toString().contains(".") { return self.toUInt32() & 0xFF }
		let d = self.toDouble()
		return d.isFinite ? UInt32(max(min(d, 1.0), 0.0) * 255.0) : 0
	}
	
	func getObject(for key: Any!) -> JSValue {
		self.objectForKeyedSubscript(key)
	}
	
}

extension JSContext {
	
	func setObject(_ object: Any!, for key: String) {
		self.setObject(object, forKeyedSubscript: key as NSString)
	}
	
	func getObject(for key: String) -> JSValue {
		self.objectForKeyedSubscript(key)
	}
	
}

/// Makes a matrix of size `MxN` where `M` is width and `N` is height.
func Matrix<T>(m: Int, n: Int, _ value: T) -> [[T]] {
	return [[T]](repeating: [T](repeating: value, count: m), count: n)
}

