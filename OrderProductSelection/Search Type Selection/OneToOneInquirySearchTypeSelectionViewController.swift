//
//  OneToOneInquirySearchTypeSelectionViewController.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/12/21.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

extension Reactive where Base: OneToOneInquirySearchTypeSelectionViewController {
  var searchTypeButtonTap: ControlEvent<OneToOneInquirySearchType> {
    return ControlEvent(events: self.base.buttonTapSubject)
  }
}

final class OneToOneInquirySearchTypeSelectionViewController: BaseViewController {
  private let stackView = UIStackView().then {
    $0.axis = .vertical
    $0.distribution = .fillEqually
  }

  fileprivate let buttonTapSubject = PublishSubject<OneToOneInquirySearchType>()

  init(selected type: OneToOneInquirySearchType) {
    super.init(nibName: nil, bundle: nil)
    self.addTypeSelectionButton(selected: type)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.addSubviews()
  }

  private func addSubviews() {
    self.view.add(
      self.stackView
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    let height = self.stackView.arrangedSubviews.count * 57
    self.stackView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(32)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(height)
    }
  }

  private func addTypeSelectionButton(selected type: OneToOneInquirySearchType) {
    OneToOneInquirySearchType.allCases.forEach { searchType in
      let button = UIButton().then {
        $0.setTitle(searchType.text, for: .normal)
        $0.titleLabel?.font = UIFont.system.regular(16)
        $0.setTitleColor(.kurly.gray800, for: .normal)
        $0.setTitleColor(.kurly.purple, for: .selected)
        $0.setBackgroundColor(.kurly.bgLightGray, for: .selected)
        $0.setBackgroundColor(.white, for: .normal)
        $0.alignTitleToLeftEnd(offSet: 20)
      }

      let isSelected = searchType == type ? true : false
      button.isSelected = isSelected

      button.rx.tap
        .do(onNext: { [weak self] in
          self?.dismiss(animated: true)
        })
        .map { searchType }
        .bind(to: self.buttonTapSubject)
        .disposed(by: self.disposeBag)

      self.stackView.addArrangedSubview(button)
    }
  }
}

extension OneToOneInquirySearchTypeSelectionViewController: BottomSheetProtocol {
  var halfContentHeight: CGFloat {
    return 145
  }

  var trackedScrollView: UIScrollView? {
    return nil
  }
}
