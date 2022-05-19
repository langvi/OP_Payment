import UIKit
import Flutter
import SwiftUI
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    static let ACCESS_CODE_PAYGATE = "22772CEF" // Onepay send for merchant
    static let MERCHANT_PAYGATE = "TESTONEPAY" //  Merchant register with onepay
    static let HASH_KEY = "6D0870CDE5F24F34F3915FB0045120DB" // Onepay send for merchant
    static let URL_SCHEMES = "OnepayPaygateIOSDemo" // g
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let deviceChannel = FlutterMethodChannel(name: "tuanchaubooking/onepay_gateway",
                                                 binaryMessenger: controller.binaryMessenger)
        prepareMethodHandler(deviceChannel: deviceChannel)
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    private func prepareMethodHandler(deviceChannel: FlutterMethodChannel) {
        deviceChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            if call.method == "create_url" {
                guard let resultFlutter = call.arguments else {
                    return
                }
                let myresult = resultFlutter as? [String: Any]
                let data = myresult?["amount"] as? String
                
                let amount = Double(data!)
                let requestEntity = OpPayment
                    .shared
                    .createURLPayment(amount: amount!,
                                      orderInformation:  "info",
                                      currency: CurrencyOnePay.VND,
                                      accessCode: ViewController.ACCESS_CODE_PAYGATE,
                                      merchant: ViewController.MERCHANT_PAYGATE,
                                      hashKey: ViewController.HASH_KEY,
                                      urlSchemes: ViewController.URL_SCHEMES)
                let controller = WebOnepayPaymentViewController(nibName: "WebOnepayPaymentViewController",
                                                                bundle: Bundle(for: WebOnepayPaymentViewController.self))
                print(requestEntity.requestURL.path)
                controller.orderPayment = requestEntity
                controller.delegate = ViewController()
                let navigationController = UINavigationController(rootViewController: controller)
                self.window.rootViewController = navigationController
                self.window.makeKeyAndVisible()
                //                controller.orderPayment = OnepayPaymentEntity(requestURL: URL(fileURLWithPath: "ijsada"), returnURL: "")
                //                let navigationController = UINavigationController(rootViewController: controller)
                //                let controller = ViewController()
                //                let navigationController = UINavigationController(rootViewController: controller)
                //                self.window.rootViewController = navigationController
                //                self.window.makeKeyAndVisible()
                //                controller.delegate = self
                //                let mainBoard = UIStoryboard(name: "Main", bundle: Bundle(for: WebOnepayPaymentViewController.self))
                //                let homePage = mainBoard.instantiateViewController(withIdentifier: "WebOnepayPaymentViewController") as! WebOnepayPaymentViewController
                //                homePage.orderPayment = requestEntity
                //                self.window.rootViewController = homePage
                //                controller.delegate = WebOnepayPaymentViewDelegate.self
                //                NavigationLink(destination: WebOnepayPaymentViewController())
                //                self.present(controller, animated: true, completion: nil)
                //                let op = OpPayment()
                //                let url = op.createURLPayment(amount: amount!, orderInformation: "Info", accessCode: AppDelegate.ACCESS_CODE_PAYGATE, merchant: AppDelegate.MERCHANT_PAYGATE, hashKey: AppDelegate.HASH_KEY, urlSchemes: AppDelegate.URL_SCHEMES)
                //                result(url)
            }
            else {
                return
            }
            
        })
    }
}
