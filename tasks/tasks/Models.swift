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
    
    var updatedFields: [FieldType: Any] = [:]
    
    public enum FieldType: String {
        case document = "document"
        case title = "title"
        case completed = "completed"
        case alert = "alert"
        case dueDate = "dueDate"
    }
    
    public var title: String {
        willSet {
            if title != newValue {
                updatedFields[.title] = newValue
            }
        }
    }
    
    public var completed: Bool {
        willSet {
            if completed != newValue {
                updatedFields[.completed] = newValue
            }
        }
        didSet {
            TaskScheduleManager.handle(self, scheduleType: .update(.completed))
//            update(.completed, for: completed)
        }
    }
    
    public var alert: Bool {
        willSet {
            if alert != newValue {
                updatedFields[.alert] = newValue
            }
        }
        didSet {
            TaskScheduleManager.handle(self, scheduleType: .update(.alert))
//            update(.alert, for: alert)
        }
    }
    
    public var dueDate: Date? {
        willSet {
            guard let dueDate = dueDate, let newDueDate = newValue else {
                return
            }
            if dueDate.timeIntervalSinceNow != newDueDate.timeIntervalSinceNow {
                updatedFields[.dueDate] = newDueDate
            }
            TaskScheduleManager.prepare(task: self, for: newDueDate)
        }
        didSet {
            guard let dueDate = dueDate else {
//                update(.alert, for: false)
                return
            }
            TaskScheduleManager.handle(self, scheduleType: .update(.dueDate))
//            update(.dueDate, for: dueDate)
//            update(.alert, for: true)
        }
    }
    
    public func save() {
        guard updatedFields.count != 0 else { return }
        updatedFields[.document] = document
    }
    
    internal var document: DocumentSnapshot

    init(_ document: QueryDocumentSnapshot) {
        self.title = document.data()[FieldType.title.rawValue] as? String ?? "no title"
        self.document = document
        self.completed = document.data()[FieldType.completed.rawValue] as? Bool ?? false
        self.dueDate = (document.data()[FieldType.dueDate.rawValue] as? Timestamp)?.dateValue()
        self.alert = document.data()[FieldType.alert.rawValue] as? Bool ?? false
    }
}

extension Task: Equatable {
    public static func == (lhs: Task, rhs: Task) -> Bool {
        //eventually will need to add assignee check and isDeleted check
        return lhs.title == rhs.title && lhs.alert == rhs.alert && lhs.dueDate == rhs.dueDate && lhs.completed == rhs.completed
    }
    
    
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ task: Task) {
        var dateString = "no date"
        if let date = task.dueDate {
            dateString = date.string(.dateShortTimeShort)
        }
        appendInterpolation("""
            ///
            task: title \(task.title)
            alert \(task.alert)
            dueDate \(dateString)
            completed \(task.completed)
            id \(task.document.documentID)
            ///
            """)
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


