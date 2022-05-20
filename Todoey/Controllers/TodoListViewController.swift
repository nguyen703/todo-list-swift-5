import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    let realm = try! Realm()
    
    var items: Results<Item>?
    
    // this variable helps loading the correct items
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.showsCancelButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Set color for navigation bar and status bar
        if let colorHex = selectedCategory?.hexColor {
            guard let navBar = navigationController?.navigationBar else { return }
            
            title = selectedCategory!.name
            let contrastTextColor = ContrastColorOf(UIColor(hexString: colorHex)!, returnFlat: true)
            
            navBar.backgroundColor = UIColor(hexString: colorHex)
            navBar.tintColor = contrastTextColor
            navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: contrastTextColor]
            searchBar.barTintColor = UIColor(hexString: colorHex)
            searchBar.searchTextField.textColor = contrastTextColor
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: contrastTextColor], for: .normal) //Cancel button
            tableView.backgroundColor = UIColor(hexString: colorHex)
        }
    }
    
    //MARK: - TableView Datasource methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        var backgroundColor = UIColor.white
        var textColor = UIColor.black
        
        //Get cell background and text color
        if let color = UIColor(hexString: selectedCategory!.hexColor)?.darken(byPercentage: CGFloat(indexPath.row)/CGFloat(items!.count)) {
            backgroundColor = color
            textColor = ContrastColorOf(color, returnFlat: true)
        }
        
        guard let item = items?[indexPath.row] else { return cell }

        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            var background = cell.backgroundConfiguration
            
            background?.backgroundColor = backgroundColor
            content.textProperties.color = textColor
            content.text = item.title
            
            cell.contentConfiguration = content
            cell.backgroundConfiguration = background
        } else {
            // Fallback on earlier versions
            cell.textLabel?.text = item.title
            cell.textLabel?.textColor = textColor
            cell.backgroundColor = backgroundColor
        }
        cell.accessoryType = item.done ? .checkmark : .none
        cell.tintColor = textColor
        
        return cell
    }
    
    //MARK: - TableView Delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = items?[indexPath.row] {
            do {
                try realm.write({
                    item.done = !item.done
                })
            } catch {
                print("Error toggling item status: \(error)")
            }
        }
        
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add IBAction Pressed
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add a new todo", message: "Let's do it", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!.isEmpty ? "Untitled item" : textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Error adding item: \(error)")
                }
            }
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Add new item"
            alertTextField.autocapitalizationType = .sentences
            textField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancelButton)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Models manipulation methods
    func loadItems() {
        
        items = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }
    
    override func updateModel(at indexPath: IndexPath) {
        do {
            try self.realm.write({
                self.realm.delete(self.items![indexPath.row])
            })
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
}

//MARK: - searchBar Delegate methods
extension TodoListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        items = items?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
            loadItems()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadItems()
        searchBar.text = ""
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }

}
