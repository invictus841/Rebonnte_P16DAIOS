//
//  User.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 18/10/2025.
//

import Foundation

struct User: Codable, Equatable {
    let uid: String
    let email: String?
    
    init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}
