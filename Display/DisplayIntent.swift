
import WidgetKit
import AppIntents
import CoreLocation

struct DisplayIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Configuration" }
	static var description: IntentDescription { "LCDisplay Configuration." }
	
	@Parameter(title: "Interval", defaultValue: 5, defaultUnit: .minutes, supportsNegativeNumbers: false)
	var interval: Measurement<UnitDuration>
	
	@Parameter(title: "Location")
	var location: CLPlacemark?
	
	@Parameter(title: "JS Driver", supportedContentTypes: [ .javaScript ])
	var driver: IntentFile?
	var type: String? { driver?.fileURL?.pathExtension }
	func file() -> String? {
		if driver == nil || driver!.fileURL == nil { return nil }
		do {
			let _ = driver!.fileURL!.startAccessingSecurityScopedResource()
			let data = try Data(contentsOf: driver!.fileURL!)
			driver!.fileURL!.stopAccessingSecurityScopedResource()
			return String(data: data, encoding: .utf8)
		} catch { return nil }
	}
	
	func coords() -> [Double] {
		if location != nil, let place = location!.location {
			return [ place.coordinate.latitude, place.coordinate.longitude ]
		}
		return []
	}
	
}
