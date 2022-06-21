//
//  OrderedProductSelectCollectionView.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/03.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReusableKit
import ReactorKit
import Differentiator

final class OneToOneInquiryProductCollectionView: UICollectionView, View {
  var disposeBag: DisposeBag

  private enum Metric {
    static let horizontalPadding = 20.f
  }

  private enum Reusable {
    static let headerCell = ReusableView<OneToOneInquiryOrderHeaderCell>()
    static let cell = ReusableCell<OneToOneInquiryProductCell>()
    static let footer = ReusableView<OneToOneInquiryProductFooterCell>()
  }

  let expandTapSubject = PublishSubject<IndexPath>()
  let headerCheckMarkTapSubject = PublishSubject<IndexPath>()
  let productCheckMarkTapSubject = PublishSubject<IndexPath>()
  let viewMoreTapSubject = PublishSubject<Int>()

  // MARK: - Life Cycle
  init(reactor: OneToOneInquiryProductSelectReactor) {
    let flowLayout = UICollectionViewFlowLayout().then {
      $0.minimumLineSpacing = 4
    }
    self.disposeBag = DisposeBag()

    super.init(frame: .zero, collectionViewLayout: flowLayout)
    self.configureCollectionView()
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryProductCollectionView")
  }

  private func configureCollectionView() {
    self.dataSource = self
    self.delegate = self
    self.backgroundColor = .white
    self.contentInset = UIEdgeInsets(top: 3, left: 0, bottom: 110, right: 0)
    self.keyboardDismissMode = .onDrag
    self.register(Reusable.headerCell, kind: .header)
    self.register(Reusable.footer, kind: .footer)
    self.register(Reusable.cell)
  }

  func bind(reactor: OneToOneInquiryProductSelectReactor) {
    self.input(reactor: reactor)
    self.output(reactor: reactor)
  }

  func input(reactor: OneToOneInquiryProductSelectReactor) {
    reactor.pulse(\.$isReloadDataNeeded)
      .filter { $0 }
      .withUnretained(self)
      .subscribe { `self`, _ in
        self.reloadData()
      }
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$reloadingSectionIndexSet)
      .withUnretained(self)
      .subscribe { `self`, sections in
        self.reloadSections(indexSet: sections)
      }
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$isScrollToTopNeeded)
      .filter { $0 }
      .withUnretained(self)
      .subscribe { `self`, _ in
        self.setContentOffset(CGPoint.zero, animated: false)
      }
      .disposed(by: self.disposeBag)

    reactor.pulse(\.$indexForViewMoreProducts)
      .withUnretained(self)
      .subscribe { `self`, index in
        if let index = index {
          self.reloadSections(indexSet: IndexSet(integer: index))
        }
      }
      .disposed(by: self.disposeBag)
  }

  func output(reactor: OneToOneInquiryProductSelectReactor) {
    self.rx.didScroll
      .debounce(.microseconds(300), scheduler: MainScheduler.asyncInstance)
      .withLatestFrom(self.rx.contentOffset)
      .filter(reactor.state.map { !$0.isLoadingNextPage })
      .withUnretained(self)
      .filter { `self`, contentOffset in
        let offset = self.contentSize.height - self.bounds.height
        return contentOffset.y > offset * 0.75
      }
      .map { _ in .loadMoreSection }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.expandTapSubject
      .map { .updateExpansionState($0.section) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.headerCheckMarkTapSubject
      .map { .updateSectionSelectState($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.productCheckMarkTapSubject
      .map { .updateItemSelectedState($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.viewMoreTapSubject
      .map { .loadMoreProducts($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
  }

  private func reloadSections(indexSet: IndexSet) {
    guard let minIndex = indexSet.min(),
          let maxIndex = indexSet.max(),
          minIndex < self.numberOfSections,
          maxIndex < self.numberOfSections else {
      return
    }
    self.reloadSections(indexSet)
  }
}

extension OneToOneInquiryProductCollectionView: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    referenceSizeForHeaderInSection section: Int
  ) -> CGSize {
    let width = self.bounds.width
    let cellHeight = 48.f

    return CGSize(width: width, height: cellHeight)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    referenceSizeForFooterInSection section: Int
  ) -> CGSize {
    let width = self.bounds.width
    guard let sections = self.reactor?.currentState.workingOrderSections else {
      return CGSize(width: width, height: 8)
    }

    let data = sections[section]
    let footerHeight: CGFloat

    if data.totalProductCount > 3 && data.isExpanded {
      footerHeight = 56
    } else {
      footerHeight = 8
    }

    return CGSize(width: width, height: footerHeight)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    var height = 70.f
    let width = self.bounds.width

    guard let sections = self.reactor?.currentState.workingOrderSections,
          indexPath.section <= sections.count - 1 else {
      return CGSize(width: width, height: height)
    }

    let section = sections[indexPath.section]
    guard indexPath.item <= section.items.count - 1 else {
      return CGSize(width: width, height: height)
    }

    let item = section.items[indexPath.item]

    let isTheLastSectionCell: Bool
    if indexPath.section == section.items.count - 1 &&
       indexPath.item == section.items.count - 1 {
      isTheLastSectionCell = true
    } else {
      isTheLastSectionCell = false
    }

    height = Reusable.cell.class.cellHeight(
      item: item,
      isTheLast: isTheLastSectionCell
    )

    return CGSize(width: width, height: height)
  }
}

extension OneToOneInquiryProductCollectionView: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    let count = self.reactor?.currentState.workingOrderSections.count ?? 0
    return count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    guard let sections = self.reactor?.currentState.workingOrderSections else {
      return 0
    }

    return sections[section].items.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeue(Reusable.cell, for: indexPath)

    if let sections = self.reactor?.currentState.workingOrderSections,
        indexPath.section < sections.count {
      let section = sections[indexPath.section]
      let items = section.items
      if indexPath.item < items.count {
        let item = items[indexPath.item]
        cell.configure(
          indexPath: indexPath,
          selectionType: section.selectionType,
          data: item,
          checkMarkTapSubject: self.productCheckMarkTapSubject
        )
      }
    }

    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    guard let reactor = self.reactor else {
      return UICollectionReusableView()
    }
    let orderSections = reactor.currentState.workingOrderSections
    let orderSection = orderSections[indexPath.section]

    switch kind {
    case UICollectionView.elementKindSectionHeader:
      let headerCell = collectionView.dequeue(
        Reusable.headerCell,
        kind: .header,
        for: indexPath
      )

      headerCell.configure(
        indexPath: indexPath,
        data: orderSection,
        expandTapSubject: self.expandTapSubject,
        checkMarkTapSubject: self.headerCheckMarkTapSubject
      )

      return headerCell

    case UICollectionView.elementKindSectionFooter:
      let footerCell = collectionView.dequeue(
        Reusable.footer,
        kind: .footer,
        for: indexPath
      )

      let isTheLastSection = orderSections.count - 1 == indexPath.section

      footerCell.configure(
        index: indexPath.section,
        data: orderSection,
        tapSubject: self.viewMoreTapSubject,
        isTheLast: isTheLastSection
      )

      return footerCell

    default:
      fatalError()
    }
  }
}
