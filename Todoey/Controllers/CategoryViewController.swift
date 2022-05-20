//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Nguyen NGO on 16/05/2022.
//  Copyright © 2022 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class CategoryViewController: SwipeTableViewController {
    
    let realm = try! Realm() //initialize Realm Object for database
    
    var categories: Results<Category>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init array to be printed to TableView
        loadCategories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let navBar = navigationController?.navigationBar else { return }

        let gradientColor = GradientColor(.topToBottom, frame: UIScreen.main.bounds, colors: Array(arrayLiteral: K.Colors.firstColor, K.Colors.secondColor, K.Colors.thirdColor))
        let contrastTextColor = ContrastColorOf(gradientColor, returnFlat: true)
        
        navBar.backgroundColor = nil
        navBar.tintColor = contrastTextColor //UIColor.black
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: contrastTextColor] //UIColor.black
        tableView.backgroundColor = gradientColor
    }

    //MARK: - Add IBAction Pressed
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "New category", message: "Add a new category for your items", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            let newCategory = Category()
            newCategory.name = textField.text!.isEmpty ? "Untitled category" : textField.text!
            newCategory.hexColor = UIColor.randomFlat().hexValue()
            
            self.save(category: newCategory)
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Add new category"
            alertTextField.autocapitalizationType = .words
            textField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancelButton)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - TableView Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        var textColor: UIColor?
        
        let category = categories?[indexPath.row]
        
        if let color = UIColor(hexString: category!.hexColor) {
            textColor = ContrastColorOf(color, returnFlat: true)
        }
        
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.textProperties.color = textColor!
            content.text = category?.name ?? "No categories added yet"
            cell.contentConfiguration = content
        } else {
            // Fallback on earlier versions
            cell.textLabel?.textColor = textColor
            cell.textLabel?.text = category?.name ?? "No categories added yet"
        }
        
        cell.backgroundColor = UIColor(hexString: category!.hexColor)
        
        return cell
    }
    
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.segueToItems, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        destinationVC.selectedCategory = categories?[indexPath.row]
    }
    
    //MARK: - Data Manipulation Methods
    func save(category: Category) {
        
        do {
            try realm.write({
                realm.add(category)
            })
        } catch {
            print("Error saving data: \(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadCategories() {
        
        categories = realm.objects(Category.self)
        
        tableView.reloadData()
    }
    
    override func updateModel(at indexPath: IndexPath) {
        do {
            try self.realm.write({
                self.realm.delete(self.categories![indexPath.row])
            })
        } catch {
            print("Error deleting category: \(error)")
        }
    }
    
}
