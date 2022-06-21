//
//  OneToOneInquiryProductSelectNavigationController.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/02/28.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

final class OneToOneInquiryProductSelectNavigationController: UINavigationController, Themeable {

  var disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.delegate = self
    self.applyDefaultSettingsForNavigationBar()
    self.applyThemeForNavigationBar(using: .white)
  }
}

extension OneToOneInquiryProductSelectNavigationController: UINavigationControllerDelegate {
  func navigationController(
    _ navigationController: UINavigationController,
    willShow viewController: UIViewController,
    animated: Bool
  ) {
    let item = UIBarButtonItem(
      image: R.image.common_navi_btn_exit(),
      style: .done,
      target: self,
      action: nil
    ).then {
      $0.rx.tap
        .withUnretained(self)
        .subscribe { `self`, _ in
          self.dismiss(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    viewController.navigationItem.title = R.string.localizable.composeInquiryOrderProductNavi()
    viewController.navigationItem.leftBarButtonItem = item
    viewController.navigationController?.navigationBar.isTranslucent = false
  }
}
