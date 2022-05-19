import UIKit
import Flutter
import SwiftUI
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
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
    
            }
            else {
                return
            }
            
        })
    }
}
