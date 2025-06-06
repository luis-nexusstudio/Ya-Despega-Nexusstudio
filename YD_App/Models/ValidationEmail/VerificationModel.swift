//
//  VerificationModel.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//


// MARK: - Response Models
struct VerificationStatusResponse: Codable {
    let success: Bool
    let data: VerificationData?
    let error: String?
}

struct VerificationData: Codable {
    let verified: Bool
    let authVerified: Bool?
    let firestoreStatus: String?
    let message: String
    let canPurchase: Bool
    
    enum CodingKeys: String, CodingKey {
        case verified
        case authVerified = "auth_verified"
        case firestoreStatus = "firestore_status"
        case message
        case canPurchase = "can_purchase"
    }
}

struct CanPurchaseResponse: Codable {
    let success: Bool
    let canPurchase: Bool
    let verified: Bool
    let message: String
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case canPurchase = "can_purchase"
        case verified
        case message
        case error
    }
}

struct ResendEmailResponse {
    let success: Bool
    let message: String
    let alreadyVerified: Bool
    let sentTo: String?
    let error: String?
}
