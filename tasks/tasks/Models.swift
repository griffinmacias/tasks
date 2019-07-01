//
//  Models.swift
//  tasks
//
//  Created by Mason Macias on 6/9/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import Firebase
import UserNotifications

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
        didSet {
            //network call?
        }
    }
    internal var document: DocumentSnapshot
    public var tasks: [Task] = []
//    public var metadata: Metadata
    public init(_ document: QueryDocumentSnapshot) {
        self.document = document
        self.title = document.data()["title"] as? String ?? "no title"
//        self.metadata = Metadata()
    }
    
    public func add(_ task: String, completion: @escaping () -> Void) {
        let dict = ["title": task]
        document.reference.updateData(["tasks":[dict]]) { (_) in
            completion()
        }
    }
    
    public func remove( _ task: String) {
        
    }
    
}

final public class Task: ItemProtocol {
    
    public var title: String {
        didSet {
            update("title", for: title)
        }
    }
    
    public var completed: Bool {
        didSet {
            update("completed", for: completed)
        }
    }
    
    public var alert: Bool {
        didSet {
            update("alert", for: alert)
        }
    }
    
    public var dueDate: Date? {
        didSet {
            guard let dueDate = dueDate else {
                update("alert", for: false)
                return
            }
            update("dueDate", for: dueDate)
            update("alert", for: true)
        }
    }
    
    internal var document: DocumentSnapshot

    init(_ document: QueryDocumentSnapshot) {
        self.title = document.data()["title"] as? String ?? "no title"
        self.document = document
        self.completed = document.data()["completed"] as? Bool ?? false
        self.dueDate = (document.data()["dueDate"] as? Timestamp)?.dateValue()
        self.alert = document.data()["alert"] as? Bool ?? false
    }
    
    //MARK: - network
    
    func update(_ key: String, for value: Any) {
        
        document.reference.updateData([key: value]) { [weak self] (error) in
            if let error = error {
                print("error updating obj \(self?.title ?? "(no object found)") \(error.localizedDescription)")
                return
            }
            guard let weakSelf = self else { return }
            //TODO: make this look better
            if key == "dueDate" {
                print("scheduled notification")
                TaskNotifications.schedulePendingNotificationRequest(with: weakSelf)
            } else if key == "alert" && !weakSelf.alert {
                print("unscheduled notification")
                TaskNotifications.schedulePendingNotificationRequest(with: weakSelf)
            }
        }
    }
}

enum Type: String {
    case list = "list"
    case task = "task"
}


final class TaskViewModel {
    var titleText: String
    var dueDateText: String?
    var dueDatePassed: Bool = false
    var completed: Bool
    init(_ task: Task) {
        self.titleText = task.title
        self.completed = task.completed
        if let dueDate = task.dueDate, task.alert {
            //check if the date has already past
            dueDatePassed = dueDate.timeIntervalSinceNow < 0
            //format dateText
            dueDateText = dueDate.string(.dateShortTimeShort)
        }
    }
}

