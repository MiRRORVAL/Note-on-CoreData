
import UIKit
import CoreData




class ViewController: UITableViewController {
    
    private let cellID = "cell"
    private var tasks: [Task] = []
    private let managedContext = (
        UIApplication.shared.delegate as! AppDelegate
        )
        .persistentContainer.viewContext
    var colorMuve = 0.0
    var colorMuveIsReversed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        // Table view cell register
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    /// Setup view
    private func setupView() {
        view.backgroundColor = .systemBackground
        setupNavigationBar()
    }
    
    /// Setup navigation bar
    private func setupNavigationBar() {
        
        // Set title for navigation bar
        title = "Ежедневник"
        
        // Title color
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.black
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.darkGray
        ]
        
        // Navigation bar color
        navigationController?.navigationBar.barTintColor = UIColor(
            displayP3Red: 255/255,
            green: 255/255,
            blue: 255/255,
            alpha: 255/255
        )
        
        // Set large title
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add button to navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Добавить",
            style: .plain,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .darkGray
    }
    
    @objc private func addNewTask() {
        showAddAlert(title: "Новая задача", message: "Что вы хотите сделать?")
    }

}

// MARK: - UITableViewDataSource
extension ViewController {
    
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
        ) -> Int {
        
        return tasks.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID,
                                                 for: indexPath)
        
        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.name
            if colorMuve < 1.0 && colorMuveIsReversed == false {
                colorMuve += 0.03
                print("1")
            } else if colorMuve >= 1.0 {
                colorMuveIsReversed = true
                colorMuve -= 0.03
                print("2")
            } else if colorMuve > 0.0 && colorMuveIsReversed == true {
                colorMuve -= 0.03
                print("3")
            } else if colorMuve <= 0.0 {
                colorMuveIsReversed = false
                colorMuve += 0.03
                print("4")
            }
            print(colorMuve)
            let color = CGColor.init(genericCMYKCyan: 0.4, magenta: 0.2,
                                     yellow: colorMuve, black: 0.1, alpha: 0.2)
            cell.backgroundColor = .init(cgColor: color)
            
            
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fullTask = tasks[indexPath.row]
        showEditAlert(title: "Редактор",
                      message: "Что вы хотите сделать?",
                      fullTask: fullTask,
                      rowIndex: indexPath.item)
    }
}

// MARK: - Work with Data Base
extension ViewController {
    
    // Fetch data
    private func fetchData() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest() // Запрос выборки по ключу Task
        
        do {
            tasks = try managedContext.fetch(fetchRequest) // Заполнение массива данными из базы
            tableView.reloadData()
        } catch let error {
            print("Failed to fetch data", error)
        }
    }
    
    // Save data
    private func saveTask(_ taskName: String) {
        
        guard let entity = NSEntityDescription.entity(
            forEntityName: "Task",
            in: managedContext
            ) else { return } // Create entity
        
        let task = NSManagedObject(entity: entity,
                                   insertInto: managedContext) as! Task // Task instace
        task.name = taskName // New value for task name
        
        do {
            try managedContext.save()
            tasks.append(task)
            tableView.insertRows(
                at: [IndexPath(row: tasks.count - 1, section: 0)],
                with: .automatic
            )
        } catch let error {
            print("Failed to save task", error.localizedDescription)
        }
    }
    
    private func editTask(_ taskName: String, taskForwordIn: Task, rowIndex: Int) {
        do {
            taskForwordIn.name = taskName
            try managedContext.save()
            
            tasks[rowIndex].name = taskName
            tableView.reloadRows(
                at: [IndexPath(row: rowIndex, section: 0)],
                with: .automatic)
            
        } catch let error {
            print("Failed to save task", error.localizedDescription)
        }
    }
}

// MARK: - Setup Alert Controller
extension ViewController {
    
    private func showAddAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        // Save action
        let saveAction = UIAlertAction(title: "Сохранить", style: .default) { _ in
            
            guard let newValue = alert.textFields?.first?.text else { return }
            guard !newValue.isEmpty else { return }
            
            self.saveTask(newValue)
        }
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Отмена", style: .destructive) { _ in
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    
    
    
    
    
    private func showEditAlert(title: String, message: String, fullTask: Task, rowIndex: Int) {
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        // edit action
        let editAction = UIAlertAction(title: "Отредактировать", style: .default) { _ in
            guard let editedValue = alert.textFields?.first?.text else { return }
            guard !editedValue.isEmpty else { return }
            self.editTask(editedValue, taskForwordIn: fullTask, rowIndex: rowIndex)
        }
        
        // delete action
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { _ in
            do {
                self.managedContext.delete(fullTask)
                self.tasks.remove(at: rowIndex)
                try self.managedContext.save()
                self.tableView.deleteRows(
                    at: [IndexPath(row: rowIndex, section: 0)],
                    with: .automatic)
            } catch let error {
                print("Failed to delete task", error.localizedDescription)
            }
        }
        
        alert.addTextField()
        alert.textFields?.first?.text = fullTask.name
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true)
    }
}
