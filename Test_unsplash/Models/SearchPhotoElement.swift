import Foundation

// MARK: - SearchPhotoElement
struct SearchPhotoElement: Codable {
    let total, totalPages: Int
    let results: [PhotoElement]
    
    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}
