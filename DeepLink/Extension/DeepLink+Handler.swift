//
//  DeepLink+Handler.swift
//  MarketKurly
//
//  Created by Minha Seong on 29/07/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit
// Library
import MBProgressHUD

// MARK: - Public

extension DeepLink {
  func go() {
    DLog.debug(String(describing: self))

    switch kind {
    case .home:
      handleDeepLinkForHome()
    case .search:
      handleDeepLinkForSearch()
    case .myKurly:
      handleDeepLinkForMyKurly()
    case .cart:
      let viewController = CartViewController()
      let navigationController = CartNavigationController(rootViewController: viewController)
      navigationController.modalPresentationStyle = .fullScreen
      self.present(controller: viewController, navigationController: navigationController)
    case .category:
      if let viewController = UIApplication.shared.visibleViewController() as? ProductListViewController, let subcategory = viewController.findSubcategory(with: identifier) {
        viewController.selectSubcategory(subcategory)
      } else {
        present(by: ProductListViewController.self, with: ProductListNavigationController.self, storyboardIdentifier: .product) {
          $0.category = Category(identifier: self.identifier)
        }
      }
    case .collection:
      self.handleDeepLinkForProductCollection()
    case .product:
      handleDeepLinkForProduct()
    case .productSelection:
      handleDeepLinkForProductSelection()
    case .open where options.contains(.openInSafari):
      UIApplication.shared.open(components?.url, usingSafariServices: false)
    case .event, .open:
      // 내비게이션 패널을 숨겨야 하는 웹 페이지
      let links: [Linkable] = [Godo.orderSheet(nil), Godo.orderCancellation(nil), Godo.coupon(nil), Godo.deliveryGuide]
      let isShowNavigationPanel: Bool = links.first(where: { components.contains($0) }).isEmpty

      if components?.url != nil {
        presentWebViewController(isShowNavigationPanel: isShowNavigationPanel)
      } else if kind == .event {
        present(by: EventListViewController.self, with: EventListNavigationController.self, storyboardIdentifier: .home)
      }
    case .order where identifier != nil:
      authenticateUser()?.presentWebViewController(isShowNavigationPanel: false)
    case .compose:
      handleDeepLinkForCompose()
    case .recipe:
      if identifier != nil {
        presentWebViewController(isShowNavigationPanel: false)
      } else {
        present(by: RecipeListViewController.self, with: RecipeListNavigationController.self, storyboardIdentifier: .home)
      }
    case .login:
      present(by: LoginViewController.self, with: LoginNavigationController.self, storyboardIdentifier: .main)
    case .aboutKurly:
      presentWebViewController(isShowNavigationPanel: true)
    case .signup:
      present(by: SignupViewController.self, with: SignupNavigationController.self, storyboardIdentifier: .main)
    case .gift:
      self.handleDeepLinkForGift()
    case .giftList:
      self.handleDeepLinkForGiftList()
    case .notice:
      self.handleDeepLinkForNotice()
    case .frequentlyProducts:
      self.authenticateUser()?.handleDeepLinkForFrequentlyProducts()
    default:
      DLog.warning("Case not found: \(self)")
    }
  }
}

// MARK: - Private

private extension DeepLink {
  func authenticateUser() -> DeepLink? {
    if SessionManager.shared.isGuest {
      present(by: LoginViewController.self, with: LoginNavigationController.self, storyboardIdentifier: .main) {
        $0.configure(successDismissType: .deepLink(self), guestOrderType: .disable)
//                $0.deepLink = self
      }
    } else {
      return self
    }

    return nil
  }

  func handleDeepLinkForHome() {
    guard let tabBarController = UIApplication.shared.tabBarController else {
      return
    }

    // 홈 탭 --> 컬리추천 --> 화면 최상단으로 이동 --> 모든 배너를 첫번째 항목으로
    tabBarController.dismissAndPopToSelectedNavigationController(animated: options.isAnimated) {
      tabBarController.switch(to: .home)

      NotificationCenter.default.post(name: .moveToRecommendation, object: nil)
      // 화면 전환 순서대로 로그를 쌓기 위해서 일정 시간 이후에 노티피케이션을 호출
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        NotificationCenter.default.post(name: .updateRecommendation, object: nil)
      }
    }
  }

  func handleDeepLinkForGiftList() {
    guard let tabBarController = UIApplication.shared.tabBarController else {
      return
    }
    tabBarController.switch(to: .category)
    let categoryNavigationController = tabBarController.navigationController(of: .category)
    let hasProductViewController = categoryNavigationController?.viewControllers.contains(where: { $0 is ProductViewController })
    if hasProductViewController ?? false {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        NotificationCenter.default.post(name: .moveToProductList, object: nil)
      }
    } else {
      categoryNavigationController?.popToRootViewController(animated: false)
      let categoryViewController = categoryNavigationController?.viewControllers
        .first { $0 is CategoryViewController }
      let hasCategoryViewController = categoryViewController != nil
      if hasCategoryViewController {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          NotificationCenter.default.post(name: .moveToGiftCategoryProducts, object: nil)
        }
      }
    }
  }

  func handleDeepLinkForProductCollection() {
    guard let tabBarController = UIApplication.shared.tabBarController else {
      return
    }
    tabBarController.dismissAndPopToSelectedNavigationController(animated: options.isAnimated) {
      tabBarController.switch(to: .home)
    }
    NotificationCenter.default.post(name: .moveToProductCollection, object: self.identifier)
  }

  func handleDeepLinkForSearch() {
    guard let tabBarController = UIApplication.shared.tabBarController else {
      return
    }

    tabBarController.dismissAndPopToSelectedNavigationController(animated: options.isAnimated) {
      tabBarController.switch(to: .search)

      guard let searchViewController = tabBarController.selectedNavigationController?.topViewController as? SearchViewController else {
        return
      }
      
      let queryItems = self.components?.queryItems
      if let keyword = queryItems?[name: .keyword], !keyword.isBlank {
        searchViewController.handleDeeplinkSearch.onNext(keyword)
      } else {
        searchViewController.handleCancel.onNext(())
      }
    }
  }

  func handleDeepLinkForMyKurly() {
    switch path {
    case .inquiry? where identifier != nil:
      authenticateUser()?.presentWebViewController(isShowNavigationPanel: false)
    case .coupon?:
      authenticateUser()?.presentWebViewController(isShowNavigationPanel: false)
    case .bulkOrder?:
      authenticateUser()?.presentWebViewController(isShowNavigationPanel: false)
    case .oneToOneInquiry:
      authenticateUser()?.presentOneToOneInquiry()
    case .none:
      guard let tabBarController = UIApplication.shared.tabBarController else {
        return
      }

      tabBarController.dismissAndPopToSelectedNavigationController(animated: options.isAnimated) {
        tabBarController.switch(to: .myKurly)
      }
    default:
      break
    }
  }

  func handleDeepLinkForProduct() {
    switch path {
    case .review? where identifier != nil && components != nil:
      self.presentWebViewController(isShowNavigationPanel: false)
    case .inquiry? where identifier != nil && components != nil:
      self.authenticateUser()?.presentWebViewController(isShowNavigationPanel: false)
    case .none:
      var deeplinkAmplitudeEvent: AmplitudeEvent?
      if let path = self.components?.path, Path(rawValue: path) != nil {
        deeplinkAmplitudeEvent = AmplitudeEvent.name(.selectRelatedProduct)?
          .properties(self.composeRelatedProductAmplitudeEventProperties())
      }
      self.present(
        by: ProductViewController.self,
        with: ProductNavigationController.self,
        storyboardIdentifier: .product
      ) {
        let eventProperties: AmplitudeEventProperties = [
          .referrerEvent: AmplitudeEvent.Name.selectRelatedProduct.rawValue
        ]
        $0.trackableProduct = TrackableProduct(
          self.identifier,
          eventProperties,
          deeplinkAmplitudeEvent
        )
      }
    default:
      break
    }
  }

  private func handleDeepLinkForProductSelection() {
    let eventProperties: AmplitudeEventProperties = [
      .referrerEvent: AmplitudeEvent.Name.selectRelatedProductShortcut.rawValue
    ]
    let deeplinkAmplitudeEvent = AmplitudeEvent
      .name(.selectRelatedProductShortcut)?
      .properties(self.composeRelatedProductAmplitudeEventProperties())
    let viewModel = ModernProductSelectionViewModel(
      productIdentifier: self.identifier ?? "",
      productEventProperties: eventProperties,
      deeplinkAmplitudeEvent: deeplinkAmplitudeEvent,
      isGift: false,
      requestManager: RequestManager.shared,
      giftService: GiftServiceImpl(requestManager: .shared, sessionManager: .shared)
    )
    self.presentProductSelection(viewModel: viewModel)
  }

  private func presentProductSelection(viewModel: ModernProductSelectionViewModel) {
    let controller = ModernProductSelectionViewController(viewModel: viewModel)
    let navi = ProductSelectionNavigationController(rootViewController: controller)
    if #available(iOS 13.0, *) {
      navi.modalPresentationStyle = .pageSheet
    } else {
      navi.modalPresentationStyle = .fullScreen
    }
    self.present(controller: controller, navigationController: navi)
  }

  private func handleDeepLinkForGift() {
    switch self.path {
    case .giftDetail? where self.identifier != nil && self.components != nil:
      self.presentGiftDetail()
    default:
      break
    }
  }

  func handleDeepLinkForCompose() {
    switch path {
    case .review?:
      authenticateUser()?.composeReview()
    case .inquiry:
      authenticateUser()?.presentOneToOneInquiry(isApply: true)
    default:
      break
    }
  }

  func composeReview() {
    guard let productIdentifier = identifier else {
      DLog.warning("productIdentifier is nil, deepLink: \(self)")

      return
    }

    let queryItems = components?.queryItems
    let packageOptionProductIdentifier = queryItems?[name: .number(.packageOptionProduct)] ?? queryItems?[name: .number(.packageProduct)]
    let orderIdentifier = queryItems?[name: .identifier(.order)] ?? queryItems?[name: .number(.order)]

    MBProgressHUD.showHUDInWindow()
    RequestManager.shared.requestProductReviewsVerifyPermissions(productIdentifier, packageOptionProductIdentifier: packageOptionProductIdentifier, orderIdentifier: orderIdentifier) {
      MBProgressHUD.hideHUDInWindow()

      guard let json = $0.json else {
        DLog.error($0.error as Any)

        ToastManager.shared.show($0.error?.message, type: .error)

        return
      }

      let data = json["data"]
      let product = ReviewableProduct(data)

      self.present(by: ComposeReviewViewController.self, with: ComposeReviewNavigationController.self, storyboardIdentifier: .compose) {
        $0.product = product
      }
    }
  }
  
  private func composeRelatedProductAmplitudeEventProperties() -> AmplitudeEventProperties {
    guard let queryItems = self.components?.queryItems else { return [:] }
    let position = queryItems[name: .position].map { Int($0) }
    return [
      .isSoldOut: queryItems[name: .isSoldout],
      .originPrice: queryItems[name: .originPrice],
      .price: queryItems[name: .price],
      .packageID: queryItems[name: .boardType(.default)],
      .packageName: queryItems[name: .productName],
      .position: position?.increased(),
      .packageCount: queryItems[name: .packageCount],
      .referrerPackageID: queryItems[name: .referrerPackageID]
    ]
  }
  
  func presentWebViewController(isShowNavigationPanel: Bool = true) {
    guard components?.url != nil else {
      return
    }

    present(by: WebViewController.self, with: WebNavigationController.self, storyboardIdentifier: .main) {
      $0.isShowNavigationPanel = isShowNavigationPanel
      $0.deepLink = self
    }
  }

  private func presentGiftDetail() {
    guard let orderNumber = self.identifier,
          let id = Int(orderNumber) else { return }
    
    let currentNavigationController = UIApplication.shared.visibleViewController()?.navigationController
    let giftService: GiftOrderService = GiftServiceImpl(requestManager: .shared, sessionManager: .shared)
    let viewController = GiftHistoryDetailViewController(orderNumber: id, giftService: giftService)
    currentNavigationController?.show(viewController, sender: nil)
  }
  
  private func handleDeepLinkForNotice() {
    guard let controller = R.storyboard.main.webViewController() else { return }

    let queryItems = self.components?.queryItems
    let number = queryItems?[name: .number(.default)]

    controller.link = Godo.noticeContent(number)
    controller.isShowNavigationPanel = true
    controller.isRequiredToken = true

    let currentNavigationController = UIApplication.shared.visibleViewController()?.navigationController
    currentNavigationController?.show(controller, sender: nil)
  }
  
  private func handleDeepLinkForFrequentlyProducts() {
    guard let controller = R.storyboard.myKurly.purchaseHistoryViewController() else { return }
    controller.shouldScrollToFrequentlyPurchasedList = true

    let currentNavigationController = UIApplication.shared.visibleViewController()?.navigationController
    currentNavigationController?.show(controller, sender: nil)
  }
  
  private func presentOneToOneInquiry(isApply: Bool = false) {
    guard let navigationController = UIApplication.shared.visibleViewController()?.navigationController
    else {
      return
    }
    let session = RequestManager.shared.manager
    let provider = MemberBoardProvider(session: session)
    let service = OneToOneInquiryServiceImpl(provider: provider)
    let listReactor = OneToOneInquiryListReactor(oneToOneService: service)
    let list = OneToOneInquiryListViewController(reactor: listReactor)
    navigationController.show(list, sender: nil)
    if isApply {
      let apply = OneToOneInquiryApplyViewController(
        reactor: OneToOneInquiryApplyReactor(oneToOneService: service, type: .create)
      )
      navigationController.show(apply, sender: nil)
    }
  }
}

private extension DeepLink {

  func present(controller: UIViewController, navigationController: UINavigationController) {
    func dismissAndPresentModally(on presentingViewController: UIViewController) {
      presentingViewController.dismiss(animated: true) {
        presentModally(on: presentingViewController)
      }
    }

    func presentModally(on presentingViewController: UIViewController) {
      presentingViewController.present(navigationController, animated: true)
    }

    guard let visibleViewController = UIApplication.shared.visibleViewController() else {
      return
    }

    let isSameController = type(of: controller) == type(of: visibleViewController)

    // (모달로 전환된) 현재 뷰 컨트롤러가 새로 전환되는 뷰 컨트롤러와 같은 경우
    if let presentingViewController = visibleViewController.presentingViewController,
      isSameController {
      if let webViewController = visibleViewController as? WebViewController {
        // WebViewController 의 툴 바가 존재하고 옵션에 .presentModally 가 없다면 현재 뷰 컨트롤러에서 웹 페이지를 전환
        if webViewController.isShowNavigationPanel && !options.contains(.presentModally) {
          webViewController.loadTargetURL()
        } else {
          presentModally(on: visibleViewController)
        }
      } else {
        dismissAndPresentModally(on: presentingViewController)
      }
    } else {
      presentModally(on: visibleViewController)
    }
  }

  func present<T: UIViewController, U: UINavigationController>(
    by type: T.Type,
    with navigationControllerType: U.Type,
    storyboardIdentifier: UIStoryboard.Identifier,
    willPresent: ((_ viewController: T) -> Void)? = nil
  ) {
    func dismissAndPresentModally(on presentingViewController: UIViewController) {
      presentingViewController.dismiss(animated: true) {
        presentModally(on: presentingViewController)
      }
    }

    func presentModally(on presentingViewController: UIViewController) {
      presentingViewController.present(by: navigationControllerType, storyboardIdentifier: storyboardIdentifier) {
        if let viewController = $0.topViewController as? T {
          willPresent?(viewController)
        }
      }
    }

    guard let visibleViewController = UIApplication.shared.visibleViewController() else {
      return
    }

    // (모달로 전환된) 현재 뷰 컨트롤러가 새로 전환되는 뷰 컨트롤러와 같은 경우
    if let presentingViewController = visibleViewController.presentingViewController, visibleViewController is T {
      if let webViewController = visibleViewController as? WebViewController {
        // WebViewController 의 툴 바가 존재하고 옵션에 .presentModally 가 없다면 현재 뷰 컨트롤러에서 웹 페이지를 전환
        if webViewController.isShowNavigationPanel && !options.contains(.presentModally) {
          // visibleViewController is T 이므로 Force Unwrapping 을 해도 문제 없음
          willPresent?(visibleViewController as! T)

          // willPresent 에서 웹 페이지를 불러오는데 필요한 정보를 설정했다는 전제 하에 targetURL 을 이용하여 웹 페이지를 불러온다.
          webViewController.loadTargetURL()
        } else {
          presentModally(on: visibleViewController)
        }
      } else {
        dismissAndPresentModally(on: presentingViewController)
      }
    } else {
      presentModally(on: visibleViewController)
    }
  }
}
