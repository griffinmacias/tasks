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

private extension UNNotificationCategory {
    class func task() -> UNNotificationCategory {
        let completedAction = UNNotificationAction(identifier: "COMPLETED_ACTION", title: "Completed", options: UNNotificationActionOptions.init(.completed))
        let dismissAction = UNNotificationAction(identifier: "DISMISS_ACTION", title: "Dismiss", options: UNNotificationActionOptions.init(.dismiss))
        let taskCategory = UNNotificationCategory(identifier: "TASK", actions: [completedAction, dismissAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        return taskCategory
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
    convenience init(_ task: Task) {
        self.init()
        //TODO: create some constant
        title = "Task"
        body = task.title
        sound = .default
        badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        userInfo = ["id": task.document.documentID]
        //TODO: create some constant
        categoryIdentifier = "TASK"
    }
}
