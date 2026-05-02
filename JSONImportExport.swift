import Foundation

enum JSONImportExport {
    static func exportDatabaseToJSON(container: DatabaseContainer) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(container) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func importDatabaseFromJSON(_ json: String) -> DatabaseContainer? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DatabaseContainer.self, from: data)
    }
}
