//
//  OneToOneInquiryDateDetailButton.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/01/07.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import UIKit

final class OneToOneInquiryDateDetailButton: UIButton {

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.configureComponents()
    self.configureLayer()
    self.makeConstraint()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func configureComponents() {
    self.setTitle("", for: .normal)
    self.titleLabel?.font = UIFont.system.bold(14)
    self.setTitleColor(.kurly.gray800, for: .normal)

    self.setImage(R.image.on1InquiryIconCalendar(), for: .normal)
    self.setImageSide(side: .right)

    self.contentHorizontalAlignment = .left
    self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
  }

  private func configureLayer() {
    self.layer.borderColor = UIColor.kurly.lightGray.withAlphaComponent(0.5).cgColor
    self.layer.cornerRadius = 3
    self.layer.borderWidth = 1
  }

  private func makeConstraint() {
    self.imageView?.snp.remakeConstraints { make in
      make.right.equalTo(self.snp.right).inset(8)
      make.centerY.equalTo(self)
      make.size.equalTo(CGSize(width: 24, height: 24))
    }
  }
}
