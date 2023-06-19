import Foundation

final class Request {
    
    private struct Constants {
        static let baseUrl = "https://api.unsplash.com/"
    }
    
    enum HTTPMethodType: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    private let endPoint: Endpoint
    
    private let queryParameters: [URLQueryItem]
    
    private var urlString: String {
        
        var string = Constants.baseUrl
        string += endPoint.rawValue
        
        if !queryParameters.isEmpty {
            string += "?"
            
            let argumentString = queryParameters.compactMap {
                guard let value = $0.value else { return nil }
                return "\($0.name)=\(value)"
            }.joined(separator: "&")
            
            string += argumentString
        }
        return string
    }
    
    public var url: URL? {
        let сomponent = URLComponents(string: urlString)
        return сomponent?.url
    }
    
    public let methodType: HTTPMethodType
    
    init(
        endPoint: Endpoint,
        methodType: HTTPMethodType = .get,
        queryParameters: [URLQueryItem] = []
    ) {
        self.endPoint = endPoint
        self.methodType = methodType
        self.queryParameters = queryParameters
    }
}

extension Request {
    
    static func getListPhotos(pageNumber: Int) -> Request {
        return Request(
            endPoint: .getListPhotos,
            queryParameters: [
                URLQueryItem(name: "client_id", value: "T8TuvTdO5imBRrOA46rwOmsrsMrYBS357uBZx-PHBKY"),
                URLQueryItem(name: "page", value: "\(pageNumber)")
            ]
        )
    }
    
    static func searchPhotos(searchText: String) -> Request {
        return Request(
            endPoint: .searchPhotos,
            queryParameters: [
                URLQueryItem(name: "query", value: "\(searchText)"),
                URLQueryItem(name: "client_id", value: "T8TuvTdO5imBRrOA46rwOmsrsMrYBS357uBZx-PHBKY"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        )
    }
}
