//
//  InquiryProductSelectService.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/09/01.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import Alamofire
import RxSwift
import SwiftyJSON

protocol OneToOneInquiryProductService {
  func requestOrders(parameter: OneToOneInquiryOrderRequestParameter) -> Single<OneToOneInquiryOrderHistory>
}

final class OneToOneInquiryProductServiceImpl: OneToOneInquiryProductService {
  // MARK: Proeprties
  private let provider: MemberBoardProvider

  // MARK: Initializer
  init(provider: MemberBoardProvider) {
    self.provider = provider
  }

  func requestOrders(
    parameter: OneToOneInquiryOrderRequestParameter
  ) -> Single<OneToOneInquiryOrderHistory> {
    return self.provider.rx.request(.getOrders(parameters: parameter))
      .map(OneToOneInquiryPayload<OneToOneInquiryOrderHistory>.self)
      .compactMap(\.data)
      .asObservable()
      .asSingle()
      .catch { err in
        .error(err)
      }
  }
}
