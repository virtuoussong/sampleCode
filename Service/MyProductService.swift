//  
//  MyProductService.swift
//  MarketKurly
//  
//  Created by Taejun Kim on 2021/03/02.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//  

import Alamofire

protocol MyProductService {
  func loadMyProductInquiryList(
    pageIndex: Int,
    _ completion: @escaping (Result<MyProductInquiryList, RequestError>) -> Void
  )
}

final class MyProductServiceImpl: MyProductService {

  // MARK: Properties
  private let requestManager: RequestManager

  // MARK: Initializer
  init(
    requestManager: RequestManager
  ) {
    self.requestManager = requestManager
  }

  // MARK: `MyProductService` implementation
  func loadMyProductInquiryList(
    pageIndex: Int,
    _ completion: @escaping (Result<MyProductInquiryList, RequestError>) -> Void
  ) {
    let parameters: Parameters = ["page_no": pageIndex]
    self.requestManager.manager
      .request(RequestManager.Router.myProductInquiries(parameters))
      .validate()
      .responseJSON { response in
        let result = response
          .mapResult { MyProductInquiryList(json: $0) }
        completion(result)
      }
  }
}
