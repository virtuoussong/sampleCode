//
//  WebtoonCookieManager.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/05/12.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import Foundation
import RxSwift

final class WebtoonClickKeyManager {
  static let shared = WebtoonClickKeyManager()

  private var disposedBag = DisposeBag()

  private var webToonClickKey: WebtoonClickKey?

  private let service: MarketingService = MarketingServiceImp(
    provider: MarketingProvider(
      session: RequestManager.shared.manager
    )
  )

  var isOpenedWithWebEvent = false

  private init() {}

  func saveClickKey(with parameters: [AnyHashable: Any]?) {
    guard let isWebtoonEvent = parameters?["is_webtoon_event"] as? String,
       let isWebtoonEvent = isWebtoonEvent.bool,
       isWebtoonEvent,
       let clickKey = parameters?["click_key"] as? String else {
      return
    }

    self.isOpenedWithWebEvent = true

    if SessionManager.shared.isGuest {
      self.webToonClickKey = WebtoonClickKey(key: clickKey)
    }
  }

  func postKeyIfNeeded() {
    guard let isValid = self.webToonClickKey?.isValid,
          isValid else {
      self.deleteClickKey()
      return
    }
    self.requestClickKeyPost()
  }

  func deleteClickKey() {
    self.webToonClickKey = nil
  }

  private func requestClickKeyPost() {
    guard let clickKey = self.webToonClickKey?.clickKey else { return }

    self.service.requestClickKeyPost(key: clickKey)
      .asObservable()
      .do(onDispose: { [weak self] in
        self?.deleteClickKey()
      })
      .bind { _ in }
      .disposed(by: self.disposedBag)
  }
}
