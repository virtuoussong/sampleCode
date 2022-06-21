//
//  ProductCollectionService.swift
//  MarketKurly
//
//  Created by MK-Mac-255 on 2021/11/14.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import RxSwift

protocol ProductCollectionService: AnyObject {
  func loadCollectionInfo(code: String) -> Single<ProductCollectionInfoModel>
  func loadCollectionProducts(
    code: String,
    sort: String,
    page: Int
  ) -> Single<ProductCollectionProductsModel>
}

final class ProductCollectionServiceImpl: ProductCollectionService {

  // MARK: Properties
  private let provider: ProductCollectionProvider

  // MARK: Initializer
  init(provider: ProductCollectionProvider) {
    self.provider = provider
  }

  // MARK: `ProductCollectionService` implementaion
  func loadCollectionInfo(code: String) -> Single<ProductCollectionInfoModel> {
    return self.provider.rx.request(.getCollectionInfo(code: code))
      .map(ProductCollectionInfoModel.self)
  }

  func loadCollectionProducts(
    code: String,
    sort: String,
    page: Int
  ) -> Single<ProductCollectionProductsModel> {
    return self.provider.rx.request(
      .getCollectionProducts(
        code: code,
        sortType: sort,
        page: page
      ))
      .mapResponse(ProductCollectionProductsModel.self)
  }
}
