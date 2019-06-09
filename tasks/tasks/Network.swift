//
//  Network.swift
//  tasks
//
//  Created by Mason Macias on 6/6/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import FirebaseFirestore

protocol NetworkProtocol {
    func fetchLists(completion:@escaping () -> Void)
    func fetchTasks(completion:@escaping () -> Void)
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
