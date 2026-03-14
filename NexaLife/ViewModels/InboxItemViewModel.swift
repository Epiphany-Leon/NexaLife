//
//  InboxItemViewModel.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//

import Foundation
import Combine

class InboxItemViewModel: ObservableObject {
    @Published var inboxItems: [InboxItem] = []    // 发布者通知更新
    
    // 初始化方法，加载初始数据
    init(initialData: [InboxItem] = []) {
        self.inboxItems = initialData
    }

    func addItem(content: String) {
        let newItem = InboxItem(content: content)
        inboxItems.append(newItem)
    }

    func deleteItem(_ item: InboxItem) {
        if let index = inboxItems.firstIndex(where: { $0.id == item.id }) {
            inboxItems.remove(at: index)
        }
    }
}
