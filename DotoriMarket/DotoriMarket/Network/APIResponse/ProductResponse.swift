//
//  ProductResponse.swift
//  DotoriMarket
//
//  Created by 1 on 2022/07/05.
//

import Foundation

struct ProductResponse: Codable {
    let id: Int
    let vendorID: Int
    let name: String
    let thumbnail: String
    let currency: Currency
    let price: Double
    let bargainPrice: Double
    let discountedPrice: Double
    let stock: Int
    let createdAt: Date
    let issuedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        
        case vendorID = "vendor_id"
        case bargainPrice = "bargain_price"
        case discountedPrice = "discounted_price"
        case createdAt = "created_at"
        case issuedAt = "issued_at"
        case id, name, thumbnail, currency, price, stock
    }
}

extension ProductResponse {
    
    func toDomain() -> Product {
        return Product(id: self.id,
                       vendorID: self.vendorID,
                       name: self.name,
                       thumbnail: self.thumbnail,
                       currency: self.currency,
                       price: self.price,
                       bargainPrice: self.bargainPrice,
                       discountedPrice: self.discountedPrice,
                       stock: self.stock)
    }
}
