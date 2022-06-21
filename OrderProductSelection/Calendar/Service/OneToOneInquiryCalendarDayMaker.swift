//
//  OneToOneInquiryCalendarDayMaker.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/03/10.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import Foundation

final class OneToOneInquiryCalendarDayMaker {
  typealias MonthItem = OneToOneInquiryCalendarDateServiceImp.MonthItem
  typealias SelectState = OneToOneInquiryCalendarDayItem.SelectState

  func makeDaysOfMonth(parameter: MonthItem) -> [OneToOneInquiryCalendarDayItem] {
    var dates: [OneToOneInquiryCalendarDayItem] = []

    var dayInt = 1
    for i in 0..<parameter.numberOfCell {
      let isEmptyDateCell = i < parameter.emptyCellCount ? true : false
      var createdDate: Date?
      var dayString = ""
      let dayNumber = dayInt

      if !isEmptyDateCell {
        dayString = "\(parameter.year)-\(parameter.month)-\(dayInt)"
        createdDate = Date(dayString)?.dateWithLocalEndTime
        dayInt += 1
      }

      let selectState = self.daySelectState(
        createdDate: createdDate ?? Date(),
        parameter: parameter,
        isEmptyDateCell: isEmptyDateCell
      )

      let dayItem = OneToOneInquiryCalendarDayItem(
        date: createdDate,
        isEmptyCell: isEmptyDateCell,
        day: dayNumber,
        selectStatus: selectState
      )

      dates.append(dayItem)
    }

    return dates
  }

  private func daySelectState(
    createdDate: Date,
    parameter: MonthItem,
    isEmptyDateCell: Bool
  ) -> SelectState {
    if parameter.loadType == .reload {
      let isTheSelectedDate = Calendar.current.isDate(createdDate, inSameDayAs: parameter.selectedDate)
      if !isEmptyDateCell && isTheSelectedDate {
        return .selected
      }
    }

    let isGreaterThanPeriodLimit = parameter.startDate.isGreaterThanPeriodLimit(
      endDate: createdDate,
      period: 6,
      components: [.month, .day]
    )

    let isBeforeStartDay = parameter.startDate > createdDate

    if self.isAfterToday(date: createdDate) ||
       self.isDateOlderThanThreeYearsAgo(date: createdDate) ||
       (parameter.calendarType == .endDatePicker && isGreaterThanPeriodLimit) ||
       (parameter.calendarType == .endDatePicker && isBeforeStartDay) ||
       isEmptyDateCell {
      return .disabled
    }

    return .unSelected
  }

  private func isAfterToday(
    date: Date
  ) -> Bool {
    let today = Date().dateWithLocalEndTime ?? Date()
    if date.isAfterDate(today, granularity: .day) {
      return true
    }

    return false
  }

  private func isDateOlderThanThreeYearsAgo(date: Date) -> Bool {
    let threeYearsAgo = Date().dateByAdding(-3, .year).date
    if date < threeYearsAgo {
      return true
    }

    return false
  }
}
