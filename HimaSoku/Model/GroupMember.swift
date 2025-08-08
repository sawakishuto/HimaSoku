//
//  GroupMember.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import Foundation

struct GroupMember: Codable {
    let group: Group
    let users: [User]
}
