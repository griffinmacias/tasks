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

enum SwipeType: String {
    case left = "completed"
    case right = "undo"
    var color: UIColor {
        switch self {
        case .left:
            return .green
        case .right:
            return .lightGray
        }
    }
}

class CollectionViewController: UIViewController {
    
    
    static let taskDetailSegue: String = "taskDetailSegue"
    @IBOutlet private weak var collectionTableView: UITableView!
    public var type: Type = .list
    private var listener: ListenerRegistration?
    private var collection: [ItemProtocol] = []
    public var list: List?
    
    //MARK: - vc lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    //MARK: - actions
    
    @objc private func didTapFooterView(_ tapGesture: UITapGestureRecognizer) {
        showAddItemDetail()
    }
    
    @IBAction func didTapAddButton(_ sender: UIBarButtonItem) {
        showAddItemDetail()
    }
    
    //MARK: - helpers
    
    private func configureTableView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFooterView(_:)))
        collectionTableView.backgroundView = UIView()
        collectionTableView.backgroundView?.addGestureRecognizer(tapGesture)
    }
    
    private func updateNavTitle(_ list: List? = nil) {
        if let listTitle = list?.title {
            navigationItem.title = listTitle
        } else {
            navigationItem.title = "Lists"
        }
    }
    
    //MARK: - network
    
    private func getDocuments() {
        Network.shared.fetch(with: type, list: list) { [weak self] (items) in
            self?.collection = items
            DispatchQueue.main.async {
                self?.updateNavTitle(self?.list)
                self?.collectionTableView.reloadData()
            }
        }
    }
    
    //MARK: - alert controller
    
    private func showAddItemDetail() {
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
                guard let list = weakSelf.list, let documentID = list.document?.documentID else { return }
                let collection = Firestore.firestore().collection(weakSelf.type.rawValue + "s")
                let collectionJSON = ["title": title, "completed": false, "listid": documentID] as [String : Any]
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
    
    //MARK: - segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard segue.identifier == CollectionViewController.taskDetailSegue, let task = sender as? Task, let detailVC = segue.destination as? ItemDetailTableViewController else { return }
        detailVC.navigationItem.title = "Detail"
        detailVC.task = task
    }
}

//MARK: - tableview datasource and delegate

extension CollectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = collection[indexPath.row]
        var cell: UITableViewCell
        switch type {
        case .list:
            let listCell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCellID", for: indexPath) as! ListTableViewCell
            listCell.listTitleLabel.text = list.title
            if let task = list as? Task {
                listCell.accessoryType = task.completed ? .checkmark : .none
            }
            cell = listCell
        case .task:
            let taskCell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCellID", for: indexPath) as! TaskTableViewCell
            if let task = list as? Task {
                let taskViewModel = TaskViewModel(task)
                taskCell.configure(taskViewModel)
            }
            cell = taskCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
            ()
            performSegue(withIdentifier: CollectionViewController.taskDetailSegue, sender: item)
        }
    }
    //TODO: need to add a swipe gesture to allow the pop to happen only on empty cells
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = self.collection[indexPath.row] as? Task, !item.completed else { return nil }
        let completedAction = UIContextualAction.itemSwipeAction(.left) {
            item.completed = true
            item.save()
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
        }
        let configuration = UISwipeActionsConfiguration(actions: [completedAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = self.collection[indexPath.row] as? Task, item.completed else { return nil }
        let undoAction = UIContextualAction.itemSwipeAction(.right) {
            item.completed = false
            item.save()
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .none
        }
        let configuration = UISwipeActionsConfiguration(actions: [undoAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
}

//MARK: - swipe action extension

extension UIContextualAction {
    internal class func itemSwipeAction(_ swipeType: SwipeType, completion: @escaping () -> Void) -> UIContextualAction {
        let completedAction = UIContextualAction(style: .normal, title: swipeType.rawValue) { (_, _, _) in
            completion()
        }
        completedAction.backgroundColor = swipeType.color
        return completedAction
    }
}

//MARK: - fui auth delegate

extension CollectionViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print(authUI, authDataResult ?? "no data result", error ?? "no error")
        getDocuments()
    }
}

//MARK: - alert controller extension

extension UIAlertController {
    class func alertController(with viewType: Type) -> UIAlertController {
        let alertController = UIAlertController(title: "Create " + viewType.rawValue.capitalized, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textfield) in
            textfield.placeholder = "title"
        }
        return alertController
    }
}


