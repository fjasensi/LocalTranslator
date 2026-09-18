import Foundation

struct ModelsResponse: Decodable {
    let models: [Model]
}

struct OutputResponse: Decodable {
    let output: [Output]
}

struct Output: Decodable {
    let type: String
    let content: String
}

struct Model: Decodable {
    let type: String
    let publisher: String
    let key: String
    let displayName: String
    let loadedInstances: [LoadedInstance]

    var isLoaded: Bool {
        !loadedInstances.isEmpty
    }

    enum CodingKeys: String, CodingKey {
        case type
        case publisher
        case key
        case displayName = "display_name"
        case loadedInstances = "loaded_instances"
    }
}

struct LoadedInstance: Decodable {
    let id: String
}

struct ChatRequest: Encodable {
    let model: String
    let input: String
}

enum LMStudioError: LocalizedError {
    case modelNotLoaded(String)
    case invalidResponse
    case serverError(statusCode: Int)
    case missingMessage

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded(let modelKey):
            return "The model \(modelKey) is not loaded in LM Studio"
        case .invalidResponse:
            return "LM Studio returned an invalid response"
        case .serverError(let statusCode):
            return "LM Studio returned HTTP status \(statusCode)"
        case .missingMessage:
            return "LM Studio did not return a message"
        }
    }
}

struct LMStudioClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func translate(
        _ text: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        using modelKey: String
    ) async throws -> String {
        try await ensureModelIsLoaded(modelKey)

        let requestBody = ChatRequest(
            model: modelKey,
            input: composePrompt(
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                textToTranslate: text
            )
        )

        let response = try await post(
            OutputResponse.self,
            path: "chat",
            body: requestBody
        )

        guard let message = response.output.first(where: { output in
            output.type == "message"
        }) else {
            throw LMStudioError.missingMessage
        }

        return message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func ensureModelIsLoaded(_ modelKey: String) async throws {
        let response = try await get(ModelsResponse.self, path: "models")

        guard response.models.contains(where: { model in
            model.key == modelKey && model.isLoaded
        }) else {
            throw LMStudioError.modelNotLoaded(modelKey)
        }
    }

    private func get<Response: Decodable>(
        _ type: Response.Type,
        path: String
    ) async throws -> Response {
        let request = makeRequest(path: path, method: "GET")
        return try await send(request, decoding: type)
    }

    private func post<Body: Encodable, Response: Decodable>(
        _ type: Response.Type,
        path: String,
        body: Body
    ) async throws -> Response {
        let bodyData = try JSONEncoder().encode(body)
        let request = makeRequest(
            path: path,
            method: "POST",
            body: bodyData
        )
        return try await send(request, decoding: type)
    }

    private func makeRequest(
        path: String,
        method: String,
        body: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func send<Response: Decodable>(
        _ request: URLRequest,
        decoding type: Response.Type
    ) async throws -> Response {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LMStudioError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LMStudioError.serverError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(type, from: data)
    }
}

func composePrompt(
    sourceLanguage: String,
    targetLanguage: String,
    textToTranslate: String
) -> String {
    """
    Translate the following text from \(sourceLanguage) to \(targetLanguage).
    Return only the translation.
    /no_think
    \(textToTranslate)
    """
}

enum AppConfiguration {
    static let sourceLanguage = "spanish"
    static let targetLanguage = "english"
    static let textToTranslate = "Necesito unas vacaciones"
    static let modelKey = "qwen/qwen3-1.7b"
    static let baseURL = URL(string: "http://127.0.0.1:1234/api/v1/")!
}

let client = LMStudioClient(baseURL: AppConfiguration.baseURL)

do {
    let translation = try await client.translate(
        AppConfiguration.textToTranslate,
        from: AppConfiguration.sourceLanguage,
        to: AppConfiguration.targetLanguage,
        using: AppConfiguration.modelKey
    )

    print(translation)
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
