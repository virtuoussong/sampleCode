//
//  OneToOneInquiryProductSelectionViewController.swift
//  MarketKurly
//
//  Created by MK-Mac-255 on 2021/12/09.
//  Copyright © 2021 com.kurly. All rights reserved.
//

import UIKit

import ReactorKit
import RxKeyboard
import RxCocoa

final class OneToOneInquiryProductSelectionViewController: BaseViewController, View {
  private enum Metric {
    static let periodSelectButtonViewHeight = 40.f
    static let searchBarHeight = 40.f
    static let dateSelectDetailButtonHeight = 40.f
  }

  private enum Text {
    static let allowMultiple = R.string.localizable.composeInquiryOrderProductSelectGuide()
  }

  // MARK: - UI Components
  private let periodSelectButtonGroupView: OneToOneInquiryPeriodButtonGroupView

  private let productSearchView: OneToOneInquiryProductSearchView

  private let instructionLabel = UILabel().then {
    $0.text = Text.allowMultiple
    $0.textColor = .kurly.gray450
    $0.font = UIFont.system.regular(12)
  }

  private let orderedListCollectionView: OneToOneInquiryProductCollectionView

  private let bottomConfirmButtonView: OneToOneInquiryConfirmButtonView

  private let noDataView = UIView().then {
    $0.backgroundColor = .white
    $0.isHidden = true
  }

  private let noDataLabel = UILabel().then {
    $0.text = R.string.localizable.composeInquiryOrderProductNoOrder()
    $0.font = UIFont.system.regular(16)
    $0.textColor = .kurly.gray400
  }

  private let loadingIndicator = UIActivityIndicatorView(style: .gray).then {
    $0.hidesWhenStopped = true
  }

  private let loadingView = UIView().then {
    $0.backgroundColor = .white
    $0.isHidden = true
  }

  // MARK: - Properties
  private let periodButtonTapSubject = PublishSubject<OneToOneInquiryPeriodButtonType>()
  private let periodDetailTapSubject = PublishSubject<OneToOneInquiryCalendarType>()
  private let periodDateSubject = PublishSubject<OneToOneInquiryDatePeriod>()
  private let searchTextSubject = PublishSubject<String>()
  private let searchTypeSubject = PublishSubject<OneToOneInquirySearchType>()
  private let confirmButtonEnableSubject = PublishSubject<Bool>()

  init(reactor: OneToOneInquiryProductSelectReactor) {
    self.periodSelectButtonGroupView = OneToOneInquiryPeriodButtonGroupView(
      tapSubject: self.periodButtonTapSubject,
      detailTapSubject: self.periodDetailTapSubject,
      dateStringSubject: self.periodDateSubject
    )

    self.productSearchView = OneToOneInquiryProductSearchView(
      searchTypeSubject: self.searchTypeSubject,
      searchSubject: self.searchTextSubject
    )

    self.orderedListCollectionView = OneToOneInquiryProductCollectionView(
      reactor: reactor
    )

    self.bottomConfirmButtonView = OneToOneInquiryConfirmButtonView(
      buttonEnableSubject: self.confirmButtonEnableSubject
    )

    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryProductSelectionViewController")
  }

  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.addSubviews()
    self.configureViewTapGesture()
  }

  // MARK: - Bind
  func bind(reactor: OneToOneInquiryProductSelectReactor) {
    self.input(reactor: reactor)
    self.output(reactor: reactor)
  }

  private func input(reactor: OneToOneInquiryProductSelectReactor) {
    self.rx.viewDidLoad
      .take(1)
      .map { .selectPeriodType(.oneWeek) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.periodButtonTapSubject
      .map { .selectPeriodType($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.periodDetailTapSubject
      .withUnretained(self)
      .subscribe(onNext: { `self`, type in
        self.presentCalendar(type: type)
      })
      .disposed(by: self.disposeBag)

    self.searchTextSubject
      .map { .searchWord($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.productSearchView.rx.searchTypeButtonTap
      .withUnretained(self)
      .subscribe(onNext: { `self`, _ in
        self.presentSearchTypeSelectView()
      })
      .disposed(by: self.disposeBag)

    self.bottomConfirmButtonView.rx.confirmTap
      .withUnretained(self)
      .do { `self`, _ in
        self.dismiss(animated: true)
      }
      .map { _ in .setSelectedOrder }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
  }

  private func output(reactor: OneToOneInquiryProductSelectReactor) {
    reactor.pulse(\.$periodType)
      .withUnretained(self)
      .bind { `self`, type in
        self.updatePeriodButtons(type: type)
      }
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$periodDates)
      .filter(reactor.state.map { $0.periodType == .specificDates })
      .compactMap { $0 }
      .bind(to: self.periodDateSubject)
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$workingOrderSections)
      .map { !$0.isEmpty }
      .bind(to: self.noDataView.rx.isHidden)
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$isNoDataRetrieved)
      .map { !$0 }
      .bind(to: self.noDataView.rx.isHidden)
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$isLoading)
      .withUnretained(self)
      .subscribe(onNext: { `self`, isLoding in
        self.toggleLoadingView(isLoading: isLoding)
      })
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$searchType)
      .bind(to: self.searchTypeSubject)
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$searchWord)
      .compactMap { $0 }
      .withUnretained(self)
      .subscribe { `self`, text in
        self.productSearchView.setSearchField(text: text)
      }
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$isConfirmButtonEnabled)
      .bind(to: self.confirmButtonEnableSubject)
      .disposed(by: self.disposeBag)
  }

  private func configureViewTapGesture() {
    let viewTap = UITapGestureRecognizer()
    viewTap.cancelsTouchesInView = false
    self.view.addGestureRecognizer(viewTap)
    viewTap.rx.event
      .withUnretained(self)
      .bind { `self`, _ in
        self.view.endEditing(true)
      }
      .disposed(by: self.disposeBag)
  }

  // MARK: - Layout
  private func addSubviews() {
    self.view.add(
      self.periodSelectButtonGroupView,
      self.productSearchView,
      self.instructionLabel,
      self.orderedListCollectionView,
      self.bottomConfirmButtonView,
      self.noDataView.with(
        self.noDataLabel
      ),
      self.loadingView.with(
        self.loadingIndicator
      )
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.periodSelectButtonGroupView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(6)
      make.leading.trailing.equalToSuperview().inset(20)
    }

    self.productSearchView.snp.makeConstraints { make in
      make.top.equalTo(self.periodSelectButtonGroupView.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview().inset(20)
      make.height.equalTo(40)
    }

    self.instructionLabel.snp.makeConstraints { make in
      make.top.equalTo(self.productSearchView.snp.bottom).offset(12)
      make.left.right.equalToSuperview().offset(20)
    }

    self.orderedListCollectionView.snp.makeConstraints { make in
      make.top.equalTo(self.instructionLabel.snp.bottom).offset(16)
      make.leading.trailing.bottom.equalToSuperview()
    }

    self.bottomConfirmButtonView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
    }

    self.bottomConfirmButtonView.makeBottomConstraint(self.view.safeAreaLayoutGuide.snp.bottom)

    self.noDataView.snp.makeConstraints { make in
      make.top.equalTo(self.productSearchView.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(self.bottomConfirmButtonView.snp.top)
    }

    self.noDataLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }

    self.loadingView.snp.makeConstraints { make in
      make.edges.equalTo(self.orderedListCollectionView)
    }

    self.loadingIndicator.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }

  // MARK: - Action
  private func updateCollectionViewBottom(inset: CGFloat) {
    self.orderedListCollectionView.snp.updateConstraints { make in
      make.bottom.equalTo(self.view.snp.bottom).inset(inset)
    }
    self.orderedListCollectionView.superview?.layoutIfNeeded()
  }

  private func updatePeriodButtons(type: OneToOneInquiryPeriodButtonType) {
    self.periodSelectButtonGroupView.updatePeriodButtons(type: type)
  }

  private func toggleLoadingView(isLoading: Bool) {
    if isLoading {
      self.loadingView.isHidden = false
      self.loadingIndicator.startAnimating()
    } else {
      self.loadingView.isHidden = true
      self.loadingIndicator.stopAnimating()
    }
  }

  // MARK: Router
  private func presentCalendar(type: OneToOneInquiryCalendarType) {
    guard let reactor = self.reactor,
          let period = reactor.currentState.periodDates else { return }

    let calendarReactor = OneToOneInquiryCalendarReactor(
      calendarService: OneToOneInquiryCalendarDateServiceImp(
        dayMaker: OneToOneInquiryCalendarDayMaker()
      ),
      selectType: type,
      period: period
    )

    let contentView = OneToOneInquiryCalendarViewController(
      reactor: calendarReactor
    ).then {
      if let reactor = self.reactor {
        $0.rx.datesSelectConfirm
          .map {
            OneToOneInquiryDatePeriod(
              startDate: $0.startDate,
              endDate: $0.endDate
            )
          }
          .map { .selectPeriodDates($0) }
          .bind(to: reactor.action)
          .disposed(by: self.disposeBag)
      }
    }

    let bottomSheet = BottomSheetViewController(contentViewController: contentView)
    self.present(bottomSheet, animated: true)
  }

  private func presentSearchTypeSelectView() {
    guard let reactor = self.reactor else {
      return
    }

    let currnetSearchType = reactor.currentState.searchType
    let contentView = OneToOneInquirySearchTypeSelectionViewController(
      selected: currnetSearchType
    ).then {
      if let reactor = self.reactor {
        $0.rx.searchTypeButtonTap
          .map { .selectSearchType($0) }
          .bind(to: reactor.action)
          .disposed(by: self.disposeBag)
      }
    }

    let bottomSheet = BottomSheetViewController(contentViewController: contentView)
    self.present(bottomSheet, animated: true)
  }

  @objc private func closeButtonDidTap() {
    self.dismiss(animated: true)
  }
}

extension Reactive where Base: OneToOneInquiryProductSelectionViewController {
  var itemSelected: ControlEvent<OneToOneInquiryOrderSelectionState> {
    let itemSelected = self.base.reactor?.state.map(\.selectionState)
      .compactMap { $0 }
    return ControlEvent(events: itemSelected ?? .empty())
  }
}
