import Crypto
import Foundation

struct HashManager {
    static func hash(_ text: String) -> String {
        let data = Data(text.utf8)
        let hashedData = SHA256.hash(data: data)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
