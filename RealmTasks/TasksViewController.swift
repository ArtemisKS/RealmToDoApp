//
//  TasksViewController.swift
//  RealmTasks
//
//  Created by Artem KUPRIIANETS on 4/20/19.
//  Copyright © 2019 Artem KUPRIIANETS. All rights reserved.
//

import UIKit
import RealmSwift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class TasksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var selectedList : TaskList!
    var openTasks : Results<Task>!
    var completedTasks : Results<Task>!
    var currentCreateAction:UIAlertAction!
    
    var isEditingMode = false
    
    @IBOutlet weak var tasksTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = selectedList.name
        readTasksAndUpateUI()
    }
    
    // MARK: - User Actions
    
    @IBAction func didClickOnEditTasks(_ sender: AnyObject) {
        isEditingMode = !isEditingMode
        self.tasksTableView.setEditing(isEditingMode, animated: true)
    }
	
    @IBAction func didClickOnNewTask(_ sender: AnyObject) {
        self.displayAlertToAddTask(nil)
    }
	
    func readTasksAndUpateUI() {
        completedTasks = self.selectedList.tasks.filter("isCompleted = true")
        openTasks = self.selectedList.tasks.filter("isCompleted = false")
        
        self.tasksTableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
	
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (section == 0) ? openTasks.count : completedTasks.count
    }
	
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return (section == 0) ? "OPEN TASKS" : "COMPLETED TASKS"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        var task: Task!
		task = (indexPath.section == 0) ? openTasks[indexPath.row] : completedTasks[indexPath.row]
		
		cell?.textLabel?.text = task.name
		return cell!
	}
	
	
	func displayAlertToAddTask(_ updatedTask:Task!){
		
		var title = "New Task"
		var doneTitle = "Create"
		if updatedTask != nil{
			title = "Update Task"
			doneTitle = "Update"
		}
		
		let alertController = UIAlertController(title: title, message: "Name of your task, please", preferredStyle: UIAlertControllerStyle.alert)
		let createAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.default) { (action) -> Void in
			if let taskName = alertController.textFields?.first?.text {
				if updatedTask != nil {
					try! uiRealm.write {
						updatedTask.name = taskName
						self.readTasksAndUpateUI()
					}
				} else {
					let newTask = Task()
					newTask.name = taskName
					
					try! uiRealm.write {
						self.selectedList.tasks.append(newTask)
						self.readTasksAndUpateUI()
					}
				}
			}
		}
		
		alertController.addAction(createAction)
		createAction.isEnabled = false
		self.currentCreateAction = createAction
		
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        alertController.addTextField { (textField) -> Void in
            textField.placeholder = "Task Name"
            textField.addTarget(self, action: #selector(TasksViewController.taskNameFieldDidChange(_:)) , for: UIControlEvents.editingChanged)
            if updatedTask != nil{
                textField.text = updatedTask.name
            }
        }
        
        self.present(alertController, animated: true, completion: nil)
    }

    //Enable the create action of the alert only if textfield text is not empty
    @objc func taskNameFieldDidChange(_ textField:UITextField){
        self.currentCreateAction.isEnabled = textField.text?.count > 0
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            //Deletion will go here
            
            var taskToBeDeleted: Task!
			taskToBeDeleted = (indexPath.section == 0) ? self.openTasks[indexPath.row] : self.completedTasks[indexPath.row]
			
            try! uiRealm.write{
                uiRealm.delete(taskToBeDeleted)
                self.readTasksAndUpateUI()
            }
        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (editAction, indexPath) -> Void in
            
            // Editing will go here
            var taskToBeUpdated: Task!
            if indexPath.section == 0{
                taskToBeUpdated = self.openTasks[indexPath.row]
            }
            else{
                taskToBeUpdated = self.completedTasks[indexPath.row]
            }
            
            self.displayAlertToAddTask(taskToBeUpdated)
            
        }
        
        let doneAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Done") { (doneAction, indexPath) -> Void in
            // Editing will go here
            var taskToBeUpdated: Task!
            if indexPath.section == 0 {
                taskToBeUpdated = self.openTasks[indexPath.row]
            } else{
                taskToBeUpdated = self.completedTasks[indexPath.row]
            }
            try! uiRealm.write{
                taskToBeUpdated.isCompleted = true
                self.readTasksAndUpateUI()
            }
            
        }
        return [deleteAction, editAction, doneAction]
    }


}
