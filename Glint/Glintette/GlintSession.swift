//
//  GlintSession.swift
//  Glint
//
//  Created by Marc Prud'hommeaux on 5/23/17.
//  Copyright © 2017 Glimpse I/O. All rights reserved.
//

import Foundation
import Glib
import BricBrac
import GlintModel

let ServerURL = fixme("http://localhost:9000")
let PresentURL = ServerURL + "/v1/present/"

public protocol GlintRequest : Bricable {
    associatedtype Response : Bracable
    static var path: String { get }
}

extension Msg : GlintRequest {
    public typealias Response = Msg
    public static let path = "echo"
}

//extension TreeRequest : GlintRequest {
//    public typealias Response = TreeResponse
//    public static let path = "structure"
//}

extension FormatRequest : GlintRequest {
    public typealias Response = FormatResponse
    public static let path = "format"
}

extension TreeRequest : GlintRequest {
    public typealias Response = TreeResponse
    public static let path = "structure"
}

extension PingRequest : GlintRequest {
    public typealias Response = PingResponse
    public static let path = "ping"
}

public class GlintSession {
    enum RequestError: Error {
        case noResponse
        case parseError(String, Error)
    }
    
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    public init() {
        
    }
    
    public func sendRequest<R: GlintRequest>(_ payload: R, handler: @escaping (Result<R.Response>) -> ()) {
        let url = URL(string: PresentURL + R.path)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            /*
             Beginning with iOS 9 and Mac OS X 10.11, NSURLSessionStream is
             available as a task type.  This allows for direct TCP/IP connection
             to a given host and port with optional secure handshaking and
             navigation of proxies.  Data tasks may also be upgraded to a
             NSURLSessionStream task via the HTTP Upgrade: header and appropriate
             use of the pipelining option of NSURLSessionConfiguration.  See RFC
             2817 and RFC 6455 for information about the Upgrade: header, and
             comments below on turning data tasks into stream tasks.
             */
             "Connection": "Upgrade",
             "Upgrade": "websocket",
        ]
        
        req.httpBody = payload.bric().stringify().data(using: .utf8)
        
        let task = session.dataTask(with: req) { (data, response, error) in
            if let error = error {
                return handler(.failure(error))
            }
            
            guard let str = data.flatMap({ String(data: $0, encoding: .utf8) }) else {
                return handler(.failure(RequestError.noResponse))
            }
            
            //dbg("parsing: \(str)")
            
            do {
                return handler(try .success(R.Response.brac(bric: Bric.parse(str))))
            } catch {
                return handler(Result.failure(error.elaborate(message: "error when prasing: \(str)")))
            }
        }
        task.resume()
    }
}

let sessionQueue = DispatchQueue(label: "GlintSession", attributes: [.concurrent])

public extension GlintSession {
    public func requestSyntax(_ code: String, handler: @escaping (Result<TreeResponse>) -> ()) {
        sessionQueue.async { [unowned self] in
            let req = TreeRequest(src: Src(identifier: fixme("<virtual>"), code: code))
            self.sendRequest(req) { resp in
                handler(resp)
            }
        }
    }
}
