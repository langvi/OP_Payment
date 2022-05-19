//
//  ViewController.swift
//  Runner
//
//  Created by Sunshine User on 17/05/2022.
//

import UIKit
class ViewController: UIViewController {
    
    @IBOutlet weak var tfInfomationOrder: UITextField!
    @IBOutlet weak var tfAmount: UITextField!
    static let ACCESS_CODE_PAYGATE = "6BEB2546" // Onepay send for merchant
    static let MERCHANT_PAYGATE = "TESTONEPAY" //  Merchant register with onepay
    static let HASH_KEY = "6D0870CDE5F24F34F3915FB0045120DB" // Onepay send for merchant
    static let URL_SCHEMES = "OnepayPaygateIOSDemo" // get CFBundleURLSchemes in Info.plist
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //        self.tfInfomationOrder.text = "\(ViewController.MERCHANT_PAYGATE) test"
        //        self.tfAmount.text = "1000"
        //        self.tfAmount.keyboardType = .decimalPad
    }
    
    @IBAction func payment(_ sender: Any) {
        if let amount = Double("10000") {
            let requestEntity = OpPayment
                .shared
                .createURLPayment(amount: amount,
                                  orderInformation:  "",
                                  currency: CurrencyOnePay.VND,
                                  accessCode: ViewController.ACCESS_CODE_PAYGATE,
                                  merchant: ViewController.MERCHANT_PAYGATE,
                                  hashKey: ViewController.HASH_KEY,
                                  urlSchemes: ViewController.URL_SCHEMES)
            let controller = WebOnepayPaymentViewController(nibName: "WebOnepayPaymentViewController",
                                                            bundle: Bundle(for: WebOnepayPaymentViewController.self))
            controller.orderPayment = requestEntity
            controller.delegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func openResultViewController(viewcontroller: UIViewController,message: String) {
        let storybroad = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storybroad.instantiateViewController(withIdentifier: "ResultPaymentViewController") as! ResultPaymentViewController
        controller.message = message
        viewcontroller.present(controller, animated: true, completion: nil)
    }
}

extension ViewController: WebOnepayPaymentViewDelegate {
    func resultOrderPayment(paymentViewController: UIViewController,
                            isSuccess: Bool,
                            amount: String,
                            card: String,
                            card_number: String,
                            command: String,
                            merchTxnRef: String,
                            merchant: String,
                            message: String,
                            orderInfo: String,
                            payChannel: String,
                            transactionNo: String,
                            version: String) {
        if isSuccess {
            self.openResultViewController(
                viewcontroller:paymentViewController,
                message: "Thanh toán thành công")
        }else {
            self.openResultViewController(
                viewcontroller:paymentViewController,
                message: "Thanh toán thất bại")
        }
    }
    
    func showLoading(paymentViewController: UIViewController) {
        print("show loading view")
    }
    
    func hidenLoading(paymentViewController: UIViewController) {
        print("hidden loading view")
    }
    
    func failConnect(paymentViewController: UIViewController, error: OnepayErrorResult) {
        var messageError:String
        switch error.errorCase {
        case .MOBILE_NOT_APP_BANKING:
            messageError = "\(error.appMobieBanking) doesn't install or not config in LSApplicationQueriesSchemes"
            break
        case .NOT_CONNECT_WEB_ONEPAY:
            messageError = "\(error.error?.localizedDescription ?? "not connect web onepay"). Please check the information set onepay sent."
            break
        case .NOT_FOUND_APP_BANKING:
            messageError = "App banking isn't exist. Contact the onepay developer with information of the message field in error."
            break
        default:
            messageError = "app not connect web onepay.Contact onepay for support."
            break
        }
        self.openResultViewController(
            viewcontroller:paymentViewController,
            message: messageError)
    }
    
    
}
