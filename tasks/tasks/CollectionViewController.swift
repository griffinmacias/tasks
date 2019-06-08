//
//  CollectionViewController.swift
//  tasks
//
//  Created by Mason Macias on 6/4/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit
import FirebaseAuthUI
import FirebaseFirestore

class CollectionViewController: UIViewController {
    
    @IBOutlet private weak var collectionTableView: UITableView!
    public var type: Type = .list
    private var listener: ListenerRegistration?
    private var collection: [ItemProtocol] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        if Auth.auth().currentUser == nil, let authUI = FUIAuth.defaultAuthUI() {
            authUI.delegate = self
            let authViewController = authUI.authViewController()
            DispatchQueue.main.async {
                self.present(authViewController, animated: true, completion: nil)
            }
        } else {
            let query = Firestore.firestore().collection(type.rawValue + "s")
            listener = query.addSnapshotListener { [weak self] (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    return
                }
                let collection = snapshot.documents.map { (document) -> ItemProtocol in
                    print(document)
                    switch self?.type {
                    case .list?:
                        return List(document.data())
                    default:
                        return Task([:])
                    }
                }
                self?.collection = collection
                DispatchQueue.main.async {
                    self?.collectionTableView.reloadData()
                    
                }
            }
        }
    }
    
    @IBAction func didTapAddButton(_ sender: UIBarButtonItem) {
        //create alert controller and have user type name of list or task
        let alertController = UIAlertController.alertController(with: type)
        let okAction = UIAlertAction(title: "create", style: .default) { [weak self] (alert) in
            //network call here either for list or task
            guard let weakSelf = self,
                let textField = alertController.textFields?.first,
                let title = textField.text else { return }
            let collection = Firestore.firestore().collection(weakSelf.type.rawValue + "s")
            let collectionJSON = ["title": title]
            collection.addDocument(data: collectionJSON)
            var collectionObj: ItemProtocol?
            switch weakSelf.type {
            case .list:
                collectionObj = List(collectionJSON)
            case .task:
                collectionObj = Task(collectionJSON)
            }
            guard let collectionO = collectionObj else { return }
            weakSelf.collection.append(collectionO)
            weakSelf.collectionTableView.reloadData()
            
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .default, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension CollectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = collection[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCellID", for: indexPath) as! ListTableViewCell
        cell.listTitleLabel.text = list.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let collectionViewController = storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as? CollectionViewController else { return }
//        let item = collection[indexPath.row]
        switch type {
        case .list:
            collectionViewController.type = .task
            //will have to pass id
        case .task:
            //complete or uncomplete the task
            ()
            
        }
    }
}

extension CollectionViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print(authUI, authDataResult ?? "no data result", error ?? "no error")
    }
}

extension UIAlertController {
    class func alertController(with viewType: Type) -> UIAlertController {
        let alertController = UIAlertController(title: "Create " + viewType.rawValue.capitalized, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textfield) in
            textfield.placeholder = "title"
        }
        return alertController
    }
}


