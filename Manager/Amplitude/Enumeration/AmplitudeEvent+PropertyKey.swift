//
//  AmplitudeEvent+PropertyKey.swift
//  MarketKurly
//
//  Created by Minha Seong on 21/10/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension AmplitudeEvent.Property {
  enum Key: String, CaseIterable {
    case adid
    case browseEventInfo
    case browseEventName
    case browseID
    case browseScreenName
    case browseTabName
    case browseSubEventInfo
    case browseSubEventName
    case browseSectionId
    case buildNumber
    case couponName
    case couponId
    case couponDiscountAmount
    case deliveryType
    case deliveryCharge
    case isReleaseBuild             // BUILD_CONFIGURATION 이 Release 인 경우에만 true 로 설정
    case isDirectPurchase           // 바로 구매 여부
    case isFirstPurchase
    case isSoldOut
    case keyword                    // 검색어
    case message
    case originPrice
    case packageID                  // P0 (상품, 패키지 상품)
    case packageName
    case screenName
    case position
    case previousScreenName
    case price
    case primaryCategoryID
    case primaryCategoryName
    case productID                  // P1 (패키지 옵션 상품)
    case productName
    case productDiscountAmount
    case pointDiscountAmount
    case packingType
    case purchaseProducts
    case purchaseTag
    case paymentMethod
    case quantity
    case referrerEvent
    case referrerPackageID
    case secondaryCategoryID
    case secondaryCategoryName
    case selectionType
    case signUpSourceScreenName
    case skuCount                   // 상품 종류 개수
    case title
    case totalOriginPrice
    case totalPrice
    case transactionID
    case url
    case isSorting
    case sortType
    case serverSortType
    case defaultSortType
    case selectionSortType
    case bannerCategoryID
    case hasDetailedAddress
    case downloadTime
    case deviceID
    case cause
    case detailedCause
    case jwt
    case isDefaultShippingAddress
    case packageCount
    case fusionQueryId
    case selectionValue
    case isChecked
    case notificationSetting
    case isGiftPurchase
    case giftType
    case sticker
    case contentTitle
    case themePosition
    case sectionId
    case templateCode
    case templateType
    case collectionId
  }
}

// MARK: - RawRepresentable

extension AmplitudeEvent.Property.Key {
  typealias RawValue = String

  var rawValue: String {
    switch self {
    case .browseID, .packageID, .productID, .primaryCategoryID, .secondaryCategoryID, .transactionID, .bannerCategoryID, .deviceID, .referrerPackageID:
      return String(describing: self).snakeCased().replacingOccurrences(of: "_i_d", with: "_id")
    case .isSoldOut:
      return "is_soldout"
    default:
      return String(describing: self).snakeCased()
    }
  }

  init?(rawValue: String) {
    guard let name = type(of: self).allCases.first(where: { $0.rawValue == rawValue }) else {
      return nil
    }

    self = name
  }
}
