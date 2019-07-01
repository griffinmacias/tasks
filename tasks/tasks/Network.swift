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
    
    static let shared = Network()
    private var listener: ListenerRegistration?
    private init() {}
    
    public func fetch(with type: Type, list: List? = nil, completion: @escaping ([ItemProtocol]) -> Void) {
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
    
    public func numberOfDueDatesPassed(completion:@escaping (Int) -> Void) {
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
}

extension Query {
    class func query(with type: Type, list: List? = nil) -> Query {
        var query: Query = Firestore.firestore().collection(type.rawValue + "s")
        if type == .task, let list = list {
            query = query.whereField("listid", isEqualTo: list.document.documentID)
        }
        return query
    }
    //NOTE: - only works for tasks for now
    class func passedDueDates(for type: Type) -> Query {
        let query = CollectionReference.query(with: type)
            .whereField("dueDate", isLessThan: Timestamp())
            .whereField("alert", isEqualTo: true)
        return query
    }
}
