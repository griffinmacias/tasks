//
//  Notifications.swift
//  tasks
//
//  Created by Mason Macias on 7/1/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

private protocol NotificationBadging {
    static var badgeCount: Int { get set }
}

struct NotificationBadgeHandler: NotificationBadging {
    static var badgeCount: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        
        set {
            UIApplication.shared.applicationIconBadgeNumber = newValue
        }
    }
    
    private static func updateBadgeCount() {
        Network.shared.numberOfDueDatesPassed(completion: { (count) in
            DispatchQueue.main.async {
                print("number of due dates passed \(count)")
                badgeCount = count
            }
        })
    }
}

enum ScheduleType {
    case schedule
    case unschedule
    case update(UpdateType)
}

enum UpdateType {
    case alert
    case dueDate
    case completed
}

protocol NotificationScheduling {
    static func handle(_ task: Task, scheduleType: ScheduleType)
}

struct TaskScheduleManager: NotificationScheduling {
    //we need to know what kind of update happened
    static func handle(_ task: Task, scheduleType: ScheduleType) {
        switch scheduleType {
        case .schedule:
            TaskNotifications.schedulePendingNotificationRequest(for: task)
        case .unschedule:
            TaskNotifications.unschedulePendingNotificationRequest(for: task)
        case .update(let updateType):
            handle(task, for: updateType)
        }
    }
    
    static func prepare(task: Task) {
        //if the old due date already went off, we need to decrement the badge count
        guard task.alert, !task.completed,
            let newDueDate = task.dueDate,
            let oldDueDate = task.document.data()?[Task.FieldType.dueDate.rawValue] as? Date,
            oldDueDate.timeIntervalSinceNow < 0, newDueDate.timeIntervalSinceNow > 0 else { return }
        NotificationBadgeHandler.badgeCount -= 1
    }
    
    private static func handle(_ task: Task, for updateType: UpdateType) {
        switch updateType {
        case .alert:
            handleAlert(for: task)
        case .dueDate:
            handleDueDate(for: task)
        case .completed:
            handleCompleted(for: task)
        }
    }
    
    private static func handleAlert(for task: Task) {
        switch task.alert {
        case true:
            handleDueDate(for: task)
        case false:
            TaskNotifications.unschedulePendingNotificationRequest(for: task)
        }
    }
    
    private static func handleCompleted(for task: Task) {
        if task.completed {
            //check if the due date was passed, decrement badge count if so
            if let dueDate = task.dueDate, dueDate.timeIntervalSinceNow < 0 {
                NotificationBadgeHandler.badgeCount -= 1
            }
            TaskNotifications.unschedulePendingNotificationRequest(for: task)
        } else {
            handleAlert(for: task)
        }
    }
    
    private static func handleDueDate(for task: Task) {
        guard task.alert, let dueDate = task.dueDate else { return }
        //just in case
        TaskNotifications.unschedulePendingNotificationRequest(for: task)
        //if the due date is in the future, schedule it
        if dueDate.timeIntervalSinceNow > 0 {
            TaskNotifications.schedulePendingNotificationRequest(for: task)
        } else {
            //if the due date was passed we need to increment the badge
            NotificationBadgeHandler.badgeCount += 1
        }
    }
    
    
}

struct TaskNotifications {
    
    public static func schedulePendingNotificationRequest(for task: Task) {
        guard let request = UNNotificationRequest.configure(for: task) else { return }
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("error adding notification request \(error.localizedDescription)")
            }
        }
    }
    
    public static func unschedulePendingNotificationRequest(for task: Task) {
        print("unschedule pending notification request")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.document.documentID])
    }
}

private extension UNNotificationActionOptions {
    enum ActionType: UInt {
        case completed = 0
        case dismiss = 1
    }
    init(_ type: ActionType) {
        switch type {
        case .completed:
            self.init(rawValue: 0)
        case .dismiss:
            self.init(rawValue: 1)
        }
    }
}

extension UNNotificationCategory {
    enum CategoryIdentifier: String {
        case task = "TASK"
    }
    
    class func task() -> UNNotificationCategory {
        let completedAction = UNNotificationAction.action(with: .completed)
        let dismissAction = UNNotificationAction.action(with: .dismiss)
        let taskCategory = UNNotificationCategory(identifier: CategoryIdentifier.task.rawValue, actions: [completedAction, dismissAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        return taskCategory
    }
}

extension UNNotificationResponse {
    var actionIdentifierType: UNNotificationAction.ActionIdentifier {
        switch actionIdentifier {
        case UNNotificationAction.ActionIdentifier.completed.rawValue:
            return .completed
        default:
            return .dismiss
        }
    }
}

extension UNNotificationAction {
    enum ActionIdentifier: String {
        case completed = "COMPLETED_ACTION"
        case dismiss = "DISMISS_ACTION"
        var pretty: String {
            switch self {
            case .completed:
                return "Completed"
            case .dismiss:
                return "Dismiss"
            }
        }
    }
    
    class func action(with identifier: ActionIdentifier) -> UNNotificationAction {
        let actionOptions: UNNotificationActionOptions.ActionType = identifier == .completed ? .completed : .dismiss
        let action = UNNotificationAction(identifier: identifier.rawValue, title: identifier.pretty, options: UNNotificationActionOptions(actionOptions))
        return action
    }
}

public extension UNNotificationRequest {
    class func configure(for task: Task) -> UNNotificationRequest? {
        guard let dueDate = task.dueDate, task.alert else { return nil }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        print("date to be triggered \(task.dueDate!)")
        return UNNotificationRequest(identifier: task.document.documentID, content: UNMutableNotificationContent(task), trigger: trigger)
    }
}

private extension UNMutableNotificationContent {
    enum NotificationTitle: String {
        case task = "Task"
    }
    convenience init(_ task: Task) {
        self.init()
        title = NotificationTitle.task.rawValue
        body = task.title
        sound = .default
        //TODO: need to change this
        //to increment the badge count
        badge = (NotificationBadgeHandler.badgeCount + 1) as NSNumber
        userInfo = ["id": task.document.documentID]
        categoryIdentifier = UNNotificationCategory.CategoryIdentifier.task.rawValue
    }
}
