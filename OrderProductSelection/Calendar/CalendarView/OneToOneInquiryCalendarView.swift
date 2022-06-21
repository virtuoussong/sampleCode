//
//  OneToOneInquiryCalendarView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/03/07.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import UIKit

import ReusableKit
import ReactorKit
import RxSwift
import RxCocoa

final class OneToOneInquiryCalendarCollectionView: UICollectionView, View {
  var disposeBag: DisposeBag

  private enum Reusable {
    static let monthCell = ReusableCell<OneToOneInquiryCalendarMonthCell>()
  }

  private enum ScrollDirection {
    case left
    case right
  }

  private var scrollDirection: ScrollDirection {
    let contentOffsetX = self.contentOffset.x
    if self.previousContentOffset < contentOffsetX {
      return .right
    }
    return .left
  }
  private var previousContentOffset = 0.f
  private var contentOffsetBeforeReloading = CGPoint.zero

  private let directionTapSubject = PublishSubject<OneToOneInquiryCalendarScrollDirection>()
  private let dayCellTapSubject = PublishSubject<OneToOneInquiryCalendarDayItem>()
  private let scrollIndexSubject: PublishSubject<Int>

  init(
    reactor: OneToOneInquiryCalendarReactor,
    initialScrollIndexSubject: PublishSubject<Int>
  ) {
    self.disposeBag = DisposeBag()
    let layout = UICollectionViewFlowLayout().then {
      $0.scrollDirection = .horizontal
      $0.minimumLineSpacing = 0
    }
    self.scrollIndexSubject = initialScrollIndexSubject

    super.init(frame: .zero, collectionViewLayout: layout)

    self.dataSource = self
    self.delegate = self
    self.register(Reusable.monthCell)
    self.isPagingEnabled = true
    self.backgroundColor = .white
    self.showsHorizontalScrollIndicator = false
    self.alpha = 0

    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: OneToOneInquiryCalendarReactor) {
    self.input(reactor: reactor)
    self.output(reactor: reactor)
  }

  func input(reactor: OneToOneInquiryCalendarReactor) {
    Observable
      .of(
        self.rx.didEndDecelerating,
        self.rx.didEndScrollingAnimation
      )
      .merge()
      .observe(on: MainScheduler.asyncInstance)
      .filter(reactor.state.map { !$0.isLoading })
      .withLatestFrom(self.rx.contentOffset)
      .withUnretained(self)
      .map { `self`, contentOffset in
        self.requestLoadMoreDirection(contentOffset: contentOffset)
      }
      .filter { $0 != nil }
      .compactMap { $0 }
      .map { .loadMoreMonths($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.directionTapSubject
      .withUnretained(self)
      .subscribe { `self`, direction in
        self.didTapArrowButton(direction: direction)
      }
      .disposed(by: self.disposeBag)

    self.dayCellTapSubject
      .map { .selectDate(date: $0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.scrollIndexSubject
      .withUnretained(self)
      .subscribe { `self`, index in
        self.scrollToItem(at: index, isAnimated: false)
        self.animateVisibility()
      }
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$initialSelectedDayIndex)
      .withUnretained(self)
      .subscribe(onNext: { `self`, index in
        guard let `index` = index else { return }
        self.scrollToItem(at: index, isAnimated: false)
      }, onCompleted: {
        self.animateVisibility()
      })
      .disposed(by: self.disposeBag)

  }

  func output(reactor: OneToOneInquiryCalendarReactor) {
    reactor.pulse(\.$monthArray)
      .withUnretained(self)
      .subscribe { `self`, data in
        self.reloadData(
          reloadType: reactor.currentState.reloadType,
          newArray: data
        )
      }
      .disposed(by: self.disposeBag)
  }

  private func didTapArrowButton(direction: OneToOneInquiryCalendarScrollDirection) {
    guard let currentIndex = self.indexForVisibleCellInTheMiddle() else {
      return
    }

    var index = currentIndex.item
    switch direction {
    case .backward:
      index -= 1
      guard index >= 0 else {
        return
      }

    case .forward:
      index += 1
      guard index <= self.numberOfItems(inSection: 0) - 1 else {
        return
      }
    }

    self.scrollToItem(at: index)
  }

  private func animateVisibility() {
    UIView.animate(
      withDuration: 0.5,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 1,
      options: .curveEaseIn
    ) {
      self.alpha = 1
    }
  }

  private func scrollToItem(
    at index: Int,
    isAnimated: Bool = true
  ) {
    guard self.numberOfItems(inSection: 0) > 0,
          index < self.numberOfItems(inSection: 0) else {
      return
    }
    /*
     iOS 14에서 발생되는 버그.
     self.collectionView.isPagingEnabled = true 일때
     self.collectionView.scrollToItem 메서드가 정상 작동 되지 않습니다.
     https://developer.apple.com/forums/thread/663156
     이 버그에 대한 해결책으로 scrollToItem를 호출 하기 전에 self.collectionView.isPagingEnabled를 toggle 해 줍니다.
    */
    self.isPagingEnabled = false
      self.scrollToItem(
        at: IndexPath(item: index, section: 0),
        at: .centeredHorizontally,
        animated: isAnimated
      )
    self.isPagingEnabled = true
  }

  private func requestLoadMoreDirection(
    contentOffset: CGPoint
  ) -> OneToOneInquiryCalendarReloadType? {
    let scrollableWidth = self.contentSize.width - self.bounds.width
    let contentOffsetX = contentOffset.x

    var reloadType: OneToOneInquiryCalendarReloadType?

    if self.scrollDirection == .right && contentOffsetX > scrollableWidth * 0.75 {
      reloadType = .forward

    } else if self.scrollDirection == .left && contentOffsetX < scrollableWidth * 0.35 {
      self.contentOffsetBeforeReloading = self.contentOffset
      reloadType = .backward
    }

    self.previousContentOffset = contentOffsetX

    return reloadType
  }

  private func reloadData(
    reloadType: OneToOneInquiryCalendarReloadType,
    newArray: [OneToOneInquiryCalendarMonth]
  ) {
    switch reloadType {
    case .reload, .forward:
        self.reloadData()

    case .backward:
      let currentCellCount = self.numberOfItems(inSection: 0)
      let newDataCount = newArray.count
      let newItemCount = newDataCount - currentCellCount

      var indexPaths: [IndexPath] = []
      for i in 0..<newItemCount {
        indexPaths.append(IndexPath(item: i, section: 0))
      }

      let contentWidth = self.contentSize.width
      let offsetX = self.contentOffsetBeforeReloading.x
      let scrolledAmount = contentWidth - offsetX

      if indexPaths.count > 0 {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.performBatchUpdates {
          self.insertItems(at: indexPaths)
        } completion: { _ in
          let contentOffsetAfterReloading = self.contentSize.width - scrolledAmount
          self.contentOffset = CGPoint(
            x: contentOffsetAfterReloading,
            y: 0
          )
          CATransaction.commit()
        }
      }
    }
  }

  private func calculateMonthCellHeight() -> CGFloat {
    let topTitleLabelHeight = 44.f
    let weekViewHeight = 42.f
    let numberOfWeek = 7.f
    let numberOfMaxDayCellVertical = 6.f
    let cellHeight = self.bounds.width / numberOfWeek
    let monthViewOffset = 6.f
    let monthCollectionViewHeight = (cellHeight * numberOfMaxDayCellVertical) + monthViewOffset
    let total = topTitleLabelHeight + weekViewHeight + monthCollectionViewHeight
    return total
  }
}

extension OneToOneInquiryCalendarCollectionView: UICollectionViewDataSource {
  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    let count = self.reactor?.currentState.monthArray.count ?? 0
    return count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeue(Reusable.monthCell, for: indexPath)
    guard let item = self.reactor?.currentState.monthArray[indexPath.item] else {
      return cell
    }
    cell.configure(
      data: item,
      directionSubject: self.directionTapSubject,
      cellTapSubject: self.dayCellTapSubject
    )
    return cell
  }
}

extension OneToOneInquiryCalendarCollectionView: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let width = self.bounds.size.width
    let height = self.calculateMonthCellHeight()
    let size = CGSize(width: width, height: height)
    return size
  }
}
