//
//  Network.swift
//  tasks
//
//  Created by Mason Macias on 6/6/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class Metadata {
    var roles: [String:[String]] = [:]
}

protocol ItemProtocol {
    var title: String { get set }
    var metadata: Metadata { get set }
    init(_ json: [String: Any])
}

final class List: ItemProtocol {
    
    public var title: String
    public var metadata: Metadata
    
    init(_ json: [String: Any]) {
        title = json["title"] as? String ?? "no title"
        metadata = Metadata()
    }
    
}

final class Task: ItemProtocol {
    init(_ json: [String : Any]) {
        title = ""
        metadata = Metadata()
    }
    
    
    public var title: String
    public var metadata: Metadata

}

protocol NetworkProtocol {
    func fetchLists(completion:@escaping () -> Void)
    func fetchTasks(completion:@escaping () -> Void)
}

enum Type: String {
    case list = "list"
    case task = "task"
}

final class Network: NetworkProtocol {
    func fetch(with type: Type, completion: @escaping () -> Void) {
        let reference = Firestore.firestore().collection(type.rawValue + "s")
        reference.getDocuments { (querySnapshot, error) in
//            let documents = querySnapshot?.documents
            completion()
        }
    }
    func fetchLists(completion: @escaping () -> Void) {
        let reference = Firestore.firestore().collection("list")
        reference.getDocuments { (querySnapshot, error) in
            
        }
        completion()
    }
    func fetchTasks(completion: @escaping () -> Void) {
        completion()
    }
}
