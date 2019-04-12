//
//  LSFService.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-03-28.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftSoup

let spBaseURL = NSURL(string: "https://livestreamfails.com")!

public enum PostMode: String, CustomStringConvertible {
    case STANDARD = "standard"
    case STREAMER = "streamer"
    case GAME = "game"
    case SEARCH = "search"
    
    public var description: String {
        return self.rawValue
    }
}

public enum PostOrder: String, CustomStringConvertible {
    case HOT = "hot"
    case TOP = "top"
    case NEW = "new"
    case RANDOM = "random"
    
    public var description: String {
        return self.rawValue
    }
}

public enum PostTimeFrame: String, CustomStringConvertible {
    case DAY = "day"
    case WEEK = "week"
    case MONTH = "month"
    case YEAR = "year"
    case ALL = "all"
    
    public var description: String {
        return self.rawValue
    }
}

func getStreamerDetail(streamerID: String, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (Streamer) -> Void) {
    let requestParameters: JSONDictionary = [:]
    
    let parse: (NSData) -> Streamer? = { data in
        if let data = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
            //println("get Streamer Detail response \(data)")
            
            do {
                let doc: Document = try SwiftSoup.parse(data as String)
                let els: Elements = try doc.select("div.d-flex")
                
                let streamer = Streamer()
                
                //get name
                if let nameElement = try els.select("div.lh-100 > h5").first() {
                    streamer.name = try nameElement.text()
                }
                
                //get avatarURL
                if let imageElement = try els.select("img").first() {
                    streamer.avatarURL = try imageElement.attr("src")
                }
                
                //get twitchURL
                if let twitchInfoElement = try els.select("div.lh-100 > small > a").first() {
                    streamer.twitchURL = try twitchInfoElement.attr("href")
                }
                
                return streamer
            } catch Exception.Error( _, let message) {
                println(message)
            } catch {
                println("error")
            }
        }
        return nil
    }
    
    let resource = jsonResource(path: "/streamer/" + streamerID, method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    if let failureHandler = failureHandler {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

func getStreamer(page: Int, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping ([Streamer]) -> Void) {
    let requestParameters = [
        "loadStreamerOrder": "amount",
        "loadStreamerPage": page,
        ] as [String : Any]
    
    let parse: (NSData) -> [Streamer]? = { data in
        if let data = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue){
            //println("get Streamer response \(data)")
            
            do {
                let doc: Document = try SwiftSoup.parse(data as String)
                let els: Elements = try doc.select("div.post-card")
                var streamerList = [Streamer]()
                for element: Element in els.array() {
                    let newStreamer = Streamer()
                    
                    //get name
                    if let nameElement = try element.select("p.card-text.title").first() {
                        newStreamer.name = try nameElement.text()
                    }
                    
                    //get avatarURL
                    if let imageElement = try element.select("img.card-img-top").first() {
                        newStreamer.avatarURL = try imageElement.attr("src")
                    }
                    
                    streamerList.append(newStreamer)
                }
                
                return streamerList
            } catch Exception.Error( _, let message) {
                println(message)
            } catch {
                println("error")
            }
        }
        return nil
    }
    
    //println("get Streamer request \(requestParameters)")
    let resource = jsonResource(path: "load/loadStreamers.php", method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    if let failureHandler = failureHandler {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

func getPostDetail(postID: String, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (PostDetail) -> Void) {
    let requestParameters: JSONDictionary = [:]
    
    let parse: (NSData) -> PostDetail? = { data in
        if let data = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
            //println("get Post Detail response \(data)")
            
            do {
                let doc: Document = try SwiftSoup.parse(data as String)
                
                let postDetail = PostDetail()
                if let videoElement = try doc.select("video > source").first() {
                    postDetail.videoURL = try videoElement.attr("src")
                }
                
                postDetail.post = Post()
                postDetail.post!.postID = postID;
                
                if let nameElement = try doc.select("h4.post-title").first() {
                    postDetail.post!.name = try nameElement.text()
                }
                
                if let thumbnailElement = try doc.select("video ").first(){
                    postDetail.post!.thumbnailURL = try thumbnailElement.attr("poster")
                }
                
                let infoElements = try doc.select("div.post-streamer-info > a")
                for infoElement in infoElements.array() {
                    let urlElement = try infoElement.attr("href") as NSString
                    if urlElement.contains("streamer") {
                        postDetail.post!.streamerID = urlElement.lastPathComponent
                        postDetail.post!.streamer = try infoElement.text()
                    } else if urlElement.contains("game") {
                        postDetail.post!.gameID = urlElement.lastPathComponent
                        postDetail.post!.game = try infoElement.text()
                    }
                }
                
                if let statsInfo = try doc.select("div.post-stats-info").first() {
                    let pointElements = (try statsInfo.text()).components(separatedBy: " · ")
                    for pointElement in pointElements {
                        if pointElement.contains("points") {
                            postDetail.post!.point = pointElement
                        } else if pointElement.contains("ago") {
                            postDetail.post!.date = pointElement
                        }
                    }
                }
                
                return postDetail
            } catch Exception.Error( _, let message) {
                println(message)
            } catch {
                println("error")
            }
        }
        return nil
    }
    
    //println("get Post Detail request \(requestParameters)")
    let resource = jsonResource(path: "/post/" + postID, method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    if let failureHandler = failureHandler {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

func getPost(page: Int, mode: PostMode, order: PostOrder, timeFrame: PostTimeFrame, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping ([Post]) -> Void) {
    let requestParameters = [
        "loadPostPage": page,
        "loadPostMode": mode.rawValue,
        "loadPostOrder": order.rawValue,
        "loadPostTimeFrame": timeFrame.rawValue,
        "loadPostNSFW": 0,
        ] as [String : Any]

    let parse: (NSData) -> [Post]? = { data in
        if let data = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
            //println("get Post response \(data)")
            
            do {
                let doc: Document = try SwiftSoup.parse(data as String)
                let els: Elements = try doc.select("div.post-card")
                var postList = [Post]()
                for element: Element in els.array() {
                    let newPost = Post()
                    
                    if let nameElement = try element.select("p.title").first() {
                        newPost.name = try nameElement.text()
                    }
                    
                    if let postElement = try element.select("a[href]").first() {
                        let postURL = try postElement.attr("href")
                        newPost.postID = (postURL as NSString).lastPathComponent
                    }
                    
                    if let thumbnailElement = try element.select("img.card-img-top").first() {
                        newPost.thumbnailURL = try thumbnailElement.attr("src")
                    }
                    
                    let infoElements = try element.select("div.stream-info > small.text-muted > a")
                    for infoElement in infoElements.array() {
                        let urlElement = try infoElement.attr("href") as NSString
                        if urlElement.contains("streamer") {
                            newPost.streamerID = urlElement.lastPathComponent
                            newPost.streamer = try infoElement.text()
                        } else if urlElement.contains("game") {
                            newPost.gameID = urlElement.lastPathComponent
                            newPost.game = try infoElement.text()
                        }
                    }
                    
                    let pointElements = try element.select("div.card-body > a > small.text-muted")
                    for pointElement in pointElements.array() {
                        let element = try pointElement.text()
                        if element.contains("points") {
                            newPost.point = element
                        } else if element.contains("ago") {
                            newPost.date = element
                        }
                    }
                    
                    postList.append(newPost)
                }
                
                return postList
            } catch Exception.Error( _, let message) {
                println(message)
            } catch {
                println("error")
            }
        }
        return nil
    }

    //println("get Post request \(requestParameters)")
    let resource = jsonResource(path: "load/loadPosts.php", method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    if let failureHandler = failureHandler {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

func getStreamerPost(page: Int, order: PostOrder, timeFrame: PostTimeFrame, streamer: String, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping ([Post]) -> Void) {
    let requestParameters = [
        "loadPostPage": page,
        "loadPostMode": PostMode.STREAMER.rawValue,
        "loadPostOrder": order.rawValue,
        "loadPostTimeFrame": timeFrame.rawValue,
        "loadPostNSFW": 0,
        "loadPostModeStreamer": streamer,
        ] as [String : Any]
    
    let parse: (NSData) -> [Post]? = { data in
        if let data = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
            //println("get Streamer Post response \(data)")
            
            do {
                let doc: Document = try SwiftSoup.parse(data as String)
                let els: Elements = try doc.select("div.post-card")
                var postList = [Post]()
                for element: Element in els.array() {
                    let newPost = Post()
                    
                    if let nameElement = try element.select("p.title").first() {
                        newPost.name = try nameElement.text()
                    }
                    
                    if let postElement = try element.select("a[href]").first() {
                        let postURL = try postElement.attr("href")
                        newPost.postID = (postURL as NSString).lastPathComponent
                    }
                    
                    if let thumbnailElement = try element.select("img.card-img-top").first() {
                        newPost.thumbnailURL = try thumbnailElement.attr("src")
                    }
                    
                    if let streamerInfoElement = try element.select("div.stream-info > small.text-muted > a").first(){
                        let streamerURL = try streamerInfoElement.attr("href")
                        newPost.streamerID = (streamerURL as NSString).lastPathComponent
                    }
                    postList.append(newPost)
                }
                
                return postList
            } catch Exception.Error( _, let message) {
                println(message)
            } catch {
                println("error")
            }
        }
        return nil
    }
    
    //println("get Streamer Post request \(requestParameters)")
    let resource = jsonResource(path: "load/loadPosts.php", method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    if let failureHandler = failureHandler {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest(modifyRequest: {_ in}, baseURL: spBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

