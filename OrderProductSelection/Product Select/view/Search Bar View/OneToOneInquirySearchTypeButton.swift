//
//  OneToOneInquirySearchTypeButton.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/12/21.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

final class OneToOneInquirySearchTypeButton: BaseControl {
  private let titleLabel = UILabel().then {
    $0.font = UIFont.system.regular(14)
  }

  private let imageView = UIImageView().then {
    $0.image = R.image.icSortingArrowDown()
  }

  override var isHighlighted: Bool {
    didSet {
      let alpha = self.isHighlighted ? 0.5 : 1
      self.backgroundColor = .kurly.bgLightGray.withAlphaComponent(alpha)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = .kurly.bgLightGray
    self.addSubView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func addSubView() {
    self.add(
      self.titleLabel,
      self.imageView
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.titleLabel.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.leading.equalTo(12)
    }

    self.imageView.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.trailing.equalTo(-14)
    }
  }

  func set(title: String) {
    self.titleLabel.text = title
  }
}
