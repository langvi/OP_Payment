//
//  SceneDelegate.swift
//  Runner
//
//  Created by Sunshine User on 17/05/2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

extension SceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let returnURL = "\(ViewController.URL_SCHEMES)://onepay"
        var urlResultPaygate = ""
        var isCurrentControllerEqualOnepayPaymentVC = false
        // analysis data from callback of app bank get url result of payment
        for context in URLContexts {
            var exits = false
            if context.url.absoluteString.starts(with: returnURL) {
                if let dataString = context.url.absoluteString.components(separatedBy: "?").last {
                    let dataArray = dataString.split{$0 == "/"}.map(String.init)
                    if let urlDirection = dataArray[dataArray.count - 1].removingPercentEncoding {
                        if !urlDirection.starts(with: "http") {
                            urlResultPaygate = "https://onepay.vn/paygate/general/?" + urlDirection
                        }else {
                            urlResultPaygate = urlDirection
                        }
                        print(urlDirection)
                    }
                }
                exits = true
            }
            if exits {
                break
            }
        }
        // callback result payment from app of bank when call web onepay
        if let requestURL = URLComponents(string: urlResultPaygate)?.url {
            if let wd = self.window {
                var vc = wd.rootViewController
                if(vc is UINavigationController){
                    vc = (vc as! UINavigationController).visibleViewController
                    if (vc is WebOnepayPaymentViewController) {
                        isCurrentControllerEqualOnepayPaymentVC = true
                        self.updateDataToOnePayPaymentViewController(
                            viewController: vc as! WebOnepayPaymentViewController,
                            requestURL: requestURL, returnURL: returnURL)
                    }
                }
                
                if(vc is WebOnepayPaymentViewController){
                    isCurrentControllerEqualOnepayPaymentVC = true
                    self.updateDataToOnePayPaymentViewController(
                        viewController: vc as! WebOnepayPaymentViewController,
                        requestURL: requestURL, returnURL: returnURL)
                }
            }
            if !isCurrentControllerEqualOnepayPaymentVC {
                self.openOnePayPaymentViewController(requestURL: requestURL, returnURL: returnURL)
            }
        }
    }
    
    func updateDataToOnePayPaymentViewController(viewController: WebOnepayPaymentViewController, requestURL: URL, returnURL: String) {
        viewController.orderPayment = OnepayPaymentEntity(requestURL: requestURL, returnURL: returnURL)
        viewController.reloadWebview()
    }
    
    func openOnePayPaymentViewController(requestURL: URL, returnURL: String) {
        let controller = WebOnepayPaymentViewController(nibName: "WebOnepayPaymentViewController", bundle: Bundle(for: WebOnepayPaymentViewController.self))
        controller.orderPayment = OnepayPaymentEntity(requestURL: requestURL, returnURL: returnURL)
        controller.delegate = self
        
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
    
    func openResultViewController(message: String) {
        let storybroad = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storybroad.instantiateViewController(withIdentifier: "ResultPaymentViewController") as! ResultPaymentViewController
        controller.message = message
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
}

extension SceneDelegate : WebOnepayPaymentViewDelegate {
    
    func resultOrderPayment(paymentViewController: UIViewController, isSuccess: Bool, amount: String, card: String, card_number: String, command: String, merchTxnRef: String, merchant: String, message: String, orderInfo: String, payChannel: String, transactionNo: String, version: String) {
        if isSuccess {
            self.openResultViewController(message: "Thanh toán thành công")
        }else {
            self.openResultViewController(message: "Thanh toán thất bại")
        }
    }
    
    func showLoading(paymentViewController: UIViewController) {
        
    }
    
    func hidenLoading(paymentViewController: UIViewController) {
        
    }
    
    func failConnect(paymentViewController: UIViewController,error: OnepayErrorResult) {
        self.openResultViewController(message: "Thanh toán thất bại")
    }
}


