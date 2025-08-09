//
//  UserModel.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
}
