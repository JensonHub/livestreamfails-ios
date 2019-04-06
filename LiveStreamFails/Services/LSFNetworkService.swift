//
//  LSFNetworkService.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-03-28.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit
import Reachability

let TTReachabilityServiceUpdated:String = "TTReachabilityServiceUpdated"

public enum Method: String, CustomStringConvertible {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
    
    public var description: String {
        return self.rawValue
    }
}

public struct Resource<A>: CustomStringConvertible {
    let path: String
    let method: Method
    let requestBody: NSData?
    let headers: [String:String]
    let parse: (NSData) -> A?
    
    public var description: String {
        var strRequestBody: String = ""
        if let requestBody = requestBody {
            strRequestBody = NSString(data: requestBody as Data, encoding: String.Encoding.utf8.rawValue)! as String
        }
        
        return "Resource(Method: \(method), path: \(path), headers: \(headers), requestBody: \(strRequestBody))"
    }
}

public enum Reason: CustomStringConvertible {
    case CouldNotParse
    case NoData
    case NoSuccessStatusCode(statusCode: Int)
    case Other(NSError?)
    
    public var description: String {
        switch self {
        case .CouldNotParse:
            return "CouldNotParse"
        case .NoData:
            return "NoData"
        case .NoSuccessStatusCode(let statusCode):
            return "NoSuccessStatusCode: \(statusCode)"
        case .Other(let error):
            return "Other, Error: \(String(describing: error?.description))"
        }
    }
}

func defaultFailureHandler(reason: Reason, errorMessage: String?) {
    println("\n***************************** LSFNetworkService Failure *****************************")
    println("Reason: \(reason)")
    if let errorMessage = errorMessage {
        println("errorMessage: >>>\(errorMessage)<<<\n")
    }
}

func queryComponents(key: String, value: AnyObject) -> [(String, String)] {
    func escape(string: String) -> String {
        let legalURLCharactersToBeEscaped: CFString = ":/?&=;+!@#$()',*" as CFString
        return CFURLCreateStringByAddingPercentEscapes(nil, string as CFString!, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
    var components: [(String, String)] = []
    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += queryComponents(key: "\(key)[\(nestedKey)]", value: value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += queryComponents(key: "\(key)[]", value: value)
        }
    } else {
        components.append(contentsOf: [(escape(string: key), escape(string: "\(value)"))])
    }
    
    return components
}

var networkActivityCount = 0 {
    didSet {
        UIApplication.shared.isNetworkActivityIndicatorVisible = (networkActivityCount > 0)
    }
}

public func apiRequest<A>(modifyRequest: (NSMutableURLRequest) -> (), baseURL: NSURL, resource: Resource<A>, failure: @escaping (Reason, String?) -> Void, completion: @escaping (A) -> Void) {
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession.init(configuration: sessionConfig)
    
    let url = baseURL.appendingPathComponent(resource.path)
    let request = NSMutableURLRequest(url: url!)
    request.httpMethod = resource.method.rawValue
    
    func needEncodesParametersForMethod(method: Method) -> Bool {
        switch method {
        case .GET, .HEAD, .DELETE:
            return true
        default:
            return false
        }
    }
    
    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in Array(parameters.keys).sorted(by: <) {
            let value: AnyObject! = parameters[key]
            components += queryComponents(key: key, value: value)
        }
        
        return (components.map{"\($0)=\($1)"} as [String]).joined(separator: "&")
    }
    
    if needEncodesParametersForMethod(method: resource.method) {
        if let requestBody = resource.requestBody {
            if let URLComponents = NSURLComponents(url: request.url!, resolvingAgainstBaseURL: false) {
                URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(parameters: decodeJSON(data: requestBody)!)
                request.url = URLComponents.url
            }
        }
        
    } else {
        request.httpBody = resource.requestBody as Data?
    }
    
    modifyRequest(request)
    
    for (key, value) in resource.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if let responseData = data {
                    if let result = resource.parse(responseData as NSData) {
                        completion(result)
                    } else {
                        let dataString = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue)
                        println("\(String(describing: dataString))\n")
                        
                        failure(Reason.CouldNotParse, errorMessageInData(data: data as NSData?))
                        println("\(resource)\n")
                    }
                } else {
                    failure(Reason.NoData, errorMessageInData(data: data as NSData?))
                    println("\(resource)\n")
                }
            } else {
                failure(Reason.NoSuccessStatusCode(statusCode: httpResponse.statusCode), errorMessageInData(data: data as NSData?))
                println("\(resource)\n")
            }
        } else {
            failure(Reason.Other(error as NSError?), errorMessageInData(data: data as NSData?))
            println("\(resource)")
        }
        
        DispatchQueue.main.async {
            networkActivityCount -= 1
        }
    }
    
    task.resume()
    
    DispatchQueue.main.async {
        networkActivityCount += 1
    }
}

func errorMessageInData(data: NSData?) -> String? {
    if let data = data {
        return NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
    }
    
    return nil
}

public typealias JSONDictionary = [String: AnyObject]
func decodeJSON(data: NSData) -> JSONDictionary? {
    if data.length > 0 {
        guard let result = try? JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions()) else {
            return JSONDictionary()
        }
        
        if let dictionary = result as? JSONDictionary {
            return dictionary
        } else if let array = result as? [JSONDictionary] {
            return ["data": array as AnyObject]
        } else {
            return JSONDictionary()
        }
        
    } else {
        return JSONDictionary()
    }
}

func encodeJSON(dict: JSONDictionary) -> NSData? {
    return dict.count > 0 ? (try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())) as NSData? : nil
}

public func jsonResource<A>(path: String, method: Method, requestParameters: JSONDictionary, parse: @escaping (NSData) -> A?) -> Resource<A> {
    return jsonResource(token: nil, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func authJsonResource<A>(path: String, method: Method, requestParameters: JSONDictionary, parse: @escaping (NSData) -> A?) -> Resource<A> {
    let token = "" //AccessToken
    return jsonResource(token: token, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func jsonResource<A>(token: String?, path: String, method: Method, requestParameters: JSONDictionary, parse: @escaping (NSData) -> A?) -> Resource<A> {
    let jsonBody = encodeJSON(dict: requestParameters)
    var headers = [
        "Content-Type": "application/json",
        ]
    if let token = token {
        headers["Authorization"] = "Bearer \(token)"
    }
    
    let locale = NSLocale.autoupdatingCurrent
    if let languageCode = locale.languageCode, let countryCode = locale.regionCode {
        headers["Accept-Language"] = languageCode + "-" + countryCode
    }
    
    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: parse)
}

class TTReachabilityService: NSObject {
    static let sharedManager = TTReachabilityService()
    
    let reachability = Reachability(hostname: "https://livestreamfails.com")
    
    class func turnOn() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged(_:)), name: Notification.Name.reachabilityChanged, object: nil)
        do{
            try self.sharedManager.reachability?.startNotifier()
        }catch{
            println("could not start reachability notifier")
        }
    }
    
    @objc class func reachabilityChanged(_ note: NSNotification) {
        let reachability = note.object as! Reachability
        switch reachability.connection {
        case .wifi:
            println("Reachable via WiFi") //push Notification
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TTReachabilityServiceUpdated"), object: nil)
        case .cellular:
            println("Reachable via Cellular") //push Notification
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TTReachabilityServiceUpdated"), object: nil)
        case .none:
            println("Network not reachable") //push Notification
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TTReachabilityServiceUpdated"), object: nil)
        }
    }
}
