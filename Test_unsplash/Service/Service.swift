import Foundation

final class Service {
    
    enum ServiceError: Error {
        case failedToCreateRequest
        case failedToGetData
        case failedToJsonSerialization
    }
    
    private func request(from req: Request) -> URLRequest? {
        guard let url = req.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = req.methodType.rawValue
        
        return request
    }
    
    public func execute<T: Codable>(
        _ request: Request,
        expecting type: T.Type
    ) async throws -> T? {
        guard let urlRequest = self.request(from: request) else {
            throw ServiceError.failedToCreateRequest
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            return handleResponse(expecting: type, data: data, response: response)
        }
        catch {
            throw ServiceError.failedToJsonSerialization
        }
    }
    
    private func handleResponse<T: Codable>(expecting type: T.Type, data: Data?, response: URLResponse?) -> T? {
        guard
            let data = data,
            let result = try? JSONDecoder().decode(type.self, from: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else {
            return nil
        }
        return result
    }
    
}
