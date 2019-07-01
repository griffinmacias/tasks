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

final class TaskNotifications {
    public class func schedulePendingNotificationRequest(with task: Task) {
        guard let request = UNNotificationRequest.configure(for: task) else { return }
        TaskNotifications.unschedulePendingNotificationRequest(for: task)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("error adding notification request \(error.localizedDescription)")
            }
        }
    }
    
    internal class func unschedulePendingNotificationRequest(for task: Task) {
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
        guard let dueDate = task.dueDate else { return nil}
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
        badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        userInfo = ["id": task.document.documentID]
        categoryIdentifier = UNNotificationCategory.CategoryIdentifier.task.rawValue
    }
}
