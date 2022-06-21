//
//  TabPageViewControllerDelegate+AmplitudeEvent.swift
//  MarketKurly
//
//  Created by Minha Seong on 06/11/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension TabPageViewControllerDelegate where Self: UIViewController {
  func eventNameOfSelectSubtab(with viewController: UIViewController?) -> AmplitudeEvent.Name? {
    guard let viewController = viewController else {
      return nil
    }

    return eventNameOfSelectSubtab(with: type(of: viewController))
  }

  func eventNameOfSelectSubtab(with viewControllerType: UIViewController.Type?) -> AmplitudeEvent.Name? {
    guard let viewControllerType = viewControllerType else {
      return nil
    }

    typealias ViewControllerTypeAndEventName = (viewControllerType: UIViewController.Type, eventName: AmplitudeEvent.Name)

    let list: [ViewControllerTypeAndEventName] = [
      (RecommendationViewController.self, .selectRecommendationSubtab),
      (NewProductViewController.self, .selectNewProductSubtab),
      (PopularProductViewController.self, .selectPopularProductSubtab),
      (BargainSaleViewController.self, .selectBargainSubtab),
      (EventListViewController.self, .selectEventListSubtab),
      (ProductDescriptionViewController.self, .selectProductDetailDescriptionSubtab),
      (ProductImageViewController.self, .selectProductDetailImageSubtab),
      (ProductDetailViewController.self, .selectProductDetailInfoSubtab),
      (ProductReviewViewLimitedAndInfiniteScrollController.self, .selectProductDetailReviewSubtab),
      (ProductInquiryListWebViewController.self, .selectProductDetailInquirySubtab),
    ]

    return list.first(where: { $0.viewControllerType == viewControllerType })?.eventName
  }
}
