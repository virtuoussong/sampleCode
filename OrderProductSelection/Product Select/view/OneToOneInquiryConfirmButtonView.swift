//
//  InquirySelectConfirmButtonView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/09/01.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReactorKit
import RxCocoa
import SnapKit

extension Reactive where Base: OneToOneInquiryConfirmButtonView {
  var confirmTap: ControlEvent<Void> {
    return base.confirmButton.rx.tap
  }
}

final class OneToOneInquiryConfirmButtonView: BaseView {
  private enum Text {
    static let selectConfirm = R.string.localizable.composeInquiryOrderProductSelectCheck()
  }

  fileprivate let confirmButton = UIButton().then {
    $0.setTitle(Text.selectConfirm, for: .normal)
    $0.setTitleColor(.white, for: .normal)
    $0.titleLabel?.font = UIFont.system.semibold(16)
    $0.setBackgroundColor(.kurly.purple, for: .normal)
    $0.setBackgroundColor(.kurly.lightGray, for: .disabled)
    $0.layer.cornerRadius = 4
    $0.clipsToBounds = true
  }

  init(buttonEnableSubject: PublishSubject<Bool>) {
    super.init(frame: .zero)
    self.backgroundColor = .white
    self.addSubViews()
    self.bind(enableSubject: buttonEnableSubject)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func bind(enableSubject: PublishSubject<Bool>) {
    enableSubject
      .bind(to: self.confirmButton.rx.isEnabled)
      .disposed(by: self.disposeBag)
  }

  private func addSubViews() {
    self.add(
      self.confirmButton
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.snp.makeConstraints { make in
      make.top.equalTo(self.confirmButton.snp.top)
    }
  }

  func makeBottomConstraint(_ constrainTarget: ConstraintRelatableTarget) {
    self.confirmButton.snp.makeConstraints { make in
      make.bottom.equalTo(constrainTarget).inset(8)
      make.leading.trailing.equalToSuperview().inset(12)
      make.height.equalTo(52)
    }
  }
}
