//
//  OneToOneInquiryProductSearchView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/12/22.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

final class OneToOneInquiryProductSearchView: BaseView {
  private enum Text {
    static let pleaseTypeIn = R.string.localizable.composeInquiryOrderProductSearchGuide()
  }

  fileprivate let searchTypeSelectButton = OneToOneInquirySearchTypeButton()

  private let grayLineView = UIView().then {
    $0.backgroundColor = .kurly.gray250
  }

  private let searchTextField = UITextField().then {
    $0.placeholder = Text.pleaseTypeIn
    $0.backgroundColor = .kurly.bgLightGray
    $0.font = UIFont.system.regular(14)
    $0.textColor = .kurly.gray800
    $0.clearButtonMode = .whileEditing
  }

  // MARK: Initializer
  init(
    searchTypeSubject: PublishSubject<OneToOneInquirySearchType>,
    searchSubject: PublishSubject<String>
  ) {
    super.init(frame: .zero)
    self.backgroundColor = .kurly.bgLightGray
    self.layer.cornerRadius = 4
    self.clipsToBounds = true
    self.addSubViews()
    self.bind(
      searchTypeSubject: searchTypeSubject,
      searchSubject: searchSubject
    )
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryProductSearchView")
  }

  func bind(
    searchTypeSubject: PublishSubject<OneToOneInquirySearchType>,
    searchSubject: PublishSubject<String>
  ) {
    self.searchTextField.rx.text.orEmpty
      .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .bind(to: searchSubject)
      .disposed(by: self.disposeBag)

    let searchText = self.searchTextField.rx.text.orEmpty
    self.searchTextField.rx.controlEvent(.editingDidEndOnExit)
      .withLatestFrom(searchText)
      .bind(to: searchSubject)
      .disposed(by: self.disposeBag)

    searchTypeSubject
      .map { $0 }
      .withUnretained(self)
      .subscribe(onNext: { `self`, type in
        self.searchTypeSelectButton.set(title: type.text)
        self.setSearchFieldPlaceHolder(type: type)
      })
      .disposed(by: self.disposeBag)
  }

  private func addSubViews() {
    self.add(
      self.searchTypeSelectButton,
      self.grayLineView,
      self.searchTextField
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.searchTypeSelectButton.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.leading.equalToSuperview()
      make.width.equalTo(96)
      make.bottom.equalToSuperview()
    }

    self.grayLineView.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.size.equalTo(CGSize(width: 1, height: 14))
      make.leading.equalTo(self.searchTypeSelectButton.snp.trailing)
    }

    self.searchTextField.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.leading.equalTo(self.grayLineView.snp.trailing).offset(12)
      make.trailing.bottom.equalToSuperview()
    }
  }

  private func setSearchFieldPlaceHolder(type: OneToOneInquirySearchType) {
    switch type {
    case .product:
      self.searchTextField.placeholder = R.string.localizable.composeInquiryPlaceholderRequireOrderProductName()
    case .orderNumber:
      self.searchTextField.placeholder = R.string.localizable.composeInquiryPlaceholderRequireOrderProductNumber()
    }
  }

  func setSearchField(text: String) {
    self.searchTextField.text = text
  }
}

extension Reactive where Base: OneToOneInquiryProductSearchView {
  var searchTypeButtonTap: ControlEvent<Void> {
    return self.base.searchTypeSelectButton.rx.tap
  }
}
