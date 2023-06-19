import UIKit
import Combine

struct MainViewModelRouting {
    let detailDidTapSubject = PassthroughSubject<PhotoElement, Never>()
}

protocol MainViewModelInput {
    var scrollLoadingMoreSubject: PassthroughSubject<Void, Never> { get }
    var searchTextSubject: PassthroughSubject<String?, Never> { get set }
    var detailCellDidTapSubject: PassthroughSubject<PhotoElement, Never> { get set }
}

protocol MainViewModelOutput {
    var updatePhotoPublisher: AnyPublisher<[PhotoElement], Never> { get }
    var updatePhotoSearchPublisher: AnyPublisher<[PhotoElement], Never> { get }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var errorPublisher: AnyPublisher<(title: String?, subtitle: String?), Never> { get }
}

typealias MainViewModel = MainViewModelInput & MainViewModelOutput

final class MainViewModelImpl: MainViewModel {
    
    // MARK: - Private Properties
    
    private var routing: MainViewModelRouting
    private var cancellables: Set<AnyCancellable> = []
    private let service = Service()
    
    // MARK: - Private Subjects
    
    private let photoElementsSubject = CurrentValueSubject<[PhotoElement], Never>([])
    private let photoSearchElementsSubject = CurrentValueSubject<[PhotoElement], Never>([])
    private let errorSubject = CurrentValueSubject<(title: String?, subtitle: String?), Never>((title: nil, subtitle: nil))
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private var currentPhotoPage = 1
    
    // MARK: - MainViewModelInput
    
    var scrollLoadingMoreSubject = PassthroughSubject<Void, Never>()
    var searchTextSubject = PassthroughSubject<String?, Never>()
    var detailCellDidTapSubject = PassthroughSubject<PhotoElement, Never>()
    
    // MARK: - MainViewModelOutput
    
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }
    
    var updatePhotoPublisher: AnyPublisher<[PhotoElement], Never> {
        photoElementsSubject
            .eraseToAnyPublisher()
    }
    
    var updatePhotoSearchPublisher: AnyPublisher<[PhotoElement], Never> {
        photoSearchElementsSubject
            .eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<(title: String?, subtitle: String?), Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(routing: MainViewModelRouting) {
        self.routing = routing
        configureBindings()
        
        Task {
            try? await requestPhotos(page: currentPhotoPage)
        }
    }
    
    private func configureBindings() {
        
        scrollLoadingMoreSubject
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentPhotoPage+=1
                
                Task {
                    try? await self.requestPhotos(page: self.currentPhotoPage)
                }
            }
            .store(in: &cancellables)
        
        searchTextSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self, let searchText = searchText else { return }
                
                Task {
                    do {
                        try await self.requestSearchPhotos(searchText: searchText)
                    } catch {
                        // Handle any errors here
                    }
                }
            }
            .store(in: &cancellables)
        
        detailCellDidTapSubject
            .sink { [weak self] photo in
                guard let self = self else { return }
                self.routing.detailDidTapSubject.send(photo)
            }
            .store(in: &cancellables)
        
    }
    
    private func requestPhotos(page: Int) async throws {
        
        isLoadingSubject.send(true)
        
        let photoElements: [PhotoElement]?
        
        do {
            photoElements = try await service.execute(.getListPhotos(pageNumber: page), expecting: [PhotoElement].self)
        }
        catch {
            errorSubject.send((title: error.localizedDescription, subtitle: "Try again"))
            isLoadingSubject.send(false)
            return
        }
        
        await MainActor.run { [weak self] in
            self?.photoElementsSubject.send(photoElements ?? [])
            isLoadingSubject.send(false)
        }
    }
    
    private func requestSearchPhotos(searchText: String) async throws {
        isLoadingSubject.send(true)
        
        let searchPhotoElements: SearchPhotoElement?
        
        do {
            searchPhotoElements = try await service.execute(.searchPhotos(searchText: searchText), expecting: SearchPhotoElement.self)
        } catch {
            errorSubject.send((title: error.localizedDescription, subtitle: "Try again"))
            isLoadingSubject.send(false)
            return
        }
        
        let photoElements: [PhotoElement] = searchPhotoElements.flatMap { $0.results }!
        
        await MainActor.run { [weak self] in
            self?.photoSearchElementsSubject.send(photoElements)
            isLoadingSubject.send(false)
        }
    }
}
