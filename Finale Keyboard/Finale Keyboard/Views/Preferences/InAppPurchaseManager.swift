//
//  InAppPurchasesManager.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/10/26.
//

import Foundation
import SwiftUI
import StoreKit

@MainActor
class InAppPurchasesManager: ObservableObject {
    private let spacebarProductID = "spacebar"
    private let spacebarGambleProductID = "spacebar_gamble"
    
    @Published var spacebarProduct: Product?
    @UserDefault("FINALE_DEV_APP_isSpacebarUnlocked", false) var isSpacebarUnlocked
    
    @Published var spacebarGambleProduct: Product?
    
    init() {
        Task {
            await LoadProducts()
            await ListenForTransaction()
        }
    }
    
    func LoadProducts() async {
        if let products = try? await Product.products(for: [spacebarProductID, spacebarGambleProductID]) {
            spacebarProduct = products.first(where: { $0.id == spacebarProductID })
            spacebarGambleProduct = products.first(where: { $0.id == spacebarGambleProductID })
        }
    }
    
    func PurchaseSpacebar(onSuccess: @escaping () -> Void) async {
        guard let spacebarProduct else { return }
        
        if case .success(let result) = try? await spacebarProduct.purchase(), case .verified(let transaction) = result {
            await transaction.finish()
            await UpdatePurchaseStatus()
            onSuccess()
        }
    }
    
    func PurchaseSpacebarGamble(onSuccess: @escaping () -> Void) async  {
        guard let spacebarGambleProduct else { return }
        
        if case .success(let result) = try? await spacebarGambleProduct.purchase(), case .verified(let transaction) = result {
            await transaction.finish()
            onSuccess()
        }
    }
    
    func UpdatePurchaseStatus() async {
        if let result = await Transaction.latest(for: spacebarProductID), case .verified(let transaction) = result {
            isSpacebarUnlocked = transaction.revocationDate == nil
        } else {
            isSpacebarUnlocked = false
        }
    }
    
    func ListenForTransaction() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update,
                transaction.productID == spacebarProductID {
                await transaction.finish()
                await UpdatePurchaseStatus()
            }
        }
    }
    
}
