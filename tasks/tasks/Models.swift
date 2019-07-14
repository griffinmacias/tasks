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



public enum FieldType: String {
    case document = "document"
    case name = "name"
    case completed = "completed"
    case alert = "alert"
    case dueDate = "dueDate"
    case userId = "userId"
}

public class CollectionObject {
    enum CodingKeys: CodingKey {
        case name
        case document
    }
    var name: String
    var document: DocumentSnapshot?
    var type: Type
    init(_ document: QueryDocumentSnapshot? = nil, type: Type) {
        let nameField = FieldType.name.rawValue
        self.name = document?.data()[nameField] as? String ?? "no \(nameField)"
        self.document = document
        self.type = type
    }
}

final class User: CollectionObject {
    var userId: String
    init(_ document: QueryDocumentSnapshot? = nil) {
        let userIdField = FieldType.name.rawValue
        self.userId = document?.data()[userIdField] as? String ?? "no \(userIdField)"
        super.init(document, type: .user)
    }
}

final class List: CollectionObject {
    public var tasks: [Task] = []
    public func add(_ task: String, completion: @escaping () -> Void) {
        let dict = ["title": task]
        document?.reference.updateData(["tasks":[dict]]) { (_) in
            completion()
        }
    }
}

public class Task: CollectionObject {
    
    var updatedFields: [FieldType: Any] = [:]
    
    override public var name: String {
        willSet {
            if name != newValue {
                updatedFields[.name] = newValue
            }
        }
    }
    
    public var completed: Bool {
        willSet {
            if completed != newValue {
                updatedFields[.completed] = newValue
            }
        }
    }
    
    public var alert: Bool {
        willSet {
            if alert != newValue {
                updatedFields[.alert] = newValue
            }
        }
    }
    
    public var dueDate: Date? {
        willSet {
            if dueDate != newValue {
                updatedFields[.dueDate] = newValue
            }
        }
    }
    
    public func save() {
        //make sure there are fields to update
        guard updatedFields.count != 0 else { return }
        //schedule
        scheduleIfNeeded()
        //update
        Network.shared.update(document, with: updatedFields)
        //clear newly updated fields
        updatedFields = [:]
    }
    
    private func scheduleIfNeeded() {
        //schedule notifications
        //if alert or due date updates lets update the due date
        if updatedFields[.alert] != nil || updatedFields[.dueDate] != nil {
            TaskScheduleManager.handle(self, scheduleType: .update(.dueDate))
            //if completed, lets unschedule any notifications
        } else if let _ = updatedFields[.completed] {
            TaskScheduleManager.handle(self, scheduleType: .update(.completed))
        }
    }

    public init(_ document: QueryDocumentSnapshot? = nil) {
        self.completed = document?.data()[FieldType.completed.rawValue] as? Bool ?? false
        self.dueDate = (document?.data()[FieldType.dueDate.rawValue] as? Timestamp)?.dateValue()
        self.alert = document?.data()[FieldType.alert.rawValue] as? Bool ?? false
        super.init(document, type: .task)
    }
}

extension Task: Equatable {
    public static func == (lhs: Task, rhs: Task) -> Bool {
        //eventually will need to add assignee check and isDeleted check
        return lhs.name == rhs.name && lhs.alert == rhs.alert && lhs.dueDate == rhs.dueDate && lhs.completed == rhs.completed
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
            task: title \(task.name)
            alert \(task.alert)
            dueDate \(dateString)
            completed \(task.completed)
            id \(task.document?.documentID ?? "no document")
            ///
            """)
    }
}

enum Type: String {
    
    case list = "list"
    case task = "task"
    case user = "user"
    
    var fieldTypes: Set<FieldType> {
        switch self {
        case .list:
            return [.name, .document]
        case .task:
            return [.name, .document, .alert, .dueDate, .completed]
        case .user:
            return [.name]
        }
    }
}





final class TaskViewModel {
    var titleText: String
    var dueDateText: String?
    var dueDatePassed: Bool = false
    var completed: Bool
    init(_ task: Task) {
        self.titleText = task.name
        self.completed = task.completed
        if let dueDate = task.dueDate, task.alert {
            //check if the date has already past
            dueDatePassed = dueDate.timeIntervalSinceNow < 0
            //format dateText
            dueDateText = dueDate.string(.dateShortTimeShort)
        }
    }
}


