//
//  ViewController.swift
//  Messenger
//
//  Created by Mahmud CIKRIK on 3.01.2024.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
        
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}




// User Defaults auth
//let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
//
//if !isLoggedIn {
//    let vc = LoginViewController()
//    let nav = UINavigationController(rootViewController: vc)
//    nav.modalPresentationStyle = .fullScreen
//    present(nav, animated: false)
//}
