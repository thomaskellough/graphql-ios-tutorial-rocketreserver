//
//  LoginViewController.swift
//  RocketReserver
//
//  Created by Thomas Kellough on 5/9/21.
//

import UIKit
import KeychainSwift

class LoginViewController: UIViewController {
    
    private var emailTextField: UITextField!
    private var errorLabel: UILabel!
    private var submitButton: UIButton!
    
    static let loginKeychainKey = "login"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGreen
        
        setupViews()
    }
    
    @objc private func submitTapped() {
        self.errorLabel.text = nil
        self.enableSubmitButton(false)
        
        guard let email = self.emailTextField.text else {
            self.errorLabel.text = "Please enter an email address."
            self.enableSubmitButton(true)
            return
        }
        
        guard self.validate(email: email) else {
            self.errorLabel.text = "Please enter a valid email."
            self.enableSubmitButton(true)
            return
        }
        
        Network.shared.apollo.perform(mutation: LoginMutation(email: email)) { [weak self] result in
            defer {
                self?.enableSubmitButton(true)
            }
            
            switch result {
            case .success(let graphQLResult):
                if let token = graphQLResult.data?.login {
                    let keychain = KeychainSwift()
                    keychain.set(token, forKey: LoginViewController.loginKeychainKey)
                    self?.navigationController?.popViewController(animated: true)
                }
                
                if let errors = graphQLResult.errors {
                    print("Errors from server: \(errors)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }

    }
    
    private func enableSubmitButton(_ isEnabled: Bool) {
        self.submitButton.isEnabled = isEnabled
        if isEnabled {
            self.submitButton.setTitle("Submit", for: .normal)
        } else {
            self.submitButton.setTitle("Submitting...", for: .normal)
        }
    }
    
    private func validate(email: String) -> Bool {
        return email.contains("@")
    }
    
    @objc private func cancelTapped() {
        self.dismiss(animated: true)
    }
    
    func setupViews() {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleLabel.textAlignment = .center
        titleLabel.text = "Login"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emailTextField = UITextField()
        emailTextField.placeholder = "Email address"
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        
        errorLabel = UILabel()
        errorLabel.text = "Errors"
        errorLabel.textAlignment = .center
        errorLabel.textColor = .red
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        submitButton = UIButton()
        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(errorLabel)
        view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.heightAnchor.constraint(equalToConstant: 44),
            
            emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailTextField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8),
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8),
            errorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 8),
            errorLabel.heightAnchor.constraint(equalToConstant: 44),
            
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8),
            submitButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            
        ])
    }
}
