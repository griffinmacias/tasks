//
//  ItemDetailTableViewController.swift
//  tasks
//
//  Created by Mason Macias on 6/17/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit

class ItemDetailTableViewController: UITableViewController {
    @IBOutlet var itemDetailTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemDetailTableView.tableFooterView = UIView()
    }
}
