import UIKit
import Combine

struct DetailViewModelRouting {
    let backButtonDidTapSubject = PassthroughSubject<Void, Never>()
}

protocol DetailViewModelInput {
    var didTapLikeSubject: PassthroughSubject<Void, Never> { get }
}

protocol DetailViewModelOutput {
    var photoDataPublisher: AnyPublisher<PhotoElement?, Never> { get }
    var showAlertSaveStorageBasePublisher: AnyPublisher<(title: String?, subtitle: String?), Never> { get }
}

typealias DetailViewModel = DetailViewModelInput & DetailViewModelOutput

final class DetailViewModelImpl: DetailViewModel {
    
    // MARK: - Private Properties
    
    private var routing: DetailViewModelRouting
    private var cancellables: Set<AnyCancellable> = []
    private let storageService = StorageService()
    
    // MARK: - Private Subjects
    private let photoDataSubject = CurrentValueSubject<PhotoElement?, Never>(nil)
    private let alertSaveToStorageSubject = PassthroughSubject<(title: String?, subtitle: String?), Never>()
    
    // MARK: - DetailViewModelInput
    
    var didTapLikeSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - DetailViewModelOutput
    var photoDataPublisher: AnyPublisher<PhotoElement?, Never> {
        photoDataSubject.eraseToAnyPublisher()
    }
    
    var showAlertSaveStorageBasePublisher: AnyPublisher<(title: String?, subtitle: String?), Never> {
        alertSaveToStorageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(routing: DetailViewModelRouting, photoElement: PhotoElement) {
        self.routing = routing
        self.photoDataSubject.send(photoElement)
        configureBindings()
    }
    
    private func configureBindings() {
        didTapLikeSubject
            .sink { [weak self] in
                guard let photo = self?.photoDataSubject.value else { return }
                
                let photoModels = self?.storageService.photoElements
                
                //Check if the photo is already in the database
                let isPhotoModelsAlreadySaved = photoModels?.contains(where: { $0.id == photo.id }) ?? false
                
                //Save the photo only if it's not already in the storage
                if !isPhotoModelsAlreadySaved {
                    self?.storageService.photoElements.append(photo)
                    self?.alertSaveToStorageSubject.send((title: "Great!", subtitle: "Your photo has been added to favorites"))
                } else {
                    self?.alertSaveToStorageSubject.send((title: "Error", subtitle: "Photo is already in the Favorites"))
                }
            }
            .store(in: &cancellables)
    }
}
