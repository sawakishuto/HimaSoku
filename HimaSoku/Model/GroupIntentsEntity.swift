//
//  GroupIntentsEntity.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/13.
//

import Foundation
import AppIntents
import SwiftUICore

struct GroupEntity: AppEntity {
    let id: String
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "グループ"
    static var defaultQuery = GroupQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: name))
    }

    private let name: String

    init(group: Group) {
        self.id = group.id
        self.name = group.name
    }
}

// ステップ2：EntityQueryの作成
struct GroupQuery: EntityQuery {

    private func fetchGroupsFromDataSource() async throws -> [Group] {
        let user = KeychainManager.shared.getUser()
        guard let user = user else {return []}
            
        // APIClient.shared.fetchDataが直接Groupsオブジェクトを返すと仮定
        let groups: Groups = try await APIClient.shared.fetchData(path: "/users/\(user.id)/groups")
        // ここで、APIから返された groups オブジェクトから、
        // 必要なグループの配列を返します。
        // もしGroups構造体内に groups プロパティがあるなら、これだけでOKです。
        return groups.groups
    }

    func entities(for identifiers: [String]) async throws -> [GroupEntity] {
        let allGroups = try await fetchGroupsFromDataSource()
        let filteredGroups = allGroups.filter { identifiers.contains($0.id) }
        return filteredGroups.map { GroupEntity(group: $0) }
    }

    func suggestedEntities() async throws -> [GroupEntity] {
        let allGroups = try await fetchGroupsFromDataSource()
        return allGroups.map { GroupEntity(group: $0) }
    }
}
