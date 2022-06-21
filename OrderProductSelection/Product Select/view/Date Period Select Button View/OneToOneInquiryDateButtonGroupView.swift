//
//  InquirySelectedDateButtonGroupView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/09/01.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import RxSwift

final class OneToOneInquiryDateButtonGroupView: BaseView {

  private var stackView = UIStackView().then {
    $0.spacing = 6
    $0.distribution = .fillEqually
    $0.axis = .horizontal
    $0.clipsToBounds = true
  }

  let startDateButton = OneToOneInquiryDateDetailButton()
  let endDateButton = OneToOneInquiryDateDetailButton()

  init(
    tapSubject: PublishSubject<OneToOneInquiryCalendarType>,
    periodSubject: PublishSubject<OneToOneInquiryDatePeriod>
  ) {
    super.init(frame: .zero)
    self.clipsToBounds = true
    self.addSubviews()
    self.bind(buttonTapSubject: tapSubject)
    self.bind(buttonPeriodSubject: periodSubject)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryDateButtonGroupView")
  }

  // MARK: - Layout
  private func addSubviews() {
    self.add(
      self.stackView.withArranged(
        self.startDateButton,
        self.endDateButton
      )
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.stackView.snp.makeConstraints { make in
      make.top.bottom.equalTo(self)
      make.leading.trailing.equalTo(self)
    }
  }

  private func bind(buttonTapSubject: PublishSubject<OneToOneInquiryCalendarType>) {
    self.startDateButton.rx.tap
      .map { .startDatePicker }
      .bind(to: buttonTapSubject)
      .disposed(by: self.disposeBag)

    self.endDateButton.rx.tap
      .map { .endDatePicker }
      .bind(to: buttonTapSubject)
      .disposed(by: self.disposeBag)
  }

  private func bind(buttonPeriodSubject: PublishSubject<OneToOneInquiryDatePeriod>) {
    buttonPeriodSubject
      .bind { self.updateButtonTitles(date: $0) }
      .disposed(by: self.disposeBag)
  }

  private func updateButtonTitles(date: OneToOneInquiryDatePeriod) {
    let dateFormat = R.string.localizable.composeInquiryListOrderProductOrderDate()
    let startDate = date.startDate.format(dateFormat)
    let endDate = date.endDate.format(dateFormat)

    self.startDateButton.setTitle(startDate, for: .normal)
    self.endDateButton.setTitle(endDate, for: .normal)
  }
}
