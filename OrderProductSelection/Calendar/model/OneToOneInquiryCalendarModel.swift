//
//  CalendarModel.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/06/09.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import Foundation

import RxDataSources

struct OneToOneInquiryCalendarMonthSection {
  var items: [OneToOneInquiryCalendarMonth]
}

extension OneToOneInquiryCalendarMonthSection: SectionModelType {
  typealias Item = OneToOneInquiryCalendarMonth

   init(original: OneToOneInquiryCalendarMonthSection, items: [OneToOneInquiryCalendarMonth]) {
    self = original
    self.items = items
  }
}

struct OneToOneInquiryCalendarMonth {
  let year: Int
  let month: Int
  let firstDate: Date
  let isForwardEnabled: Bool
  let isBackwardEnabled: Bool
  var days: [OneToOneInquiryCalendarDayItem]
}

struct OneToOneInquiryCalendarDaySection {
  var items: [OneToOneInquiryCalendarDayItem]
}

extension OneToOneInquiryCalendarDaySection: SectionModelType {
  typealias Item = OneToOneInquiryCalendarDayItem

   init(original: OneToOneInquiryCalendarDaySection, items: [OneToOneInquiryCalendarDayItem]) {
    self = original
    self.items = items
  }
}

struct OneToOneInquiryCalendarDayItem {
  enum SelectState {
    case selected
    case unSelected
    case disabled
  }

  let date: Date?
  let isEmptyCell: Bool
  let day: Int?
  var selectStatus: SelectState
}

struct OneToOneInquiryCalendarMonthParam {
  var existingMonths: [OneToOneInquiryCalendarMonth] = []
  let calendarType: OneToOneInquiryCalendarType
  let startDate: Date
  let endDate: Date
  var loadType: OneToOneInquiryCalendarReloadType = .reload
}

enum OneToOneInquiryCalendarType {
  case startDatePicker
  case endDatePicker
}

enum OneToOneInquiryCalendarScrollDirection {
  case forward
  case backward
}

enum OneToOneInquiryCalendarReloadType {
  case backward
  case forward
  case reload
}
