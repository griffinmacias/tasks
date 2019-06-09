//
//  Models.swift
//  tasks
//
//  Created by Mason Macias on 6/9/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import Firebase

final class Metadata {
    var roles: [String:[String]] = [:]
}

protocol ItemProtocol {
    var title: String { get set }
//    var metadata: Metadata { get set }
    var document: DocumentSnapshot { get set }
    init(_ document: QueryDocumentSnapshot)
}

final class List: ItemProtocol {
    
    public var title: String {
        get {
            return document.data()?["title"] as? String ?? "no title"
        }
        set {
            self.title = newValue
        }
    }
    internal var document: DocumentSnapshot
    public var tasks: [Task] = []
//    public var metadata: Metadata
    public init(_ document: QueryDocumentSnapshot) {
        self.document = document
//        self.metadata = Metadata()
    }
    
    public func add(_ task: String, completion: @escaping () -> Void) {
        let dict = ["title": task]
//        document.reference.updateData(["task": [dict]]) { (_) in
//            completion(document.get("tasks"))
//        }
        document.reference.updateData(["tasks":[dict]]) { (_) in
            completion()
        }
    }
    
    public func remove( _ task: String) {
        
    }
    
}

final class Task: ItemProtocol {
    
    public var title: String {
        get {
            return document.data()?["title"] as? String ?? "no title"
        }
        set {
            self.title = newValue
        }
    }
    internal var document: DocumentSnapshot

    init(_ document: QueryDocumentSnapshot) {
        //    public var metadata: Metadata
        self.document = document
//        self.metadata = Metadata()
    }
    
    
}

enum Type: String {
    case list = "list"
    case task = "task"
}
