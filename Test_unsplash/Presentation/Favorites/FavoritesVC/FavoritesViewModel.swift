import UIKit
import Combine

struct FavoritesViewModelRouting {
    let detailDidTapSubject = PassthroughSubject<PhotoElement, Never>()
}

protocol FavoritesViewModelInput {
    var updateStorageServiceSubject: PassthroughSubject<Void, Never> { get }
    var deleteStorageServiceSubject: PassthroughSubject<PhotoElement, Never> { get }
    var detailCellDidTapSubject: PassthroughSubject<PhotoElement, Never> { get set }
}

protocol FavoritesViewModelOutput {
    var updateStorageServicePublisher: AnyPublisher<[PhotoElement], Never> { get }
}

typealias FavoritesViewModel = FavoritesViewModelInput & FavoritesViewModelOutput

final class FavoritesViewModelImpl: FavoritesViewModel {
    
    // MARK: - Private Properties
    
    private let storageService = StorageService()
    private var routing: FavoritesViewModelRouting
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Private Subjects
    
    var getStorageServicePublisherSubject = PassthroughSubject<[PhotoElement], Never>()
    
    // MARK: - FavoritesViewModelInput
    
    let updateStorageServiceSubject = PassthroughSubject<Void, Never>()
    let deleteStorageServiceSubject = PassthroughSubject<PhotoElement, Never>()
    var detailCellDidTapSubject = PassthroughSubject<PhotoElement, Never>()
    
    // MARK: - FavoritesViewModelOutput
    
    var updateStorageServicePublisher: AnyPublisher<[PhotoElement], Never> {
        getStorageServicePublisherSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(routing: FavoritesViewModelRouting) {
        self.routing = routing
        configureBindings()
    }
    
    private func configureBindings() {
        
        updateStorageServiceSubject
            .sink { [weak self] _ in
                let photoElementModels = self?.storageService.photoElements
                self?.getStorageServicePublisherSubject.send(photoElementModels ?? [])
            }
            .store(in: &cancellables)
        
        deleteStorageServiceSubject
            .sink { [weak self] photoElement in
                self?.storageService.removeItem(photoElement)
                let photoElementModels = self?.storageService.photoElements
                self?.getStorageServicePublisherSubject.send(photoElementModels ?? [])
            }
            .store(in: &cancellables)
        
        detailCellDidTapSubject
            .sink { [weak self] photo in
                guard let self = self else { return }
                self.routing.detailDidTapSubject.send(photo)
            }
            .store(in: &cancellables)
    }
}
