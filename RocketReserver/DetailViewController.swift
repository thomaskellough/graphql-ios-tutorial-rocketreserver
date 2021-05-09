//
//  DetailViewController.swift
//  RocketReserver
//
//  Created by Thomas Kellough on 5/8/21.
//

import Apollo
import KeychainSwift
import UIKit

class DetailViewController: UIViewController {

    var launchID: GraphQLID? {
        didSet {
            self.loadLaunchDetails()
        }
    }
    private var launch: LaunchDetailsQuery.Data.Launch? {
        didSet {
            self.setupViews()
        }
    }
    
    private var missionPatchImageView: UIImageView!
    private var missionNameLabel: UILabel!
    private var rocketNameLabel: UILabel!
    private var launchSiteLabel: UILabel!
    private var bookCancelButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBlue
        
        bookCancelButton = UIBarButtonItem(title: "Book now!", style: .plain, target: self, action: #selector(bookCancelTapped))
        navigationItem.rightBarButtonItem = bookCancelButton
        
        setupViews()
    }
    
    @objc func bookCancelTapped() {
        guard self.isLoggedIn() else {
            let vc = LoginViewController()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        guard let launch = self.launch else {
            // We don't have enough information yet to know
            // if we're booking or cancelling, bail.
            return
        }
        
        if launch.isBooked {
            self.cancelTrip(with: launch.id)
        } else {
            self.bookTrip(with: launch.id)
        }
    }
    
    private func isLoggedIn() -> Bool {
        let keychain = KeychainSwift()
        return keychain.get(LoginViewController.loginKeychainKey) != nil
    }
    
    private func bookTrip(with id: GraphQLID) {
        Network.shared.apollo.perform(mutation: BookTripMutation(id: id)) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let graphQLResult):
                if let bookingResult = graphQLResult.data?.bookTrips {
                    if bookingResult.success {
                        self.showAlert(title: "Success!",
                                       message: bookingResult.message ?? "Trip booked successfully")
                        self.loadLaunchDetails(forceReload: true)
                    } else {
                        self.showAlert(title: "Could not book trip",
                                       message: bookingResult.message ?? "Unknown failure.")
                    }
                }
                
                if let errors = graphQLResult.errors {
                    self.showAlertForErrors(errors)
                }
            case .failure(let error):
                self.showAlert(title: "Network Error",
                               message: error.localizedDescription)
            }
        }
    }
    
    private func cancelTrip(with id: GraphQLID) {
        Network.shared.apollo.perform(mutation: CancelTripMutation(id: id)) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let graphQLResult):
                if let cancelResult = graphQLResult.data?.cancelTrip {
                    if cancelResult.success {
                        self.showAlert(title: "Trip cancelled",
                                       message: cancelResult.message ?? "Your trip has been officially cancelled.")
                        self.loadLaunchDetails(forceReload: true)
                    } else {
                        self.showAlert(title: "Could not cancel trip",
                                       message: cancelResult.message ?? "Unknown failure.")
                    }
                }
                
                if let errors = graphQLResult.errors {
                    self.showAlertForErrors(errors)
                }
            case .failure(let error):
                self.showAlert(title: "Network Error",
                               message: error.localizedDescription)
            }
        }
    }
    
    func setupViews() {
        let view = UIView()
        guard let launch = self.launch else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        
        missionPatchImageView = UIImageView()
        missionPatchImageView.translatesAutoresizingMaskIntoConstraints = false
        if let missionPatch = launch.mission?.missionPatch {
            self.missionPatchImageView.sd_setImage(with: URL(string: missionPatch)!, placeholderImage: UIImage(named: "placeholder"))
        } else {
            self.missionPatchImageView.image = UIImage(named: "placeholder")
        }
        
        missionNameLabel = UILabel()
        missionNameLabel.text = "Loading..."
        missionNameLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        missionNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rocketNameLabel = UILabel()
        rocketNameLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        rocketNameLabel.translatesAutoresizingMaskIntoConstraints = false
        if let rocketName = launch.rocket?.name, let rocketType = launch.rocket?.type {
            self.rocketNameLabel.text = "🚀 \(rocketName) (\(rocketType))"
        } else {
            self.rocketNameLabel.text = nil
        }
        
        launchSiteLabel = UILabel()
        launchSiteLabel.font = UIFont.preferredFont(forTextStyle: .body)
        launchSiteLabel.numberOfLines = 0
        launchSiteLabel.translatesAutoresizingMaskIntoConstraints = false
        if let site = launch.site {
            self.launchSiteLabel.text = "Launching from \(site)"
        } else {
            self.launchSiteLabel.text = nil
        }
        
        if launch.isBooked {
            self.bookCancelButton.title = "Cancel trip"
            self.bookCancelButton.tintColor = .red
        } else {
            self.bookCancelButton.title = "Book now!"
            self.bookCancelButton.tintColor = self.view.tintColor
        }
        
        view.addSubview(missionPatchImageView)
        view.addSubview(missionNameLabel)
        view.addSubview(rocketNameLabel)
        view.addSubview(launchSiteLabel)
        self.view.addSubview(view)
        
        NSLayoutConstraint.activate([
            missionPatchImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            missionPatchImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            missionPatchImageView.heightAnchor.constraint(equalTo: view.heightAnchor),
            
            missionNameLabel.leadingAnchor.constraint(equalTo: missionPatchImageView.trailingAnchor, constant: 8),
            missionNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            missionNameLabel.heightAnchor.constraint(equalToConstant: 44),
            missionNameLabel.bottomAnchor.constraint(equalTo: rocketNameLabel.topAnchor),
            
            rocketNameLabel.leadingAnchor.constraint(equalTo: missionPatchImageView.trailingAnchor, constant: 8),
            rocketNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rocketNameLabel.heightAnchor.constraint(equalToConstant: 44),
            rocketNameLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            launchSiteLabel.leadingAnchor.constraint(equalTo: missionPatchImageView.trailingAnchor, constant: 8),
            launchSiteLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            launchSiteLabel.heightAnchor.constraint(equalToConstant: 44),
            launchSiteLabel.topAnchor.constraint(equalTo: rocketNameLabel.bottomAnchor),
            
            view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 32),
            view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4)
        ])
    }
    
    private func loadLaunchDetails(forceReload: Bool = false) {
        guard let launchID = self.launchID else { return }
        guard launchID != self.launch?.id || forceReload else { return }
        
        let cachePolicy: CachePolicy
        if forceReload {
            cachePolicy = .fetchIgnoringCacheCompletely
        } else {
            cachePolicy = .returnCacheDataElseFetch
        }
        
        Network.shared.apollo.fetch(query: LaunchDetailsQuery(id: launchID), cachePolicy: cachePolicy) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            case .success(let graphQLResult):
                if let launch = graphQLResult.data?.launch {
                    self.launch = launch
                }
                
                if let errors = graphQLResult.errors {
                    print("GraphQL errors: \(errors)")
                }
            }
        }
    }

}
