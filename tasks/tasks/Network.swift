//
//  Network.swift
//  tasks
//
//  Created by Mason Macias on 6/6/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct CollectionSerializer {
    static func transform(_ collection: CollectionObject) -> [String: Any] {
        var params: [String: Any] = [FieldType.name.rawValue: collection.name ]
        switch collection.type {
        case .task:
            transform(collection as! Task, &params)
        case .list:
            transform(collection as! List, &params)
        case .user:
            transform(collection as! User, &params)
        }
        return params
    }
    
    private static func transform(_ task: Task, _ params:inout [String: Any]) {
        let taskParams = [
            FieldType.alert.rawValue: task.alert,
            FieldType.completed.rawValue: task.completed
        ]
        params.merge(taskParams) { $1 }
        if let dueDate = task.dueDate {
            params[FieldType.dueDate.rawValue] = dueDate
        }
    }
    
    private static func transform(_ list: List, _ params:inout [String: Any]) {
    
    }
    
    private static func transform(_ user: User, _ params:inout [String: Any]) {
        
    }
}


final class Network {
    
    typealias Completion = () -> Void
    typealias ItemsCompletion = ([CollectionObject]) -> Void
    typealias CountCompletion = (Int) -> Void
    
    static let shared = Network()
    private var listener: ListenerRegistration?
    private init() {}
    
    public func fetch(with type: Type, list: List? = nil, completion: @escaping ItemsCompletion) {
        let query = CollectionReference.query(with: type, list: list)
        
        listener = query.addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshot results: \(error!)")
                return
            }
            let collection = snapshot.documents.map { (document) -> CollectionObject in
                print(document)
                switch type {
                case .list:
                    return List(document, type: .list)
                default:
                    return Task(document)
                }
            }
            completion(collection)
        }
    }
    
    public func numberOfDueDatesPassed(completion:@escaping CountCompletion) {
        let query = CollectionReference.passedDueDates(for: .task)
        listener = query.addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshot results: \(error!)")
                return
            }
            let count = snapshot.documents.count
            completion(count)
        })
    }
    
    func create(_ collectionObject: CollectionObject, completion: Completion? = nil) {
        let collection = Firestore.firestore().collection(collectionObject.type.rawValue + "s")
        collection.addDocument(data: CollectionSerializer.transform(collectionObject), completion: { (error) in
            guard error != nil else { return }
            if let completion = completion {
                completion()
            }
        })
    }
    
    public func update<K: RawRepresentable>(_ document: DocumentSnapshot?, with fields: [K: Any], completion: Completion? = nil) where K.RawValue == String {
        let params = Dictionary(uniqueKeysWithValues: fields.map { key, value in (key.rawValue, value) })
    
        document?.reference.updateData(params) { (error) in
            if let error = error {
                print("error updating obj \(String(describing: document?.data()?[FieldType.name.rawValue])) \(error.localizedDescription)")
                if let completion = completion {
                    completion()
                }
                return
            }
            if let completion = completion {
                completion()
            }
        }
    }
}

extension Query {
    class func query(with type: Type, list: List? = nil) -> Query {
        var query: Query = Firestore.firestore().collection(type.rawValue + "s")
        if type == .task, let list = list, let document = list.document {
            query = query.whereField("listid", isEqualTo: document.documentID)
        }
        return query
    }
    //NOTE: - only works for tasks for now
    class func passedDueDates(for type: Type) -> Query {
        let query = CollectionReference.query(with: .task)
            .whereField(FieldType.dueDate.rawValue, isLessThan: Timestamp())
            .whereField(FieldType.alert.rawValue, isEqualTo: true)
            .whereField(FieldType.completed.rawValue, isEqualTo: false)
        return query
    }
}
