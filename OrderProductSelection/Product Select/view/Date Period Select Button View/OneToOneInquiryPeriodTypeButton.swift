//
//  OneToOneInquiryPeriodSelectButton.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/01/06.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import UIKit

final class OneToOneInquiryPeriodTypeButton: UIButton {
  let type: OneToOneInquiryPeriodButtonType
  private let selectedLayerColor = UIColor.kurly.purple.cgColor
  private let normalLayerColor = UIColor.kurly.lightGray.withAlphaComponent(0.5).cgColor

  override var isSelected: Bool {
    didSet {
      self.updateColorSettings()
    }
  }

  override var isHighlighted: Bool {
    didSet {
      self.alpha = self.isHighlighted ? 0.5 : 1
    }
  }

  init(type: OneToOneInquiryPeriodButtonType) {
    self.type = type
    super.init(frame: .zero)
    self.setTitle(type.text, for: .normal)
    self.configureButtonStyle()
    self.updateColorSettings()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func configureButtonStyle() {
    self.clipsToBounds = true
    self.layer.cornerRadius = 3
    self.layer.borderWidth = 1
    self.titleLabel?.font = UIFont.system.regular(14)
    self.setTitleColor(.kurly.gray600, for: .normal)
    self.setTitleColor(.kurly.purple, for: .selected)
  }

  private func updateColorSettings() {
    self.layer.borderColor = self.isSelected ? self.selectedLayerColor : self.normalLayerColor
  }
}
