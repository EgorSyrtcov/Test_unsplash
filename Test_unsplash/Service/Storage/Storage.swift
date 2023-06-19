import Foundation

fileprivate enum SessionUserDefaultKey: String {
    case photo = "photo"
    var key: String { return rawValue }
}

final class StorageService {
 
    private let userDefaults = UserDefaults.standard
    
    var photoElements: [PhotoElement] {
        get {
            guard let data = userDefaults.value(forKey: SessionUserDefaultKey.photo.key) as? Data,
                  let items = try? PropertyListDecoder().decode([PhotoElement].self, from: data) else { return [] }
            return items
        }
        
        set {
            guard let data = try? PropertyListEncoder().encode(newValue) else { return }
            userDefaults.set(data, forKey: SessionUserDefaultKey.photo.key)
        }
    }
    
    func removeItem(_ photoElement: PhotoElement) {
        var photoElementsModels = photoElements
        if let index = photoElementsModels.firstIndex(where: { $0.id == photoElement.id }) {
            photoElementsModels.remove(at: index)
        }
        self.photoElements = photoElementsModels
    }
}


