//
//  ViewController.swift
//  tasks
//
//  Created by Mason Macias on 6/4/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit
import FirebaseAuthUI

enum ViewType: String {
    case list = "list"
    case task = "task"
    
    var alertTitle: String {
        switch self {
        case .list:
            return "Create List"
        case .task:
            return "Create Task"
        }
    }
}

class ViewController: UIViewController {
    var viewType: ViewType = .list
    override func viewDidLoad() {
        super.viewDidLoad()
        if let authUI = FUIAuth.defaultAuthUI() {
            authUI.delegate = self
            let authViewController = authUI.authViewController()
            DispatchQueue.main.async {
                self.present(authViewController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func didTapAddButton(_ sender: UIBarButtonItem) {
        //create alert controller and have user type name of list or task
        let alertController = UIAlertController.alertController(with: viewType)
        let okAction = UIAlertAction(title: "create", style: .default) { (alert) in
            //network call here either for list or task
            switch self.viewType {
            case .list:
                ()
            case .task:
                ()
            }
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .default, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
    }
}

extension ViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print(authUI, authDataResult ?? "no data result", error ?? "no error")
    }
}

extension UIAlertController {
    class func alertController(with viewType: ViewType) -> UIAlertController {
        let alertController = UIAlertController(title: viewType.alertTitle, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textfield) in
            textfield.placeholder = viewType.rawValue + " title"
        }
        return alertController
    }
}

