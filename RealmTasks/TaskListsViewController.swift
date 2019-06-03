//
//  TaskListsViewController.swift
//  RealmTasks
//
//  Created by Artem KUPRIIANETS on 4/20/19.
//  Copyright © 2019 Artem KUPRIIANETS. All rights reserved.
//

import UIKit
import RealmSwift

class TaskListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    var lists: Results<TaskList>!
    var isEditingMode = false
    
    var currentCreateAction: UIAlertAction!
    @IBOutlet weak var taskListsTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    override func viewWillAppear(_ animated: Bool) {
        readTasksAndUpdateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		guard !searchText.isEmpty else { readTasksAndUpdateUI(); return }
        let predicate = NSPredicate.init(format: "name CONTAINS [c]%@", searchText)
		let scopeIndex = searchBar.selectedScopeButtonIndex
		
		switch scopeIndex {
		case 0:
			lists = uiRealm.objects(TaskList.self).filter(predicate).sorted(byKeyPath: "name")
		case 1:
			lists = uiRealm.objects(TaskList.self).filter(predicate).sorted(byKeyPath: "createdAt")
		default:
			lists = uiRealm.objects(TaskList.self).filter(predicate)
		}
		taskListsTableView.reloadData()
    }
	
	private func checkIfSortLists() {
		if segmentControl.selectedSegmentIndex == 0 { lists = lists.sorted(byKeyPath: "name") }
		else if segmentControl.selectedSegmentIndex == 1 { lists = lists.sorted(byKeyPath: "createdAt", ascending: false) }
	}
    
    func readTasksAndUpdateUI(){
        lists = uiRealm.objects(TaskList.self)
		taskListsTableView.setEditing(false, animated: true)
		checkIfSortLists()
        taskListsTableView.reloadData()
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.segmentControl.isHidden = self.lists.isEmpty
            self.searchBar.isHidden = self.lists.isEmpty
        }, completion: nil)
    }
    
    // MARK: - User Actions -
    
    @IBAction func didSelectSortCriteria(_ sender: UISegmentedControl) {
		lists = (sender.selectedSegmentIndex == 0) ? lists.sorted(byKeyPath: "name") : lists.sorted(byKeyPath: "createdAt", ascending: false)
        taskListsTableView.reloadData()
    }
    
    @IBAction func didClickOnEditButton(_ sender: UIBarButtonItem) {
        isEditingMode = !isEditingMode
        taskListsTableView.setEditing(isEditingMode, animated: true)
    }
    
    @IBAction func didClickOnAddButton(_ sender: UIBarButtonItem) {
        displayAlertToAddTaskList(nil)
    }
    
    //Enable the create action of the alert only if textfield text is not empty
    
    @objc func listNameFieldDidChange(_ textField:UITextField){
        if let text = textField.text {
            self.currentCreateAction.isEnabled = text.count > 0
        }
    }
    
    func displayAlertToAddTaskList(_ updatedList: TaskList!) {
        var title = "New Tasks List"
        var doneTitle = "Create"
        if updatedList != nil{
            title = "Update Tasks List"
            doneTitle = "Update"
        }
        
        let alertController = UIAlertController(title: title, message: "Name of your tasks list, please", preferredStyle: UIAlertControllerStyle.alert)
        let createAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.default) { (action) -> Void in
            let listName = alertController.textFields?.first?.text
            
            if updatedList != nil{
                try! uiRealm.write{
                    updatedList.name = listName!
                    self.readTasksAndUpdateUI()
                }
            } else {
                let newTaskList = TaskList()
                newTaskList.name = listName!
                
                try! uiRealm.write{
                    
                    uiRealm.add(newTaskList)
                    self.readTasksAndUpdateUI()
                }
            }
        }
        
        alertController.addAction(createAction)
        createAction.isEnabled = false
        self.currentCreateAction = createAction
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        alertController.addTextField { (textField) -> Void in
            textField.placeholder = "Task List Name"
            textField.addTarget(self, action: #selector(self.listNameFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            if updatedList != nil{
                textField.text = updatedList.name
            }
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let listsTasks = lists {
            return listsTasks.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell")
        let list = lists[indexPath.row]

        cell?.textLabel?.text = list.name
        cell?.detailTextLabel?.text = "\(list.tasks.count) Tasks"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            let listToBeDeleted = self.lists[indexPath.row]
            try! uiRealm.write {
                uiRealm.delete(listToBeDeleted)
                self.readTasksAndUpdateUI()
            }
        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (editAction, indexPath) -> Void in
            let listToBeUpdated = self.lists[indexPath.row]
            self.displayAlertToAddTaskList(listToBeUpdated)
            
        }
        return [deleteAction, editAction]
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "openTasks", sender: self.lists[indexPath.row])
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let tasksViewController = segue.destination as! TasksViewController
        tasksViewController.selectedList = sender as! TaskList
    }

}
