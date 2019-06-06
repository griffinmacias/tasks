//
//  TaskTableViewCell.swift
//  tasks
//
//  Created by Mason Macias on 6/5/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var taskDueDateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
