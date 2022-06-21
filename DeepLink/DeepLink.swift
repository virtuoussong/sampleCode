//
//  DeepLink.swift
//  MarketKurly
//
//  Created by Minha Seong on 2017. 5. 2..
//  Copyright © 2017년 TheFarmers, Inc. All rights reserved.
//

import UIKit

struct DeepLink {
  var kind: Kind = .unknown
  var path: Path?                         // components.path
  var identifier: String?
  var components: URLComponents?
  var options: Set<HandlingOption> = []

  init(kind: Kind, path: Path? = nil, identifier: String? = nil, components: URLComponents? = nil, options: Set<HandlingOption> = []) {
    self.kind = kind
    self.path = path
    self.identifier = identifier
    self.components = components
    self.options = options

    modifyHandlingOptionsForFragment()
    modifyURL()
    modifyHandlingOptionsForCustomScheme()
  }

  init?(_ url: URL?, options: Set<HandlingOption> = []) {
    guard let unwrappedURL = url, var deepLink = deepLink(from: unwrappedURL) else {
      return nil
    }

    deepLink.options.formUnion(options)

    self = deepLink
  }
}

// MARK: - Public

// MARK: - Private

private extension DeepLink {
  /**
   딥링크 종류와 파라미터에 따라서 URL 을 설정

   커스텀 스킴으로 시작하는 URL 을 이용하여 특정 웹 페이지로 이동하는 딥링크를 생성한 경우, 해당 웹 페이지의 URL 을 생성하고 이를 components 에 할당
   그 외의 경우, 화면 전환 시 필요한 값을 파싱
   */
  mutating func modifyURL() {
    switch kind {
    case .myKurly:
      switch path {
      case .inquiry?:
        components = WebPage.oneToOneInquiryContent(identifier.emptyIfBlank).components
      case .coupon?:
        components = Godo.coupon(components?.encodedQueryItems?[name: .code]).components
      case .bulkOrder?:
        components = Godo.bulkOrderInquiry.components
      default:
        break
      }
    case .product:
      switch path {
      case .review?:
        if let identifier = identifier, let productIdentifier = components?.queryItems?[name: .identifier(.product)] {
          components = Godo.productReviewContent(productIdentifier, identifier, .product, .normal).components
        }
      case .inquiry?:
        if let info = parseProductInquiryInfo(with: components) {
          components = WebPage.productInquiryContent(info.productIdentifier, info.identifier, .normal).components
        }
      default:
        break
      }
    case .order where !identifier.isBlank:
      var temporaryComponents = Godo.orderSheet(identifier).components
      temporaryComponents?.appendQueryItem(name: .referrer, value: components?.queryItems?[name: .referrer])

      components = temporaryComponents
    case .recipe where !identifier.isBlank:
      components = Godo.recipe(identifier!).components
    case .aboutKurly where components == nil:
      components = Godo.aboutKurly.components
    default:
      break
    }
  }

  /// URL 에 따라서 딥링크 처리 방식을 설정
  mutating func modifyHandlingOptionsForCustomScheme() {
    guard let url = components?.url else {
      return
    }

    if url.hasCustomScheme {
      options.insert(.openInSafari)
    }
  }

  mutating func modifyHandlingOptionsForFragment() {
    guard let url = components?.url else {
      return
    }
    if url.hasFragmentForModal {
      options.insert(.presentModally)
    }
  }
}

// MARK: - Equatable

extension DeepLink: Equatable {
  static func == (lhs: DeepLink, rhs: DeepLink) -> Bool {
    return lhs.kind == rhs.kind && lhs.path == rhs.path && lhs.identifier == rhs.identifier && lhs.components == rhs.components
  }
}
