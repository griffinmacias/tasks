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
        var query: Query = Firestore.firestore().collection(type.rawValue + "s")
        if type == .task, let list = list {
            query = query.whereField("listid", isEqualTo: list.document.documentID)
        }
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
}
