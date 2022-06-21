//
//  CalendatDateCell.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/09.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import UIKit

final class OneToOneInquiryCalendarDayCell: BaseCollectionViewCell {

  private let dateLabel = UILabel().then {
    $0.font = UIFont.system.regular(15)
  }

  private let purpleCircleView = UIView().then {
    $0.backgroundColor = .presetToolTip
    $0.isHidden = true
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.contentView.backgroundColor = .white
    self.addViews()
    self.configureComponents()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    DLog.verbose("👋 CalendarDateCell")
  }

  // MARK: - Configuration
  private func configureComponents() {
    self.purpleCircleView.layer.cornerRadius = self.contentView.bounds.size.height / 2
  }

  // MARK: - Layout
  private func addViews() {
    self.contentView.add(
      self.purpleCircleView,
      self.dateLabel
    )
  }

  override func makeConstraints() {
    super.makeConstraints()
    self.purpleCircleView.snp.makeConstraints { make in
      make.size.equalToSuperview()
    }
    self.dateLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }

  func configure(data: OneToOneInquiryCalendarDayItem) {
    if !data.isEmptyCell {
      if let dayNumber = data.day {
        self.dateLabel.text = "\(dayNumber)"
      }
    } else {
      self.dateLabel.text = nil
    }

    switch data.selectStatus {
    case .selected:
      self.purpleCircleView.isHidden = false
      self.dateLabel.textColor = .white
      self.dateLabel.font = UIFont.system.bold(15)

    case .unSelected:
      self.purpleCircleView.isHidden = true
      self.dateLabel.textColor = .kurly.gray800
      self.dateLabel.font = UIFont.system.regular(15)

    case .disabled:
      self.purpleCircleView.isHidden = true
      self.dateLabel.textColor = .kurly.gray350
      self.dateLabel.font = UIFont.system.regular(15)
    }
  }
}
