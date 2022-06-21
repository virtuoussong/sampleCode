//
//  DeepLink+Enumeration.swift
//  MarketKurly
//
//  Created by Minha Seong on 29/07/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension DeepLink {
  enum Kind: String {
    case unknown
    // Public
    case home                               // 홈 탭
    case search                             // 검색 탭
    case myKurly = "mykurly"                // 마이컬리 탭
    case event                              // 이벤트 목록, 이벤트 웹 페이지 URL
    case open                               // WebViewController 를 이용하여 웹 페이지 열기
    case cart                               // 장바구니
    case category                           // 상품 목록
    case product                            // 상품 상세, 상품 후기 상세, 상품 문의 상세
    case productSelection                   // 상품 선택
    case order                              // 주문 내역 상세
    case compose                            // 작성하기
    case login                              // 로그인
    case notice
    case frequentlyProducts = "frequently-products"
    case collection
    // TODO: https://kurly0521.atlassian.net/browse/KMA-764
    case growth
    // Private
    case recipe                             // 레시피 목록, 레시피 상세
    case aboutKurly = "about_kurly"         // About Kurly
    case signup                             // 가입하기
    case gift = "gift"
    case giftList
  }

  enum Path: String {
    case inquiry = "/inquiry"               // 상품 문의 상세, 1:1 문의 상세, 1:1 문의 작성
    case coupon = "/coupon"                 // 쿠폰 목록, 쿠폰 등록
    case review = "/review"                 // 상품 후기 상세, 상품 후기 작성
    case bulkOrder = "/bulk_order"          // 대량주문 문의
    case giftHistory = "/gift_history"
    case giftDetail = "/detail"
    case oneToOneInquiry = "/onetoone_inquiry"
    case productDetail = "/productDetail"
    case productSelection = "/productSelection"
  }

  enum HandlingOption: Hashable {
    case presentModally                     // 모달을 이용하여 화면 전환 (WebViewController 인 경우에만 적용)
    case openInSafari                       // 사파리로 열기 (.open 인 경우에만 적용)
    case navigationItemTitle(String)        // 내비게이션 타이틀을 별도로 설정하는 경우 사용
    case animated(Bool)                     // 화면 전환 시 사용
  }
}
