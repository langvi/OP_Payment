//
//  ResultPaymentViewController.swift
//  Runner
//
//  Created by Sunshine User on 17/05/2022.
//

import UIKit

class ResultPaymentViewController: UIViewController {

    @IBOutlet weak var lblResult: UILabel!
    
    var message: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.lblResult.text = message
    }
    
    @IBAction func backToHome(_ sender: Any) {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
              fatalError("could not get scene delegate ")
            }
        let storybroad = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storybroad.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        sceneDelegate.window?.rootViewController = controller
        sceneDelegate.window?.makeKeyAndVisible()
    }
}

