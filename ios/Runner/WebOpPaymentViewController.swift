//
//  WebOpPaymentViewController.swift
//  Runner
//
//  Created by LangVi on 17/05/2022.
//

import UIKit
import WebKit
import SwiftUI

public protocol WebOnepayPaymentViewDelegate: class {
    /// Handle payment results returned by onepay
    /// - Parameters:
    ///      - paymentViewController: WebOnepayPaymentViewController
    ///      -  isSuccess: result payment ( true = success, false = failed)
    ///      -  amount: amount of order
    ///      -  transactionNo: transaction no to cdr
    /// - Returns: nil
    /// - Note: Handle payment results returned by onepay, you can handle hidden paymentViewController or open another paymentViewController depending on your business
    func resultOrderPayment(
        paymentViewController: UIViewController,
        isSuccess: Bool,
        amount: String,
        card: String,
        card_number: String,
        command: String,
        merchTxnRef: String,
        merchant: String,
        message:String,
        orderInfo: String,
        payChannel: String,
        transactionNo: String,
        version: String)
    
    /// Handle loading when visible controller equals WebOnepayPaymentViewController
    /// - Parameters:
    ///      - paymentViewController: WebOnepayPaymentViewController
    /// - Returns: nil
    /// - Note: Handle show loading when open web proccessing
    func showLoading(paymentViewController: UIViewController)
    
    /// Handle loading done when visible controller equals WebOnepayPaymentViewController
    /// - Parameters:
    ///      - paymentViewController: WebOnepayPaymentViewController
    /// - Returns: nil
    /// - Note: Handle hidden loading when open web proccessing
    func hidenLoading(paymentViewController: UIViewController)
    
    /// create url which direct web onepay to payment oder
    /// - Parameters:
    ///      - paymentViewController: WebOnepayPaymentViewController
    ///      -  error: order information
    /// - Returns: nil
    /// - Note: Handle errors returned by onepay, See also the error codes described below this document
    func failConnect(paymentViewController: UIViewController, error: OnepayErrorResult)
}

public enum OnepayErrorCase {
    case MOBILE_NOT_APP_BANKING // app mobile banking doesn't install or not config in LSApplicationQueriesSchemes
    case NOT_CONNECT_WEB_ONEPAY // app not connect web onepay.Please check the information set onepay sent.
    case NOT_FOUND_APP_BANKING // App banking isn't exist. Contact the onepay developer with information of the message field in error.
    case WEB_ONEPAY_STATUS_500 // app not connect web onepay.Contact onepay for support.
}

public class OnepayErrorResult: Error {
    public var errorCase:OnepayErrorCase
    public var appMobieBanking: String = ""
    public var message: String = ""
    public var error: Error? = nil
    init(errorCase:OnepayErrorCase) {
        self.errorCase = errorCase
    }
}

public class WebOnepayPaymentViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    public var orderPayment: OnepayPaymentEntity?
    public weak var delegate: WebOnepayPaymentViewDelegate?
    public var result: FlutterResult?
    var dictApp = [
        "f5smartaccount" : "id1470378562",
        "viviet" : "id1055088382",
        "kienlongbankmobilebanking" : "id1492432328",
        "oceanbankmobilebanking" : "id1033968672",
        "acbapp" : "id950141024",
        "vietbankmobilebanking" : "id1469883896",
        "vabmobilebanking" : "id910897337",
        "Sgbmobile" : "id954973621",
        "seabankmobile" : "id846407152",
        "bidcvnmobile" : "id1043501726",
        "eximbankmobile" : "id1242260338",
        "qpaymobile" : "id1292194225",
        "vibmobile" : "id949371011",
        "shbmobile" : "id538278798",
        "ncbsmartbanking" : "id1111830467",
        "ivbmobilebanking" : "id1096963960",
        "abbankmobile" : "id1137160023",
        "scbmobilebanking" : "id954973621",
        "vpbankonline" : "id1209349510",
        "msbmobile" : "id436134873",
        "vietinbankmobile" : "id689963454",
        "bidvsmartbanking" : "id1061867449",
        "agribankmobile" : "id935944952",
        "vcbpaymobile" : "id1408592505",
        "vietcombankmobile" : "id561433133",
    ]
    @objc private func popViewController() {
        // Add custom logic code
        navigationController?.popViewController(animated: true)
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let payment = orderPayment {
            webView.load(URLRequest(url: payment.requestURL))
        }
        webView.navigationDelegate = self
        self.webView.isOpaque = false
        self.webView.backgroundColor = UIColor.clear
        self.webView.scrollView.backgroundColor = UIColor.clear
    }
    
    public func reloadWebview() {
        if let payment = orderPayment {
            webView.load(URLRequest(url: payment.requestURL))
        }
    }
    
    func handleOpenLinkError(url :URL, appID: String) {
        // handle unable to open the app, perhaps redirect to the App Store
        if let idx = url.absoluteString.firstIndex(of: ":") {
            let mobileBankApp: String = String(url.absoluteString.prefix(upTo: idx))
            print("App Mobie Banking: \(mobileBankApp)")
            if let url = URL(string: "itms-apps://apple.com/app/" + appID) {
                UIApplication.shared.open(url)
            }else {
                let errorCase = OnepayErrorResult(errorCase: OnepayErrorCase.MOBILE_NOT_APP_BANKING)
                errorCase.appMobieBanking = String(mobileBankApp)
                self.delegate?.failConnect(paymentViewController: self,error: errorCase)
            }
        }
        else {
            let errorCase = OnepayErrorResult(errorCase: OnepayErrorCase.NOT_FOUND_APP_BANKING)
            errorCase.message = url.absoluteString
            self.delegate?.failConnect(paymentViewController: self,error: errorCase)
        }
    }
    
    func openCustomURLScheme(customURLScheme: String, appID: String) {
        let url = URL(string: customURLScheme)!
        UIApplication.shared.open(url) { success in
            if !success {
                self.handleOpenLinkError(url: url, appID: appID)
            }
        }
    }
    
    func dissmisWebOnepayPaymentViewController() {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: false)
        }else {
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension WebOnepayPaymentViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // hidden loading
        delegate?.hidenLoading(paymentViewController: self)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // show loading
        delegate?.showLoading(paymentViewController: self)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // hidden loading and show error
        delegate?.hidenLoading(paymentViewController: self)
        let errorCase = OnepayErrorResult(errorCase: OnepayErrorCase.NOT_CONNECT_WEB_ONEPAY)
        errorCase.error = error
        delegate?.failConnect(paymentViewController: self, error: errorCase)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let url = navigationAction.request.url, let payment = orderPayment{
            print("urlContext: \(url.absoluteString.lowercased())")
            if url.absoluteString.lowercased().starts(with: payment.returnURL.lowercased()) {
                // handle response
                let code = url.getQueryStringParameter(param: "vpc_TxnResponseCode")
                var isSuccess = false
                if code.elementsEqual("0") {
                    isSuccess = true
                }
                delegate?.resultOrderPayment(
                    paymentViewController: self,
                    isSuccess: isSuccess,
                    amount: url.getQueryStringParameter(param: "vpc_Amount"),
                    card: url.getQueryStringParameter(param: "vpc_Card"),
                    card_number: url.getQueryStringParameter(param: "vpc_CardNum"),
                    command: url.getQueryStringParameter(param: "vpc_Command"),
                    merchTxnRef: url.getQueryStringParameter(param: "vpc_MerchTxnRef"),
                    merchant: url.getQueryStringParameter(param: "vpc_Merchant"),
                    message: url.getQueryStringParameter(param: "vpc_Message"),
                    orderInfo: url.getQueryStringParameter(param: "vpc_OrderInfo"),
                    payChannel: url.getQueryStringParameter(param: "vpc_PayChannel"),
                    transactionNo: url.getQueryStringParameter(param: "vpc_TransactionNo"),
                    version: url.getQueryStringParameter(param: "vpc_Version"))
                decisionHandler(.cancel)
                // callback to flutter
                if result != nil {
                    
                    result!(isSuccess)
                }
                popViewController()
                return
            }else if url.absoluteString.starts(with: OpPayment.AGAIN_LINK) {
                decisionHandler(.cancel)
                return
            }else  if !url.absoluteString.starts(with: "http") {
                let dataArray = url.absoluteString.split{$0 == "&"}.map(String.init)
                if dataArray.count > 0 {
                    self.openCustomURLScheme(customURLScheme: dataArray[0],
                                             appID: dataArray[dataArray.count - 1])
                }
            }
        }
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let response = navigationResponse.response as? HTTPURLResponse {
            if response.statusCode > 299 {
                let errorCase = OnepayErrorResult(errorCase: OnepayErrorCase.WEB_ONEPAY_STATUS_500)
                errorCase.message = response.description
                delegate?.failConnect(paymentViewController: self,error: errorCase)
            }
        }
        decisionHandler(.allow)
    }
}


class TopView: UIView{
    
}
