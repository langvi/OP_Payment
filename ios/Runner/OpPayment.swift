//
//  OpPayment.swift
//  Runner
//
//  Created by Lang vi on 17/05/2022.
//

import Foundation
import CommonCrypto
public enum NetworkOnepayType: String {
    case wifi = "en0"
    case cellular = "pdp_ip0"
}

public enum CurrencyOnePay: String {
    case VND = "VND"
    case USD = "USD"
}
public class OnepayPaymentEntity {
    var returnURL: String
    var requestURL: URL
    
    public init(requestURL: URL, returnURL: String) {
        self.requestURL = requestURL
        self.returnURL = returnURL
    }
}
public class OpPayment{
   
    public static let shared = OpPayment()
    private static let LINK_PAYGATE = "https://onepay.vn/paygate/vpcpay.op"
    private static let VERSION_PAYGATE = "2"
    private static let COMMAND_PAYGATE = "pay"
    private static let TICKET_NO = "10.2.20.1"
    static let AGAIN_LINK = "https://localhost/again_link"
    private static let VPC_THEME = "general"
    public func createURLPayment(
            amount: Double,
            orderInformation: String,
            currency: CurrencyOnePay = CurrencyOnePay.VND,
            accessCode: String,
            merchant: String,
            hashKey: String,
            urlSchemes: String) -> OnepayPaymentEntity {
        let code = "\(Date().timeIntervalSince1970)"
        let title = merchant
        let amountString:String = "\(UInt64(amount*100))";
        let returnURL = "\(urlSchemes)://onepay/"
        let requestURL =  self.createURLRequest (
            version: OpPayment.VERSION_PAYGATE,
            command: OpPayment.COMMAND_PAYGATE,
            accessCode: accessCode,
            merchant: merchant,
            returnURL: returnURL,
            merchTxnRef: code,
            orderInfo: orderInformation,
            amount: amountString,
            againLink: OpPayment.AGAIN_LINK,
            title:title,
            currency:currency.rawValue,
            hashKeyCustomer:hashKey
        )
        return OnepayPaymentEntity(requestURL: requestURL, returnURL: returnURL)
    }
    
    // MARK: - Private Method
    private func createURLRequest(
        version:String = VERSION_PAYGATE,
        command:String = COMMAND_PAYGATE,
        accessCode:String, //  OnePAY cấp
        merchant:String, //  OnePAY cấp
        returnURL:String, // URL Website ĐVCNTT để nhận kết quả trả về.
        merchTxnRef:String = "\(Date().timeIntervalSince1970)", // Mã giao dịch, biến số này yêu cầu là duy nhất mỗi lần gửi sang OnePAY
        orderInfo:String = "OP test",// Thông tin đơn hàng, thường là mã đơn hàng hoặc mô tả ngắn gọn về đơn hàng
        amount:String, // Khoản tiền thanh toán
        againLink:String = AGAIN_LINK, // Link trang thanh toán của website trước khi chuyển sang OnePAY
        title:String, // Tiêu đề cổng thanh toán hiển thị trên trình duyệt của chủ thẻ.
        currency: String,
        customerPhone:String? = nil,
        customerEmail:String? = nil,
        customerId:String? = nil,
        hashKeyCustomer: String
    ) -> URL {
        var ticketNo:String = self.getAddress(for: .wifi) ?? ""
        if ticketNo.elementsEqual("") {
            ticketNo = self.getAddress(for: .cellular) ?? ""
        }
        if ticketNo.elementsEqual("") {
            ticketNo = OpPayment.TICKET_NO
        }
        let amountString = amount
        var languageString = "vn"
        let language =  Locale.current.languageCode
        if language == "vi" {
            languageString = "vn"
        } else{
            languageString = "en"
        }
        var dict = [
            "vpc_Version":version,
            "vpc_Command":command,
            "vpc_AccessCode":accessCode,
            "vpc_Merchant":merchant,
            "vpc_Locale":languageString,
            "vpc_ReturnURL":returnURL,
            "vpc_MerchTxnRef":merchTxnRef,
            "vpc_OrderInfo":orderInfo,
            "vpc_Amount":amountString,
            "vpc_TicketNo":ticketNo,
            "Title":title,
            "vpc_Currency":currency,
            "vpc_Theme": OpPayment.VPC_THEME
        ]
        var queryItems = [
            URLQueryItem(name: "vpc_Version", value: version),
            URLQueryItem(name: "vpc_Command", value: command),
            URLQueryItem(name: "vpc_AccessCode", value: accessCode),
            URLQueryItem(name: "vpc_Merchant", value: merchant),
            URLQueryItem(name: "vpc_Locale", value: languageString),
            URLQueryItem(name: "vpc_ReturnURL", value: returnURL),
            URLQueryItem(name: "vpc_MerchTxnRef", value: merchTxnRef),
            URLQueryItem(name: "vpc_OrderInfo", value: orderInfo),
            URLQueryItem(name: "vpc_Amount", value: amountString),
            URLQueryItem(name: "vpc_TicketNo", value: ticketNo),
            URLQueryItem(name: "Title", value: title),
            URLQueryItem(name: "vpc_Currency", value: currency),
            URLQueryItem(name: "vpc_Theme", value: OpPayment.VPC_THEME)
        ]
        if !againLink.elementsEqual("") {
            queryItems.append(
                URLQueryItem(name: "AgainLink", value: againLink)
            )
            dict["AgainLink"] = againLink
        }
        if let customerPhone = customerPhone {
            queryItems.append(
                URLQueryItem(name: "vpc_Customer_Phone", value: customerPhone)
            )
            dict["vpc_Customer_Phone"] = customerPhone
        }
        if let customerEmail = customerEmail {
            queryItems.append(
                URLQueryItem(name: "vpc_Customer_Email", value: customerEmail)
            )
            dict["vpc_Customer_Email"] = customerEmail
        }
        if let customerId = customerId {
            queryItems.append(
                URLQueryItem(name: "vpc_Customer_Id", value: customerId)
            )
            dict["vpc_Customer_Id"] = customerId
        }
        queryItems.append(
            URLQueryItem(name: "vpc_SecureHash", value: self.secureHashKey(dict: dict, hashKeyCustomer: hashKeyCustomer))
        )
        var urlComps = URLComponents(string: OpPayment.LINK_PAYGATE)!
        urlComps.queryItems = queryItems
        let result = urlComps.url!
        return result
    }
    
    private func secureHashKey(dict:[String:String], hashKeyCustomer: String) -> String {
        var stringDict = ""
        let dictSort = dict.sorted { $0.0 < $1.0 }
        var index = 0
        for (key, value) in dictSort {
            index = index + 1
            if key.starts(with: "vpc_") {
                if index < dictSort.count {
                    stringDict = stringDict + "\(key)=\(value)" + "&"
                }else {
                    stringDict = stringDict + "\(key)=\(value)"
                }
            }
        }
        let hmacData2 = hmac(hashName:"SHA256", message:stringDict.data(using:.utf8)!, key: hashKeyCustomer.hexaData)
        let str = hmacData2!.hexEncodedString(options: .upperCase)
        return str
    }
    
    private func hmac(hashName:String, message:Data, key:Data) -> Data? {
        let algos = ["SHA1":   (kCCHmacAlgSHA1,   CC_SHA1_DIGEST_LENGTH),
                     "MD5":    (kCCHmacAlgMD5,    CC_MD5_DIGEST_LENGTH),
                     "SHA224": (kCCHmacAlgSHA224, CC_SHA224_DIGEST_LENGTH),
                     "SHA256": (kCCHmacAlgSHA256, CC_SHA256_DIGEST_LENGTH),
                     "SHA384": (kCCHmacAlgSHA384, CC_SHA384_DIGEST_LENGTH),
                     "SHA512": (kCCHmacAlgSHA512, CC_SHA512_DIGEST_LENGTH)]
        guard let (hashAlgorithm, length) = algos[hashName]  else { return nil }
        var macData = Data(count: Int(length))
        
        macData.withUnsafeMutableBytes { (macBytes: UnsafeMutableRawBufferPointer) in
            message.withUnsafeBytes { (messageBytes: UnsafeRawBufferPointer) in
                key.withUnsafeBytes {(keyBytes : UnsafeRawBufferPointer) in
                    CCHmac(CCHmacAlgorithm(hashAlgorithm),
                           keyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                           key.count,
                           messageBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                           message.count,
                           macBytes.baseAddress?.assumingMemoryBound(to: UInt8.self))
                }
            }
        }
        return macData
    }
    
    private func getAddress(for network: NetworkOnepayType) -> String? {
        var address: String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == network.rawValue {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}
