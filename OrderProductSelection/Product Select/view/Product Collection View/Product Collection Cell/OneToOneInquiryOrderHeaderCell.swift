//
//  OneToOneInquiryOrderHeaderCell.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/12/21.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReactorKit
import RxCocoa
import TrueTime

final class OneToOneInquiryOrderHeaderCell: BaseCollectionReusableView {
  // MARK: - Constant
  private enum Metric {
    static let markSize = CGSize(width: 24, height: 24)
    static let arrowSize = CGSize(width: 20, height: 20)
  }

  // MARK: - UI Component
  private let checkMarkButton = InquiryProductCheckButton(frame: .zero)

  private let dateLabel = UILabel().then {
    $0.font = UIFont.system.medium(15)
    $0.textColor = .kurlyGray800
  }

  private let orderNumberLabel = UILabel().then {
    $0.font = UIFont.system.medium(12)
    $0.textColor = .kurlyGray450
    $0.textAlignment = .left
  }

  private let arrowImageView = AnimatingArrowView()

  fileprivate let expandButton = UIButton()

  // MARK: - Properties
  var indexPath = IndexPath(item: 0, section: 0)
  var calculatedProductHeight = 0.f
  var isExpaned = false

  // MARK: - Life Cycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = .white
    self.addSubView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryOrderHeaderCell")
  }

  func configure(
    indexPath: IndexPath,
    data: OneToOneInquiryOrderSection,
    expandTapSubject: PublishSubject<IndexPath>,
    checkMarkTapSubject: PublishSubject<IndexPath>
  ) {    
    self.checkMarkButton.checkState = data.selectionState
    self.dateLabel.text = data.orderedDate
    let orderNumberText = R.string.localizable.composeInquiryOrderProductNumber()
    self.orderNumberLabel.text = "\(orderNumberText) \(data.orderNo)"
    self.arrowImageView.updateIsOpened(data.isExpanded, animated: false)
    self.indexPath = indexPath

    self.expandButton.rx.tap
      .do(onNext: { [weak self] _ in
        self?.arrowImageView.toggleIsOpened()
      })
      .map { indexPath }
      .bind(to: expandTapSubject)
      .disposed(by: self.disposeBag)

    self.checkMarkButton.rx.tap
      .map { indexPath }
      .bind(to: checkMarkTapSubject)
      .disposed(by: self.disposeBag)
  }

  // MARK: - Layout
  private func addSubView() {
    self.add(
      self.checkMarkButton,
      self.dateLabel,
      self.orderNumberLabel,
      self.arrowImageView,
      self.expandButton
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.checkMarkButton.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.leading.equalToSuperview().offset(20)
      make.size.equalTo(Metric.markSize)
    }

    self.dateLabel.snp.makeConstraints { make in
      make.centerY.equalTo(self.checkMarkButton)
      make.leading.equalTo(self.checkMarkButton.snp.trailing).offset(12)
      make.width.equalTo(84)
    }

    self.orderNumberLabel.snp.makeConstraints { make in
      make.centerY.equalTo(self.dateLabel)
      make.leading.equalTo(self.dateLabel.snp.trailing).offset(4)
      make.trailing.equalTo(self.arrowImageView.snp.leading).offset(20)
    }

    self.arrowImageView.snp.makeConstraints { make in
      make.centerY.equalTo(self.checkMarkButton)
      make.trailing.equalToSuperview().inset(20)
    }

    self.expandButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.checkMarkButton)
      make.trailing.equalToSuperview()
      make.leading.equalTo(self.orderNumberLabel)
    }
  }
}
