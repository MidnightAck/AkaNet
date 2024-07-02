//
//  MoyaProvider+Internal.swift
//  NetworkService
//
//  Created by fushiguro on 2024/2/20.
//

import Foundation

// MARK: - Method

public extension Method {
    /// A Boolean value determining whether the request supports multipart.
    var supportsMultipart: Bool {
        switch self {
        case .post, .put, .patch, .connect:
            return true
        default:
            return false
        }
    }
}

// MARK: - MoyaProvider

/// Internal extension to keep the inner-workings outside the main Moya.swift file.
public extension MoyaProvider {
    /// Performs normal requests.
    func requestNormal(_ target: Target, callbackQueue: DispatchQueue?, progress: ProgressBlock?, priority: RequestPriority, completion: @escaping Completion) -> MoyaCancellable {
        let endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        let cancellableToken = CancellableWrapper()

        // Allow plugins to modify response
        let pluginsWithCompletion: Completion = { result in
            let processedResult = self.plugins.reduce(result) { $1.process($0, target: target) }
            completion(processedResult)
        }
        if trackInflights {
            var inflightCompletionBlocks = self.inflightRequests[endpoint]
            inflightCompletionBlocks?.append(pluginsWithCompletion)
            self.internalInflightRequests[endpoint] = inflightCompletionBlocks

            if inflightCompletionBlocks != nil {
                return cancellableToken
            } else {
                self.internalInflightRequests[endpoint] = [pluginsWithCompletion]
            }
        }

        let performNetworking = { [weak self] (requestResult: Result<URLRequest, MoyaError>) in
            guard let self = self else { return }
            MoyaService.synchronizationQueue.async { [weak self] in
                guard let self else { return }
                AkaNetLogAdapter.shared.log(custom: ["path" : target.path,
                                                    "body": target.bodyParams,
                                                    "active_request_num": MoyaService.activeRequests,
                                                    "pool_limit": MoyaService.requestPoolLimit,
                                                    "is_stub": MoyaService.activeRequests >= MoyaService.requestPoolLimit])
                if MoyaService.activeRequests >= MoyaService.requestPoolLimit {
                    addRequestToQueue({
                        MoyaService.activeRequests += 1
                        self.performNetworkingAction(requestResult, target: target, cancellableToken: cancellableToken, pluginsWithCompletion: completion, callbackQueue: callbackQueue, progress: progress, endpoint: endpoint, stubBehavior: stubBehavior)
                    }, priority: priority)
                } else {
                    MoyaService.activeRequests += 1

                    DispatchQueue.main.async {

                        self.performNetworkingAction(requestResult, target: target, cancellableToken: cancellableToken, pluginsWithCompletion: completion, callbackQueue: callbackQueue, progress: progress, endpoint: endpoint, stubBehavior: stubBehavior)
                    }
                }
            }
        }
        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }
    
    private func performNetworkingAction(_ requestResult: Result<URLRequest, MoyaError>, target: Target, cancellableToken: CancellableWrapper, pluginsWithCompletion: @escaping Completion, callbackQueue: DispatchQueue?, progress: ProgressBlock?, endpoint: Endpoint, stubBehavior: StubBehavior) -> MoyaCancellable {
        switch requestResult {
        case .success(let urlRequest):
            let request = urlRequest
            let networkCompletion: Completion = { [weak self] result in
                MoyaService.synchronizationQueue.async {
                    MoyaService.activeRequests -= 1
                    if !MoyaService.waitingRequestsQueue.isEmpty {
                        let nextRequest = MoyaService.waitingRequestsQueue.removeFirst().0
                        DispatchQueue.main.async {
                            nextRequest()
                        }
                    }
                }
                
                (callbackQueue ?? DispatchQueue.main).async {
                    pluginsWithCompletion(result)
                }
            }

            cancellableToken.innerCancellable = self.performRequest(target, request: request, callbackQueue: callbackQueue, progress: progress, completion: networkCompletion, endpoint: endpoint, stubBehavior: stubBehavior)
            
        case .failure(let error):
            (callbackQueue ?? DispatchQueue.main).async {
                pluginsWithCompletion(.failure(error))
            }
            MoyaService.synchronizationQueue.async {
                MoyaService.activeRequests -= 1
                if !MoyaService.waitingRequestsQueue.isEmpty {
                    let nextRequest = MoyaService.waitingRequestsQueue.removeFirst().0
                    DispatchQueue.main.async {
                        nextRequest()
                    }
                }
            }
        }
        return cancellableToken

    }


    // swiftlint:disable:next function_parameter_count
    private func performRequest(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, progress: ProgressBlock?, completion: @escaping Completion, endpoint: Endpoint, stubBehavior: StubBehavior) -> MoyaCancellable {
        switch stubBehavior {
        case .never:
            switch endpoint.task {
            case .requestPlain, .requestData, .requestJSONEncodable, .requestCustomJSONEncodable, .requestParameters, .requestCompositeData, .requestCompositeParameters:
                return self.sendRequest(target, request: request, callbackQueue: callbackQueue, progress: progress, completion: completion)
            case .uploadFile(let file):
                return self.sendUploadFile(target, request: request, callbackQueue: callbackQueue, file: file, progress: progress, completion: completion)
            case .uploadMultipart(let multipartBody), .uploadCompositeMultipart(let multipartBody, _):
                guard !multipartBody.isEmpty && endpoint.method.supportsMultipart else {
                    fatalError("\(target) is not a multipart upload target.")
                }
                return self.sendUploadMultipart(target, request: request, callbackQueue: callbackQueue, multipartBody: multipartBody, progress: progress, completion: completion)
            case .downloadDestination(let destination), .downloadParameters(_, _, let destination):
                return self.sendDownloadRequest(target, request: request, callbackQueue: callbackQueue, destination: destination, progress: progress, completion: completion)
            }
        default:
            return self.stubRequest(target, request: request, callbackQueue: callbackQueue, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
        }
    }

    func cancelCompletion(_ completion: Completion, target: Target) {
        let error = MoyaError.underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil), nil)
        plugins.forEach { $0.didReceive(.failure(error), target: target) }
        completion(.failure(error))
    }

    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    final func createStubFunction(_ token: CancellableToken, forTarget target: Target, withCompletion completion: @escaping Completion, endpoint: Endpoint, plugins: [PluginType], request: URLRequest) -> (() -> Void) { // swiftlint:disable:this function_parameter_count
        return {
            if token.isCancelled {
                self.cancelCompletion(completion, target: target)
                return
            }

            let validate = { (response: Response) -> Result<Response, MoyaError> in
                let validCodes = target.validationType.statusCodes
                guard !validCodes.isEmpty else { return .success(response) }
                if validCodes.contains(response.statusCode) {
                    return .success(response)
                } else {
                    let statusError = MoyaError.statusCode(response)
                    let error = MoyaError.underlying(statusError, response)
                    return .failure(error)
                }
            }

            switch endpoint.sampleResponseClosure() {
            case .networkResponse(let statusCode, let data):
                let response = Response(statusCode: statusCode, data: data, request: request, response: nil)
                let result = validate(response)
                plugins.forEach { $0.didReceive(result, target: target) }
                completion(result)
            case .response(let customResponse, let data):
                let response = Response(statusCode: customResponse.statusCode, data: data, request: request, response: customResponse)
                let result = validate(response)
                plugins.forEach { $0.didReceive(result, target: target) }
                completion(result)
            case .networkError(let error):
                let error = MoyaError.underlying(error, nil)
                plugins.forEach { $0.didReceive(.failure(error), target: target) }
                completion(.failure(error))
            }
        }
    }

    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    final func notifyPluginsOfImpendingStub(for request: URLRequest, target: Target) -> URLRequest {
        let alamoRequest = session.request(request)
        alamoRequest.cancel()

        let preparedRequest = plugins.reduce(request) { $1.prepare($0, target: target) }

        let stubbedAlamoRequest = RequestTypeWrapper(request: alamoRequest, urlRequest: preparedRequest)
        plugins.forEach { $0.willSend(stubbedAlamoRequest, target: target) }

        return preparedRequest
    }
}

private extension MoyaProvider {
    private func interceptor(target: Target) -> MoyaRequestInterceptor {
        return MoyaRequestInterceptor(prepare: { [weak self] urlRequest in
            return self?.plugins.reduce(urlRequest) { $1.prepare($0, target: target) } ?? urlRequest
       })
    }

    private func setup(interceptor: MoyaRequestInterceptor, with target: Target, and request: Request) {
        interceptor.willSend = { [weak self, weak request] urlRequest in
            guard let self = self, let request = request else { return }

            let stubbedAlamoRequest = RequestTypeWrapper(request: request, urlRequest: urlRequest)
            self.plugins.forEach { $0.willSend(stubbedAlamoRequest, target: target) }
        }
    }

    func sendUploadMultipart(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, multipartBody: [MultipartFormData], progress: ProgressBlock? = nil, completion: @escaping Completion) -> CancellableToken {
        let formData = RequestMultipartFormData()
        formData.applyMoyaMultipartFormData(multipartBody)

        let interceptor = self.interceptor(target: target)
        let uploadRequest: UploadRequest = session.requestQueue.sync {
            let uploadRequest = session.upload(multipartFormData: formData, with: request, interceptor: interceptor)
            setup(interceptor: interceptor, with: target, and: uploadRequest)

            return uploadRequest
        }

        let validationCodes = target.validationType.statusCodes
        let validatedRequest = validationCodes.isEmpty ? uploadRequest : uploadRequest.validate(statusCode: validationCodes)
        return sendAlamofireRequest(validatedRequest, target: target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }

    func sendUploadFile(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, file: URL, progress: ProgressBlock? = nil, completion: @escaping Completion) -> CancellableToken {
        let interceptor = self.interceptor(target: target)
        let uploadRequest: UploadRequest = session.requestQueue.sync {
            let uploadRequest = session.upload(file, with: request, interceptor: interceptor)
            setup(interceptor: interceptor, with: target, and: uploadRequest)

            return uploadRequest
        }

        let validationCodes = target.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? uploadRequest : uploadRequest.validate(statusCode: validationCodes)
        return sendAlamofireRequest(alamoRequest, target: target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }

    func sendDownloadRequest(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, destination: @escaping DownloadDestination, progress: ProgressBlock? = nil, completion: @escaping Completion) -> CancellableToken {
        let interceptor = self.interceptor(target: target)
        let downloadRequest: DownloadRequest = session.requestQueue.sync {
            let downloadRequest = session.download(request, interceptor: interceptor, to: destination)
            setup(interceptor: interceptor, with: target, and: downloadRequest)

            return downloadRequest
        }

        let validationCodes = target.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? downloadRequest : downloadRequest.validate(statusCode: validationCodes)
        return sendAlamofireRequest(alamoRequest, target: target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }

    func sendRequest(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, progress: ProgressBlock?, completion: @escaping Completion) -> CancellableToken {
        let interceptor = self.interceptor(target: target)
        let initialRequest: DataRequest = session.requestQueue.sync {
            let initialRequest = session.request(request, interceptor: interceptor)
            setup(interceptor: interceptor, with: target, and: initialRequest)

            return initialRequest
        }

        let validationCodes = target.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? initialRequest : initialRequest.validate(statusCode: validationCodes)
        return sendAlamofireRequest(alamoRequest, target: target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func sendAlamofireRequest<T>(_ alamoRequest: T, target: Target, callbackQueue: DispatchQueue?, progress progressCompletion: ProgressBlock?, completion: @escaping Completion) -> CancellableToken where T: Requestable, T: Request {
        // Give plugins the chance to alter the outgoing request
        let plugins = self.plugins
        var progressAlamoRequest = alamoRequest
        let progressClosure: (Progress) -> Void = { progress in
            let sendProgress: () -> Void = {
                progressCompletion?(ProgressResponse(progress: progress))
            }

            if let callbackQueue = callbackQueue {
                callbackQueue.async(execute: sendProgress)
            } else {
                sendProgress()
            }
        }

        // Perform the actual request
        if progressCompletion != nil {
            switch progressAlamoRequest {
            case let downloadRequest as DownloadRequest:
                if let downloadRequest = downloadRequest.downloadProgress(closure: progressClosure) as? T {
                    progressAlamoRequest = downloadRequest
                }
            case let uploadRequest as UploadRequest:
                if let uploadRequest = uploadRequest.uploadProgress(closure: progressClosure) as? T {
                    progressAlamoRequest = uploadRequest
                }
            case let dataRequest as DataRequest:
                if let dataRequest = dataRequest.downloadProgress(closure: progressClosure) as? T {
                    progressAlamoRequest = dataRequest
                }
            default: break
            }
        }

        let completionHandler: RequestableCompletion = { response, request, data, error in
            let result = convertResponseToResult(response, request: request, data: data, error: error)
            // Inform all plugins about the response
            plugins.forEach { $0.didReceive(result, target: target) }
            if let progressCompletion = progressCompletion {
                let value = try? result.get()
                switch progressAlamoRequest {
                case let downloadRequest as DownloadRequest:
                    progressCompletion(ProgressResponse(progress: downloadRequest.downloadProgress, response: value))
                case let uploadRequest as UploadRequest:
                    progressCompletion(ProgressResponse(progress: uploadRequest.uploadProgress, response: value))
                case let dataRequest as DataRequest:
                    progressCompletion(ProgressResponse(progress: dataRequest.downloadProgress, response: value))
                default:
                    progressCompletion(ProgressResponse(response: value))
                }
            }
            completion(result)
        }

        progressAlamoRequest = progressAlamoRequest.response(callbackQueue: callbackQueue, completionHandler: completionHandler)

        progressAlamoRequest.resume()

        return CancellableToken(request: progressAlamoRequest)
    }
}
