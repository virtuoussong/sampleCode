//
//  OrderedListModel.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/07.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import RxDataSources

struct OneToOneInquiryOrderSection {
  let selectionType: OneToOneInquiryOrderType
  var isExpanded = false
  var selectionState: CheckMarkState = .unchecked
  let orderNo: Int
  let orderedDate: String
  let totalProductCount: Int
  var isAllProductsShown = false
  var items: [OneToOneInquiryProduct]
}

extension OneToOneInquiryOrderSection: SectionModelType {
  typealias Item = OneToOneInquiryProduct

  init(
    original: OneToOneInquiryOrderSection,
    items: [OneToOneInquiryProduct]
  ) {
    self = original
    self.items = items
  }
}

struct OneToOneInquiryOrderHistory: Decodable {
  let content: [NewOneToOneInquiryOrder]
  let totalPages: Int?
  let totalElements: Int?
  let number: Int?
  let numberOfElements: Int?
}

struct NewOneToOneInquiryOrder: Decodable {
  let orderNo: Int
  var products: [OneToOneInquiryProduct]
  var isExpanded = false
  var selectionState: CheckMarkState = .unchecked
  var orderedDate: String {
    if let dateString = self.products.first?.orderedDatetime,
       let dateFormatted = Date(dateString)?.format() {
      return dateFormatted
    }
    return ""
  }

  var totalProductCount: Int {
    return  self.products.count
  }

  private enum CodingKeys: String, CodingKey {
    case orderNo
    case products
  }
}
