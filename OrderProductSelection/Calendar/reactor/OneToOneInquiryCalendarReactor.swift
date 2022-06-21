//
//  CalendarReactor.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/01/10.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import Foundation

import ReactorKit
import RxSwift
import SwiftDate
import TrueTime

final class OneToOneInquiryCalendarReactor: Reactor {
  enum Metric {
    static let maxMonthsPeriodLimit = 6
  }

  enum Action {
    case loadInitialMonths
    case loadMoreMonths(OneToOneInquiryCalendarReloadType)
    case selectDate(date: OneToOneInquiryCalendarDayItem)
  }

  enum Mutation {
    case setIsLoading(Bool)
    case setInitialMonthArray([OneToOneInquiryCalendarMonth])
    case setMoreLoadedMonths([OneToOneInquiryCalendarMonth])
    case setReloadType(OneToOneInquiryCalendarReloadType)
    case setSelectedCell(OneToOneInquiryCalendarDayItem)
    case setIsConfirmEnabled
  }

  // MARK: State
  struct State {
    @Pulse var monthArray: [OneToOneInquiryCalendarMonth] = []
    @Pulse var initialSelectedDayIndex: Int?
    var calendarType: OneToOneInquiryCalendarType = .startDatePicker
    var startDate = Date()
    var endDate = Date()
    var newDayItem: OneToOneInquiryCalendarDayItem?
    var isLoading = false
    @Pulse var reloadType: OneToOneInquiryCalendarReloadType = .reload
    @Pulse var isConfirmButtonEabled = true
  }

  var initialState = State()

  private let calendarService: OneToOneInquiryCalendarDateService

  // MARK: Init
  init(
    calendarService: OneToOneInquiryCalendarDateService,
    selectType: OneToOneInquiryCalendarType,
    period dates: OneToOneInquiryDatePeriod
  ) {
    self.calendarService = calendarService
    self.initialState.calendarType = selectType
    self.initialState.startDate = dates.startDate
    self.initialState.endDate = dates.endDate
    self.action.onNext(.loadInitialMonths)
  }

  // MARK: Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .loadInitialMonths:
      return .concat(
        .just(.setReloadType(.reload)),
        self.loadInitialMonthArray()
      )

    case .loadMoreMonths(let type):
      return .concat(
          .just(.setIsLoading(true)),
          .just(.setReloadType(type)),
          self.loadMoreMonths(type: type)
        )

    case .selectDate(let date):
      return .merge(
        .just(.setReloadType(.reload)),
        .just(.setSelectedCell(date)),
        .just(.setIsConfirmEnabled)
      )
    }
  }

  // MARK: Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state

    switch mutation {
    case .setInitialMonthArray(let monthArray):
      newState.monthArray = monthArray
      if let selectedMonthIndex = self.indexForTheSelectedDay(
        type: state.calendarType,
        months: monthArray
      ) {
        newState.initialSelectedDayIndex = selectedMonthIndex
      }

    case .setMoreLoadedMonths(let monthArray):
      newState.monthArray = monthArray
      newState.isLoading = false

    case .setSelectedCell(let selectedDayItem):
      let datePeriodUpdatedState = self.calculateNewDatePeriod(
        selectedDayItem: selectedDayItem,
        state: newState
      )
      newState.startDate = datePeriodUpdatedState.startDate
      newState.endDate = datePeriodUpdatedState.endDate
      newState.newDayItem = datePeriodUpdatedState.newDayItem
      newState.monthArray = self.updateDaySelectState(state: datePeriodUpdatedState)

    case .setIsLoading(let isLoading):
      newState.isLoading = isLoading

    case .setReloadType(let reloadType):
      newState.reloadType = reloadType

    case .setIsConfirmEnabled:
      newState.isConfirmButtonEabled = self.updateIsConfirmEnabled(months: newState.monthArray)
    }

    return newState
  }

  // MARK: Load Calendar
  private func loadInitialMonthArray() -> Observable<Mutation> {
    let parameter = OneToOneInquiryCalendarMonthParam(
      calendarType: self.currentState.calendarType,
      startDate: self.currentState.startDate,
      endDate: self.currentState.endDate
    )

    let monthArray = self.calendarService.fetchMonths(parameter: parameter)
      .map { months -> Mutation in
        Mutation.setInitialMonthArray(months)
      }

    return monthArray
  }

  private func loadMoreMonths(
    type: OneToOneInquiryCalendarReloadType
  ) -> Observable<Mutation> {
    let parameter = OneToOneInquiryCalendarMonthParam(
      existingMonths: self.currentState.monthArray,
      calendarType: self.currentState.calendarType,
      startDate: self.currentState.startDate,
      endDate: self.currentState.endDate,
      loadType: type
    )

    let months = self.calendarService.fetchMonths(parameter: parameter)
      .filter { $0.count > 0 }
      .map { months -> Mutation in
        Mutation.setMoreLoadedMonths(months)
      }

    return months
  }

  private func indexForTheSelectedDay(
    type: OneToOneInquiryCalendarType,
    months: [OneToOneInquiryCalendarMonth]
  ) -> Int? {
    let comparingDate = type == .startDatePicker ? self.currentState.startDate : self.currentState.endDate

    let monthIndex = months.firstIndex { month in
      return Calendar.current.isDate(
        month.firstDate,
        equalTo: comparingDate,
        toGranularity: .month
      )
    }

    return monthIndex
  }

  private func updateDaySelectState(state: State) -> [OneToOneInquiryCalendarMonth] {
    let updatedArray = state.monthArray.map { month -> OneToOneInquiryCalendarMonth in
      var copiedMonth = month
      let copiedDays = copiedMonth.days.map { day -> OneToOneInquiryCalendarDayItem in
        var copiedDay = day

        if day.date == state.newDayItem?.date {
          let status: OneToOneInquiryCalendarDayItem.SelectState =
          day.selectStatus == .selected ? .unSelected : .selected
          copiedDay.selectStatus = status
        } else if day.selectStatus == .selected {
          copiedDay.selectStatus = .unSelected
        }

        return copiedDay
      }
      
      copiedMonth.days = copiedDays

      return copiedMonth
    }

    return updatedArray
  }

  // MARK: Date Comparison
  private func calculateNewDatePeriod(
    selectedDayItem: OneToOneInquiryCalendarDayItem,
    state: State
  ) -> State {
    var newState = state

    newState.newDayItem = selectedDayItem
    guard let newSelectedDate = selectedDayItem.date else {
      return newState
    }

    switch state.calendarType {
    case .startDatePicker:
      newState.startDate = newSelectedDate

      let today = Date().dateWithLocalEndTime ?? Date()
      var newEndDate = newSelectedDate.dateByAdding(6, .month).date
      if newEndDate >= today {
        newEndDate = today
      }
      newState.endDate = newEndDate.dateWithLocalEndTime ?? newEndDate

    case .endDatePicker:
      newState.endDate = newSelectedDate
    }

    return newState
  }

  private func isGreaterThanPeriodLimit(
    startDate: Date,
    endDate: Date,
    period limit: Int = Metric.maxMonthsPeriodLimit
  ) -> Bool {
    guard let endDate = endDate.dateWithLocalEndTime else {
      return false
    }

    let dateDifference = Calendar.current.dateComponents(
      [.month, .day],
      from: startDate,
      to: endDate
    )

    guard let monthDifference = dateDifference.month,
          let dayDifference = dateDifference.day else {
      return false
    }

    if monthDifference <= limit {
      if monthDifference == limit {
        if abs(dayDifference) < 1 {
          return false
        } else {
          return true
        }
      }

      return false

    } else {
      return true
    }
  }

  private func isNewStartDateEqualOrPassedEndDate(
    startDate: Date,
    endDate: Date
  ) -> Bool {
    let bool = startDate >= endDate ? true : false
    return bool
  }

  private func updateIsConfirmEnabled(months: [OneToOneInquiryCalendarMonth]) -> Bool {
    let isDaySelected = months.contains { month in
      month.days.contains { day in
        day.selectStatus == .selected
      }
    }
    return isDaySelected
  }
}
