//
//  UrlInfo.swift
//  SafeQR
//
//  Created by Abylaykhan Myrzakhanov on 12.04.2024.
//

import Foundation

struct UrlInfo: Decodable {
    let domain: String
    let ip_address: String
    let countryCode: String
    let city: String
}
