//
//  tasksTests.swift
//  tasksTests
//
//  Created by Mason Macias on 6/4/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import XCTest
import Quick
import Nimble
import Firebase
@testable import tasks

class TaskLocalNotificationSpec: QuickSpec {
    override func spec() {
        describe("a task") {
            var task: TaskMock!
            beforeEach {
                task = TaskMock("do dishes", alert: true, dueDate: Date().addingTimeInterval(-1000))
                print("\(String(describing: task))")
            }
            describe("initial badge count") {
                beforeEach {
                    NotificationBadgeHandler.badgeCount = 0
                }
                it("is 0") {
                    print("badgeCount is \(String(describing: NotificationBadgeHandler.badgeCount))")
                    expect(NotificationBadgeHandler.badgeCount).to(equal(0))
                }
                
            }
            describe("add task that has a past due date") {
                beforeEach {
                    NotificationBadgeHandler.badgeCount = 0
                    TaskScheduleManager.handle(task, scheduleType: .update(.dueDate))
                }
                it("is 1") {
                    expect(NotificationBadgeHandler.badgeCount).to(equal(1))
                }
            }
            describe("complete task that has a past due date") {
                beforeEach {
                    NotificationBadgeHandler.badgeCount = 1
                    task.completed = true
                    TaskScheduleManager.handle(task, scheduleType: .update(.completed))
                }
                it("is 0") {
                    expect(NotificationBadgeHandler.badgeCount).to(equal(0))
                }
            }
            describe("undo complete for task") {
                beforeEach {
                    NotificationBadgeHandler.badgeCount = 1
                    task.completed = true
                    TaskScheduleManager.handle(task, scheduleType: .update(.completed))
                    task.completed = false
                    TaskScheduleManager.handle(task, scheduleType: .update(.completed))
                }
                it("is 1") {
                    expect(NotificationBadgeHandler.badgeCount).to(equal(1))
                }
            }
            
            describe("disable alert for task that has a past due date") {
                beforeEach {
                    NotificationBadgeHandler.badgeCount = 1
                    task.alert = false
                    TaskScheduleManager.handle(task, scheduleType: .update(.alert))
                }
                it("is 0") {
                    expect(NotificationBadgeHandler.badgeCount).to(equal(0))
                }
            }
            
            describe("task with past due date and due date gets updated to the future") {
                beforeEach {
                    NotificationBadgeHandler.badgeCount = 1
                    task.alert = true
                    task.completed = false
                    if let oldDueDate = task.dueDate {
                        TaskScheduleManager.prepare(oldDueDate, Date().addingTimeInterval(1000))
                    }
                }
                it("is 0") {
                    expect(NotificationBadgeHandler.badgeCount).to(equal(0))
                }
            }
        }
    }
}
private class TaskMock: Task {
    convenience init(_ title: String = "", alert: Bool = false, dueDate: Date? = nil, completed: Bool = false) {
        self.init()
        self.title = title
        self.alert = alert
        self.dueDate = dueDate
        self.completed = completed
    }
}



//class tasksTests: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
//}
