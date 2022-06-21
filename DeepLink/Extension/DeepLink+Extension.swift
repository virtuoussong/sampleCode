//
//  DeepLink+Extension.swift
//  MarketKurly
//
//  Created by Minha Seong on 2017. 5. 4..
//  Copyright © 2017년 TheFarmers, Inc. All rights reserved.
//

import UIKit

// MARK: - Public

extension DeepLink {
  var navigationItemTitle: String? {
    // 별도로 설정된 내비게이션 타이틀이 있는 경우, 우선 적용
    if let title = options.navigationItemTitle {
      return title
    }

    switch kind {
    case .myKurly:
      switch path {
      case .inquiry?:
        return R.string.localizable.oneToOneInquiryContentNavi()
      case .coupon?:
        return R.string.localizable.myKurlyCouponNavi()
      case .bulkOrder:
        return R.string.localizable.myKurlyBulkOrderInquiryNavi()
      default:
        return nil
      }
    case .event:
      return R.string.localizable.eventNavi()
    case .open:
      // TODO: .orderSheet 인 경우, orderno 에 대한 처리
      let links: [Linkable] = [Godo.terms, Godo.privacy, Godo.orderSheet(nil), Godo.orderCancellation(nil), Godo.coupon(nil), Godo.deliveryGuide, Godo.notice, Godo.noticeContent(nil), Godo.faq]

      return links.first(where: { components.contains($0) })?.navigationItemTitle
    case .product:
      switch path {
      case .review?:
        return R.string.localizable.productReviewContentNavi()
      case .inquiry?:
        return R.string.localizable.productInquiryContentNavi()
      default:
        return nil
      }
    case .order:
      return R.string.localizable.myKurlyOrderSheetNavi()
    case .aboutKurly:
      return R.string.localizable.myKurlyAboutKurlyNavi()
    case .recipe:
      return R.string.localizable.recipeNavi()
    case .signup:
      return R.string.localizable.myKurlySignupNavi()
    default:
      return nil
    }
  }
}

extension DeepLink {
  func isPublic() -> DeepLink? {
    var isPublic = false
    switch kind {
    case .home, .search, .myKurly, .event, .open, .cart, .category, .collection, .order, .compose, .login, .notice, .frequentlyProducts:
      isPublic = true
    case .product where path == nil: // 상품 문의 상세, 상품 후기 상세 딥링크 적용전에는 프라이빗으로 합니다.
      isPublic = true
    default:
      break
    }

    DLog.debug("isPublic: \(isPublic)")

    return isPublic ? self : nil
  }
}
