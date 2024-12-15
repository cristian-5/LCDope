
import SwiftUI
import UniformTypeIdentifiers

struct LCDocument: FileDocument {
	
	static var readableContentTypes: [UTType] { [ .javaScript ] }

    var code: String
	var name: String

    init(code: String = "") {
        self.code = code
		self.name = ""
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
		code = string
		name = configuration.file.filename ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: code.data(using: .utf8)!)
    }

}
