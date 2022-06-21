//
//  OneToOneInquiryProductFooterCell.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/12/24.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

import ReactorKit
import RxCocoa

final class OneToOneInquiryProductFooterCell: BaseCollectionReusableView {
  private enum Text {
    static let viewMore = R.string.localizable.composeInquiryOrderProductGuideListIncrease()
    static let collapse = R.string.localizable.composeInquiryOrderProductGuideListDecrease()
  }

  private let buttonContainerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let titleLabel = UILabel().then {
    $0.font = UIFont.system.regular(14)
    $0.textColor = .kurly.gray450
  }

  private let cellTapButton = UIButton()

  private var isExpandedWithAllProducts = false

  private var arrowAttributedString: NSMutableAttributedString {
    let downArrowImage = R.image.on1InquiryIcArrowMore()
    let upArrowImage = R.image.orderIcArrowUp()

    let imageAttachment = NSTextAttachment()
    imageAttachment.bounds = CGRect(x: 2, y: -4.5, width: 18, height: 18)

    let string: String
    if isExpandedWithAllProducts {
      string = Text.collapse
      imageAttachment.image = upArrowImage
    } else {
      string = Text.viewMore
      imageAttachment.image = downArrowImage
    }

    let attachmentString = NSAttributedString(attachment: imageAttachment)
    let mutatedString = NSMutableAttributedString(string: string)
    mutatedString.append(attachmentString)

    return mutatedString
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = .kurly.bg
    self.clipsToBounds = true
    self.addSubView()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 OneToOneInquiryProductFooterCell")
  }

  private func addSubView() {
    self.add(
      self.buttonContainerView.with(
        self.titleLabel,
        self.cellTapButton
      )
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.buttonContainerView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.height.equalTo(48)
    }

    self.titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.centerX.equalToSuperview()
    }

    self.cellTapButton.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  func configure(
    index: Int,
    data: OneToOneInquiryOrderSection,
    tapSubject: PublishSubject<Int>,
    isTheLast: Bool
  ) {
    self.cellTapButton.rx.tap
      .map { index }
      .bind(to: tapSubject)
      .disposed(by: self.disposeBag)

    self.isExpandedWithAllProducts = data.isAllProductsShown
    self.titleLabel.attributedText = self.arrowAttributedString
    
    if data.totalProductCount > 3 && data.isExpanded {
      self.buttonContainerView.isHidden = false
    } else {
      self.buttonContainerView.isHidden = true
    }

    if isTheLast {
      self.backgroundColor = .white
    } else {
      self.backgroundColor = .kurly.bg
    }
  }
}
