//
//  DeepLink+Parser.swift
//  MarketKurly
//
//  Created by Minha Seong on 29/07/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

// MARK: - Public

extension DeepLink {
  func deepLink(from url: URL) -> DeepLink? {
    guard let components = url.components else {
      return nil
    }

    return components.scheme == Bundle.main.customURLScheme ? deepLink(fromDeepLink: components) : deepLink(fromWeb: components)
  }

  func parseProductInquiryInfo(with components: URLComponents?) -> (identifier: String, productIdentifier: String)? {
    // 구 kurly://product/inquiry?no=143486&product_no=35537   --> 143486, 35537
    // 신 kurly://product/inquiry?no=35537&content_no=143486&   --> 143486, 35537
    var temporaryIdentifier = identifier
    var temporaryProductIdentifier = components?.queryItems?[name: .identifier(.product)]
    // https://front.kurly.com/products/35537/qna/143486    --> 143486, 35537
    if components?.path.regexMatches("^/products/[0-9]+/qna/[0-9]+$") ?? false {
      temporaryIdentifier = components?.url?.pathComponents[safe: 4]
      temporaryProductIdentifier = components?.url?.pathComponents[safe: 2]
    }

    if let identifier = temporaryIdentifier, let productIdentifier = temporaryProductIdentifier {
      return (identifier, productIdentifier)
    }

    return nil
  }
}

// MARK: - Private

private extension DeepLink {
  func deepLink(fromDeepLink components: URLComponents) -> DeepLink? {
    guard let kind: Kind = components.host?.toEnum() else {
      return nil
    }

    switch kind {
    case .search:
      return DeepLink(kind: kind, components: components)
    case .myKurly:
      switch components.path {
      case Path.inquiry.rawValue:
        return DeepLink(kind: kind, path: .inquiry, identifier: components.queryItems?[name: .number(.default)])
      case Path.coupon.rawValue:
        return DeepLink(kind: kind, path: .coupon, components: components)
      case Path.bulkOrder.rawValue:
        return DeepLink(kind: kind, path: .bulkOrder, components: components)
      case Path.oneToOneInquiry.rawValue:
        return DeepLink(kind: kind, path: .oneToOneInquiry)
      default:
        return DeepLink(kind: kind)
      }
    case .home, .cart, .login, .aboutKurly, .signup, .frequentlyProducts:
      return DeepLink(kind: kind)
    case .category, .recipe:
      return DeepLink(kind: kind, identifier: components.queryItems?[name: .number(.default)])
    case .product:
      switch components.path {
      case Path.review.rawValue:
        return DeepLink(kind: kind, path: .review, identifier: components.queryItems?[name: .identifier(.content)], components: components)
      case Path.inquiry.rawValue:
        return DeepLink(kind: kind, path: .inquiry, identifier: components.queryItems?[name: .identifier(.content)], components: components)
      default:
        return DeepLink(kind: kind, identifier: components.queryItems?[name: .number(.default)])
      }
    case .collection:
      return DeepLink(kind: kind, identifier: components.queryItems?[name: .code], components: components)
    case .gift:
      switch components.path {
      case Path.giftDetail.rawValue:
        return DeepLink(kind: kind, path: .giftDetail, identifier: components.queryItems?[name: .identifier(.order)], components: components)
      default:
        return DeepLink(kind: kind, path: .giftDetail, identifier: components.queryItems?[name: .identifier(.order)], components: components)
      }
    case .order:
      return DeepLink(kind: kind, identifier: components.queryItems?[name: .number(.default)], components: components)
    case .compose:
      switch components.path {
      case Path.review.rawValue:
        return DeepLink(kind: kind, path: .review, identifier: components.queryItems?[name: .number(.default)], components: components)
      case Path.inquiry.rawValue:
        return DeepLink(kind: kind, path: .inquiry, identifier: components.queryItems?[name: .number(.default)], components: components)
      default:
        break
      }
    case .open, .event:
      let url = components.substringURL(from: "url")
      return DeepLink(kind: kind, components: url?.components)
    case .notice:
      return DeepLink(kind: kind, components: components)
    case .growth:
      guard let path: Path = components.path.toEnum() else { return nil }
      switch path {
      case .productDetail:
        return DeepLink(
          kind: .product,
          identifier: components.queryItems?[name: .boardType(.default)],
          components: components
        )
      case .productSelection:
        return DeepLink(
          kind: .productSelection,
          identifier: components.queryItems?[name: .boardType(.default)],
          components: components
        )
      default:
        return nil
      }
    default:
      break
    }

    return nil
  }

  func deepLink(fromWeb components: URLComponents) -> DeepLink? {
    guard components.isKurly else {
      return DeepLink(kind: .open, components: components)
    }

    guard let pathComponents = components.url?.pathComponents, pathComponents.count > 1 else {
      return DeepLink(kind: .home)
    }

    if let lastPath = pathComponents.last, lastPath.hasSuffix(".php") {
      return deepLink(fromGodo: components)
    } else {
      // https://front.kurly.com/ 으로 시작하는 경우, Query String 을 사용하지 않음
      if let info = parseProductInquiryInfo(with: components) {                                                                                           // 상품 문의 상세
        return DeepLink(kind: .product, path: .inquiry, identifier: info.identifier, components: components)
      }
    }

    return nil
  }

  func deepLink(fromGodo components: URLComponents) -> DeepLink? {
    let pathComponents = components.url?.pathComponents

    // https://www.kurly.com/m2/introduce/about_kurly.php --> ["/", "m2", "introduce", "about_kurly.php"]
    if let index = pathComponents?.firstIndex(where: { $0 == "introduce" }), index < 3 {                                                                    // About Kurly
      return DeepLink(kind: .aboutKurly, components: components)
    } else if let lastPath = pathComponents?.last {
      switch lastPath {
      case "html.php":                                                                                                                                    // html.php 로 이어지는 페이지들
        if let value = components.queryItems?[name: .eventPath(.previous)], value.hasPrefixes("event", "proc/event") {                                  // 이벤트 웹 페이지
          return DeepLink(kind: .event, components: components)
        }
      case "kurlyEvent.php":                                                                                                                              // 이벤트 웹 페이지
        if let value = components.queryItems?[name: .eventPath(.previous)], value.hasPrefix("event") {
          return DeepLink(kind: .event, components: components)
        } else if let value = components.queryItems?[name: .eventPath(.current)], value.hasPrefix("event") {
          return DeepLink(kind: .event, components: components)
        }
      case "event.php":                                                                                                                                   // 이벤트 목록
        return DeepLink(kind: .event)
      case "menu_list.php":                                                                                                                               // 마이컬리
        return DeepLink(kind: .myKurly)
      case "couponlist.php":
        return DeepLink(kind: .myKurly, path: .coupon, components: components)
      case "review_view.php":
        return DeepLink(kind: .product, path: .review, identifier: components.queryItems?[name: .number(.reviewContent)], components: components)
      case "orderview.php":                                                                                                                               // 주문 상세 내역
        return DeepLink(kind: .order, identifier: components.queryItems?[name: .number(.order)], components: components)
      case "review_register.php" where components.queryItems?[name: .composeType(.default)] == .compose(.review):                                         // 상품 후기 작성
        return DeepLink(kind: .compose, path: .review, identifier: components.queryItems?[name: .number(.product)], components: components)
      case "qna_register.php" where components.queryItems?[name: .composeType(.default)] == .compose(.oneToOneInquiry):                                   // 1:1 문의
        return DeepLink(kind: .compose, path: .inquiry, identifier: components.queryItems?[name: .number(.oneToOneInquiry)], components: components)
      case "login.php":                                                                                                                                   // 로그인
        return DeepLink(kind: .login)
      case "join.php":                                                                                                                                    // 가입하기
        return DeepLink(kind: .signup)
      case "list_all.php":
        return DeepLink(kind: .collection, identifier: components.queryItems?[name: .collection], components: components)
      default:                                                                                                                                            // view.php 로 이어지는 페이지들
        // no 뒤에 category 가 따라오는 경우가 있으므로, 반드시 no 를 먼저 찾아야 한다.
        if let value = components.queryItems?[name: .number(.product)] {                                                                                // 상품
          return DeepLink(kind: .product, identifier: value, components: components)
        } else if let value = components.queryItems?[name: .number(.category)] {                                                                        // 상품 목록
          return DeepLink(kind: .category, identifier: value, components: components)
        } else if components.queryItems?[name: .boardType(.default)] == .board(.recipe) {                                                               // 레시피
          return DeepLink(kind: .recipe, identifier: components.queryItems?[name: .number(.default)], components: components)
        }
      }
    }

    return DeepLink(kind: .open, components: components)
  }
}
