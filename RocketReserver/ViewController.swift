//
//  ViewController.swift
//  RocketReserver
//
//  Created by Thomas Kellough on 5/8/21.
//

import Apollo
import SDWebImage
import UIKit

class ViewController: UIViewController {

    var launches = [LaunchListQuery.Data.Launch.Launch]()
    var tableView: UITableView!
    
    private var lastConnection: LaunchListQuery.Data.Launch?
    private var activeRequest: Cancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Launches"
        navigationController?.navigationBar.barTintColor = UIColor.systemBackground
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        self.loadMoreLaunchesIfTheyExist()
    }
    
    private func loadMoreLaunches(from cursor: String?) {
        self.activeRequest = Network.shared.apollo.fetch(query: LaunchListQuery(cursor: cursor)) { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.activeRequest = nil
            defer {
                self.tableView.reloadData()
            }
            
            switch result {
            case .success(let graphQLResult):
                if let launchConnection = graphQLResult.data?.launches {
                    self.lastConnection = launchConnection
                    self.launches.append(contentsOf: launchConnection.launches.compactMap { $0 })
                }
                
                if let errors = graphQLResult.errors {
                    let message = errors.map { $0.localizedDescription }.joined(separator: "\n")
                    self.showErrorAlert(title: "GraphQL Error(s)", message: message)
                }
            case .failure(let error):
                let title = "Network error"
                self.showErrorAlert(title: title, message: error.localizedDescription)
            }
        }
    }
    
    private func loadMoreLaunchesIfTheyExist() {
        guard let connection = self.lastConnection else {
            self.loadMoreLaunches(from: nil)
            return
        }
        
        guard connection.hasMore else {
            return
        }
        
        self.loadMoreLaunches(from: connection.cursor)
    }
}

// MARK: TableView Data Source
extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        ListSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let listSection = ListSection(rawValue: section) else {
            assertionFailure("Invalid section")
            return 0
        }
        
        switch listSection {
        case .launches:
            return self.launches.count
        case .loading:
            if self.lastConnection?.hasMore == false {
                return 0
            } else {
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SubtitleTableViewCell
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        
        guard let listSection = ListSection(rawValue: indexPath.section) else {
            assertionFailure("Invalid section")
            return cell
        }
        
        switch listSection {
        case .launches:
            let launch = self.launches[indexPath.row]
            cell.textLabel?.text = launch.mission?.name
            cell.detailTextLabel?.text = launch.site
            
            let placeholder = UIImage(named: "placeholder")
            
            if let missionPatch = launch.mission?.missionPatch {
                cell.imageView?.sd_setImage(with: URL(string: missionPatch)!, placeholderImage: placeholder)
            } else {
                cell.imageView?.image = placeholder
            }
            
        case .loading:
            if self.activeRequest == nil {
                cell.textLabel?.text = "Tap to load more"
            } else {
                cell.textLabel?.text = "Loading..."
            }
        }
        
        return cell
    }
    
    
}

// MARK: TableView Delegate Methods
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let listSection = ListSection(rawValue: indexPath.section) else {
            assertionFailure("Invalid section")
            return
        }
        
        switch listSection {
        case .launches:
            let launch = launches[indexPath.row]
            let vc = DetailViewController()
            vc.launchID = launch.id
            
            navigationController?.pushViewController(vc, animated: true)
        case .loading:
            self.tableView.deselectRow(at: indexPath, animated: true)
            
            if self.activeRequest == nil {
                self.loadMoreLaunchesIfTheyExist()
            }
            
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            break
        }
    }
}

// MARK: Section enum
extension ViewController {
    enum ListSection: Int, CaseIterable {
        case launches
        case loading
    }
}

// MARK: Errors
extension ViewController {
    private func showErrorAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
}

// MARK: Custom subtitle cell
class SubtitleTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    
    func showAlertForErrors(_ errors: [GraphQLError]) {
        let message = errors
            .map { $0.localizedDescription }
            .joined(separator: "\n")
        self.showAlert(title: "GraphQL Error(s)", message: message)
    }
}
