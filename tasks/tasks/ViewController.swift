//
//  ViewController.swift
//  tasks
//
//  Created by Mason Macias on 6/4/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit
import FirebaseAuthUI

class ViewController: UIViewController {

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print(authUI, authDataResult ?? "no data result", error ?? "no error")
    }
}

