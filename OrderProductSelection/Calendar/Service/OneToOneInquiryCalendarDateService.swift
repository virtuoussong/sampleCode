//
//  OneToOneInquiryCalendarDateService.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/02/09.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import Foundation
import RxSwift
import SwiftDate

protocol OneToOneInquiryCalendarDateService {
  func fetchMonths(
    parameter: OneToOneInquiryCalendarMonthParam
  ) -> Observable<[OneToOneInquiryCalendarMonth]>
}

final class OneToOneInquiryCalendarDateServiceImp: OneToOneInquiryCalendarDateService {
  private enum Constant {
    static let maxMonthsPeriodLimit = 6
    static let monthsInYear = 12
    static let backwardNumber = 5
  }

  struct MonthItem {
    let year: Int
    let month: Int
    let numberOfCell: Int
    let emptyCellCount: Int
    let firstDateOfTheMonth: Date
    let startDate: Date
    let calendarType: OneToOneInquiryCalendarType
    let selectedDate: Date
    let loadType: OneToOneInquiryCalendarReloadType
    let arrowEnability: ArrowEnablility
  }

  typealias ArrowEnablility = (isBackwardEnabled: Bool, isForwardEnabled: Bool)

  let dayMaker: OneToOneInquiryCalendarDayMaker

  init(dayMaker: OneToOneInquiryCalendarDayMaker) {
    self.dayMaker = dayMaker
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func fetchMonths(
    parameter: OneToOneInquiryCalendarMonthParam
  ) -> Observable<[OneToOneInquiryCalendarMonth]> {
    return Observable.create { emitter in
      self.makeMonthsAsync(parameter: parameter) {
        emitter.onNext($0)
        emitter.onCompleted()
      }
      return Disposables.create()
    }
  }

  private func makeMonthsAsync(
    parameter: OneToOneInquiryCalendarMonthParam,
    completion: @escaping ([OneToOneInquiryCalendarMonth]) -> Void
  ) {
    DispatchQueue.global(qos: .userInteractive).async {
      let monthArray = self.makeMonthArray(parameter: parameter)
      DispatchQueue.main.async {
        completion(monthArray)
      }
    }
  }

  private func makeMonthArray(
    parameter: OneToOneInquiryCalendarMonthParam
  ) -> [OneToOneInquiryCalendarMonth] {
    var months = parameter.existingMonths

    let initialDate = self.initialDateToMakeMonth(parameter: parameter)

    for i in 0..<Constant.monthsInYear {
      let addingMonth = initialDate.dateByAdding(i, .month)

      if let shouldContinue = self.monthMakerControlFlow(
        addingMonth: addingMonth,
        calendar: parameter.calendarType,
        startDate: parameter.startDate
      ) {
        if shouldContinue {
          continue
        } else {
          break
        }
      }

      let month = self.makeMonth(addingMonth: addingMonth, parameter: parameter)

      months.append(month)
    }

    months = months.sorted { lhm, rhm in
      lhm.firstDate < rhm.firstDate
    }

    return months
  }

  private func monthMakerControlFlow(
    addingMonth: DateInRegion,
    calendar type: OneToOneInquiryCalendarType,
    startDate: Date
  ) -> Bool? {
    let todayInRegion = Date().in(region: .current)
    let isAfterCurrentMonth = addingMonth.isAfterDate(todayInRegion, granularity: .month)
    if isAfterCurrentMonth {
      return false
    }

    switch type {
    case .startDatePicker:
      if self.isMonthOlderThanThreeYearsAgo(date: addingMonth.date) {
        return true
      }

    case .endDatePicker:
      let startDateInRegion = startDate.in(region: .current)
      let isBeforeStartDateMonth = addingMonth.isBeforeDate(startDateInRegion, granularity: .month)
      if isBeforeStartDateMonth {
        return true
      }

      let isAfterMonthLimit = startDate.isGreaterThanPeriodLimit(
        endDate: addingMonth.date,
        period: Constant.maxMonthsPeriodLimit,
        components: [.year, .day]
      )

      if isAfterMonthLimit {
        return false
      }
    }
    return nil
  }

  private func makeMonth(
    addingMonth: DateInRegion,
    parameter: OneToOneInquiryCalendarMonthParam
  ) -> OneToOneInquiryCalendarMonth {
    let monthData = self.makeMonthData(parameter: parameter, addingMonth: addingMonth)
    let daysOfMonth = self.dayMaker.makeDaysOfMonth(parameter: monthData)

    let month = OneToOneInquiryCalendarMonth(
      year: monthData.year,
      month: monthData.month,
      firstDate: monthData.firstDateOfTheMonth,
      isForwardEnabled: monthData.arrowEnability.isForwardEnabled,
      isBackwardEnabled: monthData.arrowEnability.isBackwardEnabled,
      days: daysOfMonth
    )

    return month
  }

  private func makeMonthData(
    parameter: OneToOneInquiryCalendarMonthParam,
    addingMonth: DateInRegion
  ) -> MonthItem {
    let numberOfDays = addingMonth.monthDays
    let firstDateOfTheMonth = addingMonth.dateAtStartOf(.month).date
    let firstWeekDayOftheMonth = addingMonth.calendar.component(.weekday, from: firstDateOfTheMonth)
    let selectedDate = parameter.calendarType == .startDatePicker ? parameter.startDate : parameter.endDate
    let arrowEnability = self.updateArrowEnability(addingMonth: addingMonth.date, parameter: parameter)

    /* firstWeekDayOftheMonth = 1 은 일요일. 1 부터 시작. */
    let emptyDayCellCount = firstWeekDayOftheMonth - 1
    let totalNumberOfCell = numberOfDays + emptyDayCellCount

    let monthData = MonthItem(
      year: addingMonth.year,
      month: addingMonth.month,
      numberOfCell: totalNumberOfCell,
      emptyCellCount: emptyDayCellCount,
      firstDateOfTheMonth: firstDateOfTheMonth,
      startDate: parameter.startDate,
      calendarType: parameter.calendarType,
      selectedDate: selectedDate,
      loadType: parameter.loadType,
      arrowEnability: arrowEnability
    )

    return monthData
  }

  private func initialDateToMakeMonth(parameter: OneToOneInquiryCalendarMonthParam) -> Date {
    var initialMonthDate = Date()
    let backwardCountfromInitialMonth = Constant.monthsInYear - Constant.backwardNumber

    switch parameter.loadType {
    case .backward:
      if let firstMonth = parameter.existingMonths.first {
        initialMonthDate = firstMonth.firstDate.dateByAdding(-(Constant.monthsInYear), .month).date
      }

    case .forward:
      if let lastMonth = parameter.existingMonths.last {
        initialMonthDate = lastMonth.firstDate.dateByAdding(1, .month).date
      }

    case .reload:
      switch parameter.calendarType {
      case .startDatePicker:
        initialMonthDate = parameter.startDate.dateByAdding(-(backwardCountfromInitialMonth), .month).date

      case .endDatePicker:
        let isEndAndStartDateInSameMonth = Calendar.current.isDate(
          parameter.startDate,
          equalTo: parameter.endDate,
          toGranularity: .month
        )

        if isEndAndStartDateInSameMonth {
          initialMonthDate = parameter.endDate
        } else {
          initialMonthDate = parameter.endDate.dateByAdding(-(backwardCountfromInitialMonth), .month).date
        }
      }
    }

    return initialMonthDate
  }

//  private func updateArrowEnability(parameter: ArrowEnabilityParameter) -> ArrowEnablility {
  private func updateArrowEnability(
    addingMonth: Date,
    parameter: OneToOneInquiryCalendarMonthParam
  ) -> ArrowEnablility {
    var isForwardEnabled = true
    var isBackwardEnabled = true

    let isCurrentMonth = Calendar.current.isDate(
      addingMonth,
      equalTo: Date(),
      toGranularity: .month
    )

    if isCurrentMonth {
      isForwardEnabled = false
    }

    if self.isMonthEqualToThreeYearsAgo(date: addingMonth) {
      isBackwardEnabled = false
    }

    let nextMonth = Calendar.current.date(
      byAdding: .month,
      value: 1,
      to: addingMonth
    )

    if let nextMonth = nextMonth, parameter.calendarType == .endDatePicker {
      let isNextMonthAfterMonthLimit = parameter.startDate.isGreaterThanPeriodLimit(
        endDate: nextMonth,
        period: Constant.maxMonthsPeriodLimit,
        components: [.month, .day]
      )

      if isNextMonthAfterMonthLimit {
        isForwardEnabled = false
      }

      let isAddingMonthAndStartMonthSame = Calendar.current.isDate(
        addingMonth,
        equalTo: parameter.startDate,
        toGranularity: .month
      )

      if isAddingMonthAndStartMonthSame {
        isBackwardEnabled = false
      }
    }

    return ArrowEnablility(isBackwardEnabled, isForwardEnabled)
  }

  private func isMonthEqualToThreeYearsAgo(date: Date) -> Bool {
    let threeYearsAgo = Date().dateByAdding(-3, .year).date
    if let threeYearsAgoFirstDate = threeYearsAgo.firstDateOfMonth(),
       let comparingDateMonthFirstDate = date.firstDateOfMonth() {
      if comparingDateMonthFirstDate == threeYearsAgoFirstDate {
        return true
      }
    }
    return false
  }

  private func isMonthOlderThanThreeYearsAgo(date: Date) -> Bool {
    let threeYearsAgo = Date().dateByAdding(-3, .year).date
    if let threeYearsAgoFirstDate = threeYearsAgo.firstDateOfMonth() {
      if date < threeYearsAgoFirstDate {
        return true
      }
    }
    return false
  }
}
