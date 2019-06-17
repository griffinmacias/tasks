//
//  CollectionViewController.swift
//  tasks
//
//  Created by Mason Macias on 6/4/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import UIKit
import FirebaseUI
import FirebaseFirestore

class CollectionViewController: UIViewController {
    
    @IBOutlet private weak var collectionTableView: UITableView!
    public var type: Type = .list
    private var listener: ListenerRegistration?
    private var collection: [ItemProtocol] = []
    public var list: List?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Auth.auth().currentUser == nil, let authUI = FUIAuth.defaultAuthUI() {
            let provider = FUIEmailAuth()
            authUI.providers = [provider]
            authUI.delegate = self
            let authViewController = authUI.authViewController()
            DispatchQueue.main.async {
                self.present(authViewController, animated: true, completion: nil)
            }
        } else {
            getDocuments()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func getDocuments() {
        var query: Query = Firestore.firestore().collection(type.rawValue + "s")
        if type == .task, let list = list {
            query = query.whereField("listid", isEqualTo: list.document.documentID)
        }
        listener = query.addSnapshotListener { [weak self] (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshot results: \(error!)")
                return
            }
            let collection = snapshot.documents.map { (document) -> ItemProtocol in
                print(document)
                switch self?.type {
                case .list?:
                    return List(document)
                default:
                    return Task(document)
                }
            }
            self?.collection = collection
            DispatchQueue.main.async {
                self?.navigationItem.title = self?.type == .list ? "Lists" : (self?.list?.title ?? "")
                self?.collectionTableView.reloadData()
                
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
            switch weakSelf.type {
            case .list:
                let collection = Firestore.firestore().collection(weakSelf.type.rawValue + "s")
                let collectionJSON = ["title": title]
                collection.addDocument(data: collectionJSON, completion: { (error) in
                    guard error != nil else { return }
                    self?.getDocuments()
                })
            case .task:
                guard let list = weakSelf.list else { return }
                let collection = Firestore.firestore().collection(weakSelf.type.rawValue + "s")
                let collectionJSON = ["title": title, "completed": false, "listid": list.document.documentID] as [String : Any]
                collection.addDocument(data: collectionJSON, completion: { (error) in
                    guard error != nil else { return }
                    self?.getDocuments()
                })
            }
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
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
        if let task = list as? Task {
            cell.accessoryType = task.completed ? .checkmark : .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = collection[indexPath.row]
        switch type {
        case .list:
            guard let collectionViewController = storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as? CollectionViewController else { return }
            collectionViewController.type = .task
            collectionViewController.list = item as? List
            collectionViewController.navigationItem.title = item.title
            navigationController?.pushViewController(collectionViewController, animated: true)
        case .task:
            //complete or uncomplete the task
            guard let cell = tableView.cellForRow(at: indexPath) as? ListTableViewCell else {
                return
            }
            guard let task = collection[indexPath.row] as? Task else { return }
            let newValue = !task.completed
            task.completed = newValue
            task.document.reference.updateData(["completed": newValue])
            cell.accessoryType = .checkmark
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = collection[indexPath.row]
            item.document.reference.delete()
            collection.remove(at: indexPath.row)
            collectionTableView.reloadData()
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

