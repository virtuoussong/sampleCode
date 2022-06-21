//
//  AmplitudeEventPropertyProtocol.swift
//  MarketKurly
//
//  Created by Minha Seong on 16/10/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

protocol AmplitudeEventPropertyProtocol {
}

extension AmplitudeEventPropertyProtocol {
  func eventProperties(
    with type: AmplitudeEvent.Property.Value.SelectionType? = nil,
    at index: Int? = nil
  ) -> AmplitudeEventProperties? {
    var properties: AmplitudeEventProperties = [
      .selectionType: type?.rawValue,
      .position: index.increased(),
      .isSorting: false
    ]

    switch self {
    case let product as ProductProtocol:
      properties.updateValue(product.parentIdentifier ?? product.identifier, forKey: .packageID)
      if product.parentIdentifier != nil {
        properties.updateValue(product.identifier, forKey: .productID)
      }
      properties.updateValue(product.parentName ?? product.name, forKey: .packageName)
      if product.parentName != nil {
        properties.updateValue(product.name, forKey: .productName)
      }
      if let packingType = product.packingType {
        properties.updateValue(packingType.rawValue, forKey: .packingType)
      }
      properties.updateValue(product.originalPrice, forKey: .originPrice)
      properties.updateValue(product.price, forKey: .price)
      properties.updateValue(product.isSoldOut, forKey: .isSoldOut)
      properties.updateValue(product.quantity, forKey: .quantity)
    case let product as PickedProductListCellBindable:
      let isSoldOut = product.status == .soldOut
      properties.updateValue(isSoldOut, forKey: .isSoldOut)
      properties.updateValue(product.originalPrice, forKey: .originPrice)
      properties.updateValue(product.discountedPrice, forKey: .price)
      properties.updateValue(product.name, forKey: .packageName)
      properties.updateValue(product.number, forKey: .packageID)
    case let banner as BannerProtocol:
      properties.updateValue(banner.deepLink?.components?.url?.absoluteString, forKey: .url)

      if banner.deepLink?.kind == .product {
        properties.updateValue(banner.deepLink?.identifier, forKey: .packageID)
      }
    case let object as SearchProtocol:
      properties.updateValue(object.keyword, forKey: .keyword)
      properties.updateValue(object.parentIdentifier ?? object.identifier, forKey: .packageID)
    case let category as Category:
      if let parentIdentifier = category.parentIdentifier, let parentName = category.parentName {
        properties.updateValue(parentIdentifier, forKey: .primaryCategoryID)
        properties.updateValue(parentName, forKey: .primaryCategoryName)
        properties.updateValue(category.identifier, forKey: .secondaryCategoryID)
        properties.updateValue(category.name, forKey: .secondaryCategoryName)
      } else {
        properties.updateValue(category.identifier, forKey: .primaryCategoryID)
        properties.updateValue(category.name, forKey: .primaryCategoryName)
        properties.updateValue(nil, forKey: .secondaryCategoryID)
        properties.updateValue(nil, forKey: .secondaryCategoryName)
      }
    case let suggestionProudct as SearchSuggestionProduct:
      properties.updateValue(suggestionProudct.name, forKey: .packageName)
      properties.updateValue(suggestionProudct.no, forKey: .packageID)
    default:
      return nil
    }

    return properties
  }
}
