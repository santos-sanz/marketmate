import Foundation

final class OfflineService {
  static let shared = OfflineService()

  private init() {}

  private func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  func save<T: Encodable>(_ data: T, to filename: String) {
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
      let encoded = try JSONEncoder().encode(data)
      try encoded.write(to: url)
    } catch {
      print("Failed to save \(filename): \(error)")
    }
  }

  func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(type, from: data)
    } catch {
      print("Failed to load \(filename): \(error)")
      return nil
    }
  }
}
