//
//  CalendarView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/08.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReusableKit
import RxSwift
import ReactorKit
import RxCocoa

final class OneToOneInquiryCalendarViewController: BaseViewController, UIScrollViewDelegate, View {

  private enum Metric {
    static let currentMonthTextViewHeight = 54.f
  }

  private enum Text {
    static let confirm = R.string.localizable.composeInquiryOrderProductCalendarSelect()
  }

  // MARK: UI Component
  private let calendarCollectionView: OneToOneInquiryCalendarCollectionView

  private let confirmButton = UIButton().then {
    $0.setTitle(Text.confirm, for: .normal)
    $0.titleLabel?.font = UIFont.system.semibold(16)
    $0.setBackgroundColor(.kurly.lightGray, for: .disabled)
    $0.setBackgroundColor(.kurly.purple, for: .normal)
    $0.layer.cornerRadius = 6
    $0.clipsToBounds = true
  }

  private let warningLabel = UILabel().then {
    $0.text = R.string.localizable.composeInquiryOrderProductCalendarSearchSixmonth()
    $0.font = UIFont.system.regular(12)
    $0.textColor = .kurly.gray450
  }

  // MARK: Property
  fileprivate let dateSelectConfirmSubject = PublishSubject<OneToOneInquirySelectedDates>()
  private let calendarInitialScrollIndexSubject = PublishSubject<Int>()

  // MARK: Initializer
  init(reactor: OneToOneInquiryCalendarReactor) {
    self.calendarCollectionView = OneToOneInquiryCalendarCollectionView(
      reactor: reactor,
      initialScrollIndexSubject: self.calendarInitialScrollIndexSubject
    )
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    print("Calendar dismissed")
  }

  // MARK: View lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.addSubView()
  }

  // MARK: Reactor
  func bind(reactor: OneToOneInquiryCalendarReactor) {
    self.input(reactor: reactor)
    self.output(reactor: reactor)
  }

  func input(reactor: OneToOneInquiryCalendarReactor) {
    self.rx.viewDidAppear
      .withLatestFrom(reactor.pulse(\.$initialSelectedDayIndex))
      .compactMap { $0 }
      .bind(to: self.calendarInitialScrollIndexSubject)
      .disposed(by: self.disposeBag)

    self.confirmButton.rx.tap
      .do(onNext: { [weak self] in
        self?.dismiss(animated: true)
      })
      .map {
        OneToOneInquirySelectedDates(
          startDate: reactor.currentState.startDate,
          endDate: reactor.currentState.endDate
        )
      }
      .bind(to: self.dateSelectConfirmSubject)
      .disposed(by: self.disposeBag)
  }

  func output(reactor: OneToOneInquiryCalendarReactor) {
    reactor.pulse(\.$isConfirmButtonEabled)
      .withUnretained(self)
      .subscribe { `self`, bool in
        self.confirmButton.isEnabled = bool
      }
      .disposed(by: self.disposeBag)
  }

  // MARK: - Layout
  private func addSubView() {
    self.view.add(
      self.calendarCollectionView,
      self.confirmButton,
      self.warningLabel
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.calendarCollectionView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(22)
      make.leading.trailing.equalToSuperview().inset(12)
      make.bottom.equalTo(self.warningLabel.snp.top).offset(-12)
    }

    self.warningLabel.snp.makeConstraints { make in
      make.leading.equalToSuperview().inset(22)
      make.bottom.equalTo(self.confirmButton.snp.top).offset(-16)
    }
    self.confirmButton.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(12)
      make.height.equalTo(52)
      make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(8)
    }
  }

  private func calculateContentHeight() -> CGFloat {
    let cellHeight = (self.view.frame.width - 24) / 7
    let calendarHeight = cellHeight * 6
    let topButtonHeight = 70.f
    let bottomButtonHeight = 107.f
    let totalHeight = cellHeight + calendarHeight + topButtonHeight + bottomButtonHeight
    return totalHeight
  }
}

extension OneToOneInquiryCalendarViewController: BottomSheetProtocol {
  var halfContentHeight: CGFloat {
    return self.calculateContentHeight()
  }

  var trackedScrollView: UIScrollView? {
    return nil
  }
}

typealias OneToOneInquirySelectedDates = (startDate: Date, endDate: Date)

extension Reactive where Base: OneToOneInquiryCalendarViewController {
  var datesSelectConfirm: ControlEvent<OneToOneInquirySelectedDates> {
    return ControlEvent(events: self.base.dateSelectConfirmSubject)
  }
}
