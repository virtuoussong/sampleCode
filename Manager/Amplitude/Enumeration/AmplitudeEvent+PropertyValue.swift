//
//  AmplitudeEvent+PropertyValue.swift
//  MarketKurly
//
//  Created by Minha Seong on 21/10/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension AmplitudeEvent.Property {
  enum Value {
  }
}

extension AmplitudeEvent.Property.Value {
  enum TabName: String, CaseIterable {
    case home
    case category
    case search
    case myKurly

    init?(identifier: MainTabIdentifier?) {
      guard let identifier = identifier else { return nil }
      switch identifier {
      case .home:
        self = .home
      case .category:
        self = .category
      case .search:
        self = .search
      case .myKurly:
        self = .myKurly
      }
    }
  }

  enum ScreenName: String, CaseIterable {
    case recommendation
    case newProduct
    case popularProduct
    case bargain
    case eventList
    case recipeList
    case recipeDetail
    case announce
    case starred
    case category
    case categoryProductList
    case search
    case searchProductList
    case myKurly
    case notificationSetting
    case guestOrderSearch
    case orderHistory
    case frequentlyPurchaseProductHistory
    case myReviewableList
    case myReviewHistory
    case myProductInquiryHistory
    case personalInquiryHistory
    case personalInquiryWriting
    case personalInquiryWritingNotice
    case personalInquiryWritingInquiryTypeSelection
    case personalInquiryWritingOrderHistorySelection
    case kurlyPassGuide
    case productList
    case productDetailDescription
    case productDetailImage
    case productDetailInfo
    case productDetailReview
    case productDetailInquiry
    case share
    case productReviewList
    case productReviewWriting
    case productInquiryList
    case productInquiryWriting
    case productInquiryWritingNotice
    case productSelection
    case cart
    case splash
    case signUp
    case login
    case shippingAddressList
    case simpleShippingAddressList
    case pickList
    case giftList
    case giftHistory
    case orderSheet
    case paymentSuccess
    case giftOrderDetail
  }

  enum SelectionType: String, CaseIterable {
    case content
    case title
    case more
    case popular                // 인기 검색어
    case recent                 // 최근 검색어
    case suggestionProduct      // 상품 바로 가기
    case keyword                // 직접 검색
    // 추천검색어
    case recommendation
    // 급상승 검색어
    case rising
    // 이벤트 검색어
    case event
    //removeCartProductSuccess
    //선택 삭제 버튼
    case selection
    //상품별 삭제 버튼
    case product
    //품절상품 삭제 버튼
    case soldout
    case shortcut
  }

  enum LogoutCauseType: String, CaseIterable {
    case logout = "로그아웃 클릭"
    case changePassword = "비밀번호 변경"
    case etc = "기타"
  }
}

// MARK: - RawRepresentable

extension AmplitudeEvent.Property.Value.TabName {
  typealias RawValue = String

  var rawValue: String {
    return String(describing: self).snakeCased()
  }

  init?(rawValue: String) {
    guard let name = type(of: self).allCases.first(where: { $0.rawValue == rawValue }) else {
      return nil
    }

    self = name
  }
}

extension AmplitudeEvent.Property.Value.ScreenName {
  typealias RawValue = String

  var rawValue: String {
    return String(describing: self).snakeCased()
  }

  init?(rawValue: String) {
    guard let name = type(of: self).allCases.first(where: { $0.rawValue == rawValue }) else {
      return nil
    }

    self = name
  }
}

extension AmplitudeEvent.Property.Value.SelectionType {
  typealias RawValue = String

  var rawValue: String {
    return String(describing: self).snakeCased()
  }

  init?(rawValue: String) {
    guard let name = type(of: self).allCases.first(where: { $0.rawValue == rawValue }) else {
      return nil
    }

    self = name
  }
}
