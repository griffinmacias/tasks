//
//  Network.swift
//  tasks
//
//  Created by Mason Macias on 6/6/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import FirebaseFirestore


final class Network {
    
    typealias Completion = () -> Void
    typealias ItemsCompletion = ([ItemProtocol]) -> Void
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
            let collection = snapshot.documents.map { (document) -> ItemProtocol in
                print(document)
                switch type {
                case .list:
                    return List(document)
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
    
    public func update(_ document: DocumentSnapshot?, with fields: [Task.FieldType: Any], completion: Completion? = nil) {
        
        var params: [String: Any] = [:]
        fields.forEach { (key, value) in
            params[key.rawValue] = value
        }

        document?.reference.updateData(params) { (error) in
            if let error = error {
                print("error updating obj \(String(describing: document?.data()?[Task.FieldType.title.rawValue])) \(error.localizedDescription)")
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
            .whereField("dueDate", isLessThan: Timestamp())
            .whereField("alert", isEqualTo: true)
            .whereField("completed", isEqualTo: false)
        return query
    }
}
