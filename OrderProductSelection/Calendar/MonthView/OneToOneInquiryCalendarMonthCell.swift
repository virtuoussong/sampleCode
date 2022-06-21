//
//  CalendarMonthCell.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/09.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReusableKit
import RxSwift
import RxCocoa
import RxDataSources

final class OneToOneInquiryCalendarMonthCell: BaseCollectionViewCell {

  private enum Text {
    static let year = R.string.localizable.composeInquiryOrderProductCalendarYear()
    static let month = R.string.localizable.composeInquiryOrderProductCalendarMonth()
  }

  private enum Metric {
    static let weekDayStackViewHeight = 18.f
    static let dateViewSize = CGSize(width: 90, height: 24)
    static let arrowSize = CGSize(width: 24, height: 24)
  }

  private enum Reusable {
    static let dayCell = ReusableCell<OneToOneInquiryCalendarDayCell>()
  }

  private let dateTextContainerView = UIView()

  private let yearAndDateLabel = UILabel().then {
    $0.font = UIFont.system.medium(15)
    $0.textColor = .kurly.gray800
    $0.numberOfLines = 1
  }

  private let backArrowButton = UIButton().then {
    $0.setImage(R.image.calendarBtnPre(), for: .normal)
  }

  private let forwardArrowButton = UIButton().then {
    $0.setImage(R.image.calendarBtnNext(), for: .normal)
  }

  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewFlowLayout().then {
      $0.minimumLineSpacing = 0
      $0.minimumInteritemSpacing = 0
    }
  ).then {
    $0.register(Reusable.dayCell)
    $0.backgroundColor = .white
  }

  private let weekDayStackview = UIStackView().then {
    $0.axis = .horizontal
    $0.distribution = .fillEqually
  }

  private let dataSource = RxCollectionViewSectionedReloadDataSource<OneToOneInquiryCalendarDaySection>(
    configureCell: { _, collectionView, indexPath, item in
    let cell = collectionView.dequeue(Reusable.dayCell, for: indexPath)
    cell.configure(data: item)

    return cell
  })

  let tappedDayCell = PublishSubject<OneToOneInquiryCalendarDayItem>()

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.configureWeekDayStickView()
    self.addViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 CalendarMonthCell")
  }

  func configure(
    data: OneToOneInquiryCalendarMonth,
    directionSubject: PublishSubject<OneToOneInquiryCalendarScrollDirection>,
    cellTapSubject: PublishSubject<OneToOneInquiryCalendarDayItem>
  ) {
    self.yearAndDateLabel.text = "\(data.year)\(Text.year) \(data.month)\(Text.month)"

    let forwardAlpha = data.isForwardEnabled ? 1.f : 0.2.f
    self.forwardArrowButton.alpha = forwardAlpha
    self.forwardArrowButton.isEnabled = data.isForwardEnabled

    let backwardAlpha = data.isBackwardEnabled ? 1.f : 0.2.f
    self.backArrowButton.alpha = backwardAlpha
    self.backArrowButton.isEnabled = data.isBackwardEnabled

    self.disposeBag = DisposeBag()

    self.collectionView.rx.setDelegate(self)
      .disposed(by: self.disposeBag)

    Observable.just(data)
      .map { [OneToOneInquiryCalendarDaySection(items: $0.days)] }
      .bind(to: self.collectionView.rx.items(dataSource: self.dataSource))
      .disposed(by: self.disposeBag)

    self.backArrowButton.rx.tap
      .map { .backward }
      .bind(to: directionSubject)
      .disposed(by: self.disposeBag)

    self.forwardArrowButton.rx.tap
      .map { .forward }
      .bind(to: directionSubject)
      .disposed(by: self.disposeBag)

    self.collectionView.rx.itemSelected
      .withUnretained(self)
      .map { `self`, indexPath in
        self.selectedDay(at: indexPath)
      }
      .compactMap { $0 }
      .bind(to: cellTapSubject)
      .disposed(by: self.disposeBag)
  }

  private func configureWeekDayStickView() {
    [R.string.localizable.composeInquiryOrderProductCalendarSunday(),
     R.string.localizable.composeInquiryOrderProductCalendarMonday(),
     R.string.localizable.composeInquiryOrderProductCalendarTuesday(),
     R.string.localizable.composeInquiryOrderProductCalendarWednesday(),
     R.string.localizable.composeInquiryOrderProductCalendarThursday(),
     R.string.localizable.composeInquiryOrderProductCalendarFriday(),
     R.string.localizable.composeInquiryOrderProductCalendarSaturday()
    ].forEach {
      let weekDayLabel = UILabel()
      weekDayLabel.text = $0
      weekDayLabel.textColor = .kurlyGray800
      weekDayLabel.font = UIFont.system.regular(15)
      weekDayLabel.textAlignment = .center
      self.weekDayStackview.addArranged(weekDayLabel)
    }
  }

  // MARK: - layout
  private func addViews() {
    self.contentView.add(
      self.dateTextContainerView.with(
        self.yearAndDateLabel
      ),
      self.forwardArrowButton,
      self.backArrowButton,
      self.weekDayStackview,
      self.collectionView
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.dateTextContainerView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.centerX.equalToSuperview()
      make.size.equalTo(Metric.dateViewSize)
    }

    self.yearAndDateLabel.snp.makeConstraints { make in
      make.center.equalTo(self.dateTextContainerView)
    }

    self.forwardArrowButton.snp.makeConstraints { make in
      make.left.equalTo(self.dateTextContainerView.snp.right)
      make.centerY.equalTo(self.dateTextContainerView)
      make.size.equalTo(Metric.arrowSize)
    }

    self.backArrowButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.dateTextContainerView)
      make.right.equalTo(self.dateTextContainerView.snp.left)
      make.size.equalTo(Metric.arrowSize)
    }

    self.weekDayStackview.snp.makeConstraints { make in
      make.top.equalTo(self.dateTextContainerView.snp.bottom).offset(24)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(Metric.weekDayStackViewHeight)
    }

    self.collectionView.snp.makeConstraints { make in
      make.top.equalTo(self.weekDayStackview.snp.bottom).offset(7)
      make.leading.trailing.bottom.equalToSuperview()
    }
  }

  private func selectedDay(at indexPath: IndexPath) -> OneToOneInquiryCalendarDayItem? {
    let calendarDay = self.dataSource[indexPath]
    if calendarDay.selectStatus != .disabled {
      return calendarDay
    }
    return nil
  }
}

extension OneToOneInquiryCalendarMonthCell: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let initialCellSize = floor(collectionView.bounds.width / 7)
    let width: CGFloat = initialCellSize - 1
    let height: CGFloat = initialCellSize - 2
    return CGSize(width: width, height: height)
  }
}
