//
//  OrderedListCell.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/07.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReactorKit
import RxCocoa

final class OneToOneInquiryProductCell: BaseCollectionViewCell {
  // MARK: - Constant
  private enum Metric {
    static let markSize = CGSize(width: 24, height: 24)
    static let productImgSize = CGSize(width: 50, height: 50)
  }

  // MARK: - UI Components
  private let checkMarkButton = InquiryProductCheckButton(frame: .zero)

  private let productImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
    $0.layer.cornerRadius = 4
    $0.image = R.image.noimgLogoHomeMD()
    $0.backgroundColor = .kurly.lightGray
  }

  private let descriptionStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 4
  }

  private let titleLabel = UILabel().then {
    $0.font = UIFont.system.regular(14)
    $0.textColor = .kurly.gray800
  }

  private let subTitleLabel = UILabel().then {
    $0.font = UIFont.system.regular(12)
    $0.textColor = .kurly.gray450
  }

  private let priceAndCountView = UIView()

  private let priceLabel = UILabel().then {
    $0.font = UIFont.system.bold(14)
    $0.textColor = .kurly.gray800
  }

  private let quantityLabel = UILabel().then {
    $0.font = UIFont.system.regular(13)
    $0.textColor = .kurly.gray600
  }

  private let priceAndCountLineView = UIView().then {
    $0.backgroundColor = .kurly.gray250
  }

  // MARK: - Property
  private(set) var data: OneToOneInquiryProduct?

  // MARK: - Initialization
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.contentView.backgroundColor = .white
    self.contentView.clipsToBounds = true
    self.addViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryProductCell")
  }

  // MARK: - Configuration
  func configure(
    indexPath: IndexPath,
    selectionType: OneToOneInquiryOrderType,
    data: OneToOneInquiryProduct,
    checkMarkTapSubject: PublishSubject<IndexPath>
  ) {
    if selectionType == .all {
      let checkState: CheckMarkState = data.selectionState == .checked ? .checkDisabled : .disabled
      self.checkMarkButton.checkState = checkState
    } else {
      self.checkMarkButton.checkState = data.selectionState
      self.checkMarkButton.rx.tap
        .map { indexPath }
        .bind(to: checkMarkTapSubject)
        .disposed(by: self.disposeBag)
    }

    self.productImageView.kf.setImage(with: URL(string: data.imageUrl))

    self.titleLabel.text = data.dealProductName

    if let subTitle = data.contentsProductName {
      self.subTitleLabel.isHidden = false
      self.subTitleLabel.text = subTitle
      self.descriptionStackView.setCustomSpacing(4, after: self.titleLabel)
      self.descriptionStackView.setCustomSpacing(8, after: self.subTitleLabel)
    } else {
      self.subTitleLabel.isHidden = true
      self.subTitleLabel.text = nil
      self.descriptionStackView.setCustomSpacing(8, after: self.titleLabel)
    }

    if let amount = data.paymentAmount.currencyFormatted() {
      self.priceLabel.text = amount
    }

    self.priceLabel.snp.remakeConstraints { make in
      make.width.equalTo(self.priceLabel.intrinsicContentSize.width)
    }

    let quantity = data.quantity
    self.quantityLabel.text = R.string.localizable.composeInquiryOrderProductAmount(quantity)

  }

  // MARK: Layout
  private func addViews() {
    self.contentView.add(
      self.checkMarkButton,
      self.productImageView,
      self.descriptionStackView.withArranged(
        self.titleLabel,
        self.subTitleLabel,
        self.priceAndCountView.with(
          self.priceLabel,
          self.priceAndCountLineView,
          self.quantityLabel
        )
      )
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.checkMarkButton.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(20)
      make.top.equalToSuperview().offset(23)
      make.size.equalTo(Metric.markSize)
    }

    self.productImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.leading.equalTo(self.checkMarkButton.snp.trailing).offset(12)
      make.size.equalTo(Metric.productImgSize)
    }

    self.descriptionStackView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(12)
      make.leading.equalTo(self.productImageView.snp.trailing).offset(16)
      make.trailing.equalToSuperview().inset(20)
    }

    self.priceAndCountView.snp.makeConstraints { make in
      make.height.equalTo(20)
    }

    self.priceLabel.snp.makeConstraints { make in
      make.top.leading.equalTo(self.priceAndCountView)
    }

    self.priceAndCountLineView.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 1, height: 10))
      make.leading.equalTo(self.priceLabel.snp.trailing).offset(6)
      make.centerY.equalTo(self.priceLabel.snp.centerY)
    }

    self.quantityLabel.snp.makeConstraints { make in
      make.leading.equalTo(self.priceAndCountLineView.snp.trailing).offset(6)
      make.centerY.equalTo(self.priceLabel.snp.centerY)
    }
  }

  static func cellHeight(
    item: OneToOneInquiryProduct,
    isTheLast: Bool
  ) -> CGFloat {
    var height = 70.f
    if item.contentsProductName != nil {
      height += 14.f
    }
    if isTheLast {
      height += 14.f
    }
    return height
  }
}
