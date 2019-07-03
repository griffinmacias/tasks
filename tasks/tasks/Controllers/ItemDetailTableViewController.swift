//
//  ItemDetailTableViewController.swift
//  tasks
//
//  Created by Mason Macias on 6/17/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit

extension Date {
    func toString(with dateFormat: DateFormatter) -> String {
        return dateFormat.string(from: self)
    }
}

class ItemDetailTableViewController: UITableViewController {
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet var itemDetailTableView: UITableView!
    public var task: Task?
    
    private var showPicker: Bool = false {
        didSet {
            dateLabel.textColor = showPicker ? .black : .darkGray
            itemDetailTableView.beginUpdates()
            itemDetailTableView.endUpdates()
        }
    }
    private var showDueDate: Bool = false {
        didSet {
            switchView.isOn = showDueDate
            if !showDueDate {
                showPicker = false
            }
            itemDetailTableView.beginUpdates()
            itemDetailTableView.endUpdates()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let task = task {
            titleTextField.text = task.title
            showDueDate = task.alert
        }
        itemDetailTableView.tableFooterView = UIView()
        guard let dueDate = task?.dueDate else {
            dateLabel.text = ""
            return
        }
        datePickerView.date = dueDate
        dateLabel.text = dueDate.string(.dateShortTimeShort)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //save the info
        //might need to change if deleted the task
        guard let task = task else { return }
        
        if !showDueDate && task.alert {
            task.dueDate = nil
        } else {
            guard !task.alert && task.dueDate?.timeIntervalSinceReferenceDate != datePickerView.date.timeIntervalSinceReferenceDate else { return }
            task.dueDate = datePickerView.date
        }
    }
    
    private func handleUpdates(with task: Task) {
        //title
        handleTitleUpdate(with: task, titleTextField.text)
        //alert
        
        //due date
    }
    
    private func handleTitleUpdate(with task: Task, _ titleText: String?) {
        //title update
        if let titleText = titleText {
            let santizedText = titleText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if santizedText.count > 0 && task.title != santizedText {
                task.title = santizedText
            }
        }
    }
    
    private func handleAlertUpdate(with task: Task, _ alert: Bool) {
        guard showDueDate != task.alert else { return }
        task.alert = showDueDate
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1,1):
            showPicker = !showPicker
        default:
            ()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch (indexPath.section, indexPath.row) {
        case (1, 1):
            if !showDueDate {
                return 0
            }
        case (1, 2):
            if !showPicker {
                return 0
            }
        case (_, _):
            break
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    //MARK: - actions
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        dateLabel.text = sender.date.string(.dateShortTimeShort)
    }
    
    @IBAction func didTapSwitchView(_ sender: UISwitch) {
        showDueDate = sender.isOn
    }
    
}
