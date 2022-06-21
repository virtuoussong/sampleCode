//
//  PeriodSelectButtonGroupView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/09/01.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

final class OneToOneInquiryPeriodButtonGroupView: BaseView {

  // MARK: - UI Component
  private var verticalStackView = UIStackView().then {
    $0.spacing = 6
    $0.axis = .vertical
  }

  private var dateTypeSelectStackView = UIStackView().then {
    $0.spacing = 6
    $0.distribution = .fillEqually
    $0.backgroundColor = .white
  }

  // MARK: - Property
  private let dateDetailButtonView: OneToOneInquiryDateButtonGroupView
  private var periodTypeButtons: [OneToOneInquiryPeriodTypeButton] = []

  // MARK: - Life Cycle
  init(
    tapSubject: PublishSubject<OneToOneInquiryPeriodButtonType>,
    detailTapSubject: PublishSubject<OneToOneInquiryCalendarType>,
    dateStringSubject: PublishSubject<OneToOneInquiryDatePeriod>
  ) {
    self.dateDetailButtonView = OneToOneInquiryDateButtonGroupView(
      tapSubject: detailTapSubject,
      periodSubject: dateStringSubject
    ).then {
      $0.isHidden = true
      $0.alpha = 0
      $0.clipsToBounds = true
    }

    super.init(frame: .zero)
    self.periodTypeButtons = OneToOneInquiryPeriodButtonType.allCases
      .map { type -> OneToOneInquiryPeriodTypeButton in
      let button = OneToOneInquiryPeriodTypeButton(type: type)
      button.rx.tap
        .map { type }
        .bind(to: tapSubject)
        .disposed(by: self.disposeBag)

      return button
    }

    self.backgroundColor = .white
    self.addSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryPeriodButtonGroupView")
  }

  private func addSubviews() {
    self.add(
      self.verticalStackView.withArranged(
        self.dateTypeSelectStackView.withArranged(self.periodTypeButtons),
        self.dateDetailButtonView
      )
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.verticalStackView.snp.makeConstraints { make in
      make.top.bottom.equalTo(self)
      make.leading.trailing.equalTo(self)
    }

    self.dateTypeSelectStackView.snp.makeConstraints { make in
      make.height.equalTo(40)
    }

    self.dateDetailButtonView.snp.makeConstraints { make in
      make.height.equalTo(40)
    }
  }

  func updatePeriodButtons(type: OneToOneInquiryPeriodButtonType) {
    if let selectedIndex = self.periodTypeButtons.firstIndex(
      where: { button in
        button.type == type
      }
    ) {
      self.periodTypeButtons.enumerated().forEach { index, button in
        let value = selectedIndex == index ? true : false
        button.isSelected = value
      }
    }

    var isHiddend = true
    if type == .specificDates {
      isHiddend = false
    }
    self.animateDateStackViewVisibility(isHidden: isHiddend)
  }

  private func animateDateStackViewVisibility(isHidden: Bool) {
    let currentValue = self.dateDetailButtonView.isHidden
    let isNewValueDifferent = isHidden != currentValue
    guard isNewValueDifferent else {
      return
    }

    if !isHidden {
      UIView.animate(withDuration: 0.2) {
        self.dateDetailButtonView.isHidden = isHidden
      } completion: { _ in
        let alpha = isHidden ? 0.f : 1.f
        self.dateDetailButtonView.alpha = alpha
      }
    } else {
      UIView.animate(withDuration: 0.2) {
        self.dateDetailButtonView.isHidden = isHidden
        let alpha = isHidden ? 0.f : 1.f
        self.dateDetailButtonView.alpha = alpha
      }
    }

  }
}
