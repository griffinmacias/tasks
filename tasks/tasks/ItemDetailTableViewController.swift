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
    
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet var itemDetailTableView: UITableView!
    public var task: Task?
    private var showPicker: Bool = false {
        didSet {
            dateLabel.textColor = self.showPicker ? .black : .lightGray
            itemDetailTableView.beginUpdates()
            itemDetailTableView.endUpdates()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemDetailTableView.tableFooterView = UIView()
        guard let dueDate = task?.dueDate else {
            dateLabel.text = ""
            return
        }
        dateLabel.text = DateFormatter.localizedString(from: dueDate, dateStyle: .short, timeStyle: .short)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //save the info
        guard let task = task, task.dueDate?.timeIntervalSinceReferenceDate != datePickerView.date.timeIntervalSinceReferenceDate else { return }
        task.dueDate = datePickerView.date
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1,0):
            showPicker = !showPicker
        default:
            ()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !showPicker && indexPath.section == 1 && indexPath.row == 1 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        dateLabel.text = DateFormatter.localizedString(from: sender.date, dateStyle: .short, timeStyle: .short)
    }
    
}
