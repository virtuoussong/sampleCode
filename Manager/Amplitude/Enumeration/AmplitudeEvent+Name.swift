//
//  AmplitudeEvent+Name.swift
//  MarketKurly
//
//  Created by Minha Seong on 11/10/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension AmplitudeEvent {
  enum Name: OptionalRawRepresentable, CaseIterable {
    case plain(String?)
    // App
    case openApp
    case loginSuccess
    case loginFail
    case selectFindId
    case selectFindPassword
    case selectHomeTab
    case selectCategoryTab
    case selectSearchTab
    case selectMyKurlyTab
    case selectRecommendationSubtab
    case selectNewProductSubtab
    case selectPopularProductSubtab
    case selectBargainSubtab
    case selectEventListSubtab
    case selectFrequentlyPurchaseProductList

    // MARK: Category
    case selectPrimaryCategory
    case selectCategory
    case selectCategorySubtab
    case selectCategoryBanner
    case selectGiftList

    case selectSearch
    case selectProductBanner
    case selectRecommendation(RecommendationSectionInfo?)
    case impressionRecommendation(RecommendationSectionInfo?)
    case selectEventListBanner
    case selectProduct
    case selectProductShortcut
    case selectRelatedProduct
    case selectRelatedProductShortcut
    case selectPopupProduct
    case selectPopupProductShortcut
    case viewProductDetail
    case selectPurchase
    case viewProductSelection
    case selectProductDetailDescriptionSubtab
    case selectProductDetailImageSubtab
    case selectProductDetailInfoSubtab
    case selectProductDetailReviewSubtab
    case selectProductDetailInquirySubtab
    case selectCart
    case addToCartProduct
    case addToCartSuccess
    case addToCartFail
    case removeCartProductSuccess
    case purchaseProduct
    case selectFriendInvitationButton
    case shareProduct
    case selectSortType
    case selectShippingAddressList
    case selectCurrentShippingAddress
    case selectAddAddressShippingButton
    case selectEditAddressShippingButton
    case submitAddAddressShippingSuccess
    case submitEditAddressShippingSuccess
    case viewShippingAddressList
    case selectTopShippingAddressButton
    case selectTopButton
    case selectPickProduct
    case removePickProduct
    case selectGiftKakaoButton
    case selectMessageResendButton
    // Web (BehaviorEvent)
    case viewSignUp
    case signUpSuccess
    case viewReviewDetail
    case viewEventDetail
    case orderCreationSuccess
    case orderCreationFail
    case checkoutSuccess
    case checkoutFail
    case purchaseSuccess
    case purchaseFail
    case shareEvent
    case viewShippingAddressSearch
    case selectDirectPurchaseShippingAddress
    // Debug
    case logout

    // MARK: - Push Notification
    case selectPushNotificationPopupButton
    case selectMarketingInformationArgeement
    case selectMarketingInformationAgreementAgain
    case selectMyKurlyNotificationSetting
    case selectNotificationSettingToggle
    case selectMarketingInformationAgreeAlert
    case selectSystemNotificationOffAlert

    // MARK: - My Kurly
    case selectMyKurlyReviewHistory
    case selectMyKurlyProductInquiryHistory
    case selectMyKurlyPersonalInquiryHistory
    case selectMyKurlyBulkOrder
    case selectMyKurlyFrequentlyQna
    case selectMyKurlyPersonalInquiryKakaoButton
    case selectMyKurlyPersonalInquiryOnebyoneButton
    case selectMyKurlyPurpleBox
    case selectMyKurlyPickList
    case selectMyKurlyMembershipGuide
    case selectMyKurlyMembershipBenefit
    case selectMyKurlyPointHistory
    case selectMyKurlyCouponList
    case selectMyKurlyGiftList
    case selectMyKurlyBanner

    // MARK: - Logo tap
    case selectMainLogo

    // MARK: - Search
    case fusionQueryId

    // MARK: - 1:1 Inquiry
    case selectMyKurlyServiceCenter
    case selectMyKurlyAddPersonalInquiry
    case selectPersonalInquiryCaseList
    case selectPersonalInquiryCaseValue
    case selectPersonalInquiryOrderList
    case selectPersonalInquiryOrderNumber
    case selectPersonalInquiryTitle
    case selectPersonalInquiryText
    case submitPersonalInquirySuccess

    // MARK: - Home
    case selectFloatingButton
    case selectSectionCategorySubtab

    // MARK: - Kurly Recipe
    case selectKurlyRecipeSearch
    case selectKurlyRecipe
  }
}

// MARK: - Private

private extension AmplitudeEvent.Name {
  /**
   연관 값 (Associated Values) 이 있는 항목만 정의하며, rawValue 생성 시 사용
   */
  var prefix: String? {
    switch self {
    case .selectRecommendation:
      return "selectRecommendation"
    case .impressionRecommendation:
      return "impressionRecommendation"
    default:
      return nil
    }
  }
}

private extension String {
  /**
   init?(rawValue:) 의 rawValue 에서 sectionID 를 추출하여 RecommendationSectionInfo 를 생성
   */
  func sectionInfo(with name: AmplitudeEvent.Name) -> RecommendationSectionInfo? {
    var sectionID = self                                                                        // .selectRecommendation("test")
    if let range = self.range(of: name.rawValue) {
      sectionID.removeSubrange(range)                                                         // select_recommendation_test --> _test
      sectionID.removeFirst()                                                                 // _test --> test
    }

    guard !sectionID.isEmpty else {
      return nil
    }

    return RecommendationSectionInfo(identifier: sectionID)
  }
}

// MARK: - RawRepresentable

extension AmplitudeEvent.Name {
  typealias RawValue = String

  var rawValue: String? {
    switch self {
    case .plain(let name):
      guard let name = name else {
        return nil
      }

      return name
    case .selectRecommendation(let sectionInfo),
         .impressionRecommendation(let sectionInfo):
      guard let prefix = prefix, let sectionIdentifier = sectionInfo?.identifier else {
        return nil
      }
      guard !sectionIdentifier.isEmpty else {
        return prefix.snakeCased()
      }

      return (prefix + "_" + sectionIdentifier).snakeCased()
    default:
      return String(describing: self).snakeCased()
    }
  }

  init?(rawValue: String?) {
    guard let rawValue = rawValue, !rawValue.isEmpty else {
      return nil
    }

    let names = type(of: self).allCases
    if let name = names.first(where: { rawValue == $0.rawValue }) {
      switch name {
      case .selectRecommendation, .impressionRecommendation:
        return nil
      default:
        self = name
      }
    } else if let name = names.first(where: { rawValue.contains($0.rawValue) }) {
      switch name {
      case .selectRecommendation:
        self = type(of: self).selectRecommendation(rawValue.sectionInfo(with: name))
      case .impressionRecommendation:
        self = type(of: self).impressionRecommendation(rawValue.sectionInfo(with: name))
      default:
        self = type(of: self).plain(rawValue)
      }
    } else {
      self = type(of: self).plain(rawValue)
    }
  }
}

// MARK: - CaseIterable

extension AmplitudeEvent.Name {
  typealias AllCases = [AmplitudeEvent.Name]

  static var allCases: [AmplitudeEvent.Name] {
    return [
      .openApp,
      .loginSuccess,
      .loginFail,
      .selectHomeTab,
      .selectCategoryTab,
      .selectSearchTab,
      .selectMyKurlyTab,
      .selectRecommendationSubtab,
      .selectNewProductSubtab,
      .selectPopularProductSubtab,
      .selectBargainSubtab,
      .selectEventListSubtab,
      .selectFrequentlyPurchaseProductList,
      .selectCategory,
      .selectCategorySubtab,
      .selectCategoryBanner,
      .selectSearch,
      .selectRecommendation(RecommendationSectionInfo()),
      .impressionRecommendation(RecommendationSectionInfo()),
      .selectEventListBanner,
      .selectProduct,
      .selectProductShortcut,
      .viewProductDetail,
      .selectPurchase,
      .viewProductSelection,
      .selectProductDetailDescriptionSubtab,
      .selectProductDetailImageSubtab,
      .selectProductDetailInfoSubtab,
      .selectProductDetailReviewSubtab,
      .selectProductDetailInquirySubtab,
      .selectCart,
      .addToCartProduct,
      .addToCartSuccess,
      .addToCartFail,
      .removeCartProductSuccess,
      .purchaseProduct,
      .selectFriendInvitationButton,
      .shareProduct,
      .selectSortType,
      .selectShippingAddressList,
      .selectCurrentShippingAddress,
      .selectAddAddressShippingButton,
      .selectEditAddressShippingButton,
      .submitAddAddressShippingSuccess,
      .submitEditAddressShippingSuccess,
      .viewShippingAddressList,
      .selectTopShippingAddressButton,
      .selectTopButton,
      .viewSignUp,
      .signUpSuccess,
      .viewReviewDetail,
      .viewEventDetail,
      .orderCreationSuccess,
      .orderCreationFail,
      .checkoutSuccess,
      .checkoutFail,
      .purchaseSuccess,
      .purchaseFail,
      .shareEvent,
      .viewShippingAddressSearch,
      .selectDirectPurchaseShippingAddress,
      .logout,
      .selectMyKurlyReviewHistory,
      .selectMyKurlyProductInquiryHistory,
      .selectMyKurlyPersonalInquiryHistory,
      .selectMyKurlyBulkOrder,
      .selectMyKurlyFrequentlyQna,
      .selectMyKurlyPersonalInquiryKakaoButton,
      .selectMyKurlyPersonalInquiryOnebyoneButton,
      .selectMainLogo,
      .selectMyKurlyPickList,
      .selectPickProduct,
      .removePickProduct,
      .selectPushNotificationPopupButton,
      .selectMarketingInformationArgeement,
      .selectMarketingInformationAgreementAgain,
      .selectMyKurlyNotificationSetting,
      .selectNotificationSettingToggle,
      .selectMarketingInformationAgreeAlert,
      .selectSystemNotificationOffAlert,
      .selectMyKurlyServiceCenter,
      .selectMyKurlyAddPersonalInquiry,
      .selectPersonalInquiryCaseList,
      .selectPersonalInquiryCaseValue,
      .selectPersonalInquiryOrderList,
      .selectPersonalInquiryOrderNumber,
      .selectPersonalInquiryTitle,
      .selectPersonalInquiryText,
      .submitPersonalInquirySuccess,
      .selectGiftList,
      .selectMyKurlyGiftList,
      .selectFloatingButton,
      .selectSectionCategorySubtab,
      .selectKurlyRecipe,
      .selectMyKurlyBanner
    ]
  }
}
