//
//  OneToOneInquiryProductSelectReactor.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2021/12/28.
//  Copyright © 2021 com.kurly. All rights reserved.
//

import Foundation

import ReactorKit
import RxSwift
import RxCocoa

final class OneToOneInquiryProductSelectReactor: Reactor {
  enum Metric {
    static let viewMoreLimitCount = 3
  }

  // MARK: Action
  enum Action {
    case setDefaultSearchTerms
    case loadSavedSearchTerms(OneToOneInquiryOrderSelectionState)
    case selectPeriodType(OneToOneInquiryPeriodButtonType)
    case selectPeriodDates(OneToOneInquiryDatePeriod)
    case selectSearchType(OneToOneInquirySearchType)
    case updateExpansionState(Int)
    case updateSectionSelectState(IndexPath)
    case updateItemSelectedState(IndexPath)
    case loadMoreSection
    case loadMoreProducts(Int)
    case searchWord(String)
    case setSelectedOrder
    case setSelectionType(OneToOneInquiryOrderType)
    case setIsConfirmButtonEnabled(Bool)
    case isNoDataRetrived(Bool)
  }

  // MARK: Mutation
  enum Mutation {
    case setSelectionType(OneToOneInquiryOrderType)

    case setPeriodType(OneToOneInquiryPeriodButtonType)
    case setPeriodDates(OneToOneInquiryDatePeriod?)
    case setSearchedList(OneToOneInquiryOrderHistory)
    case setSearchType(type: OneToOneInquirySearchType)
    case setSearchWord(word: String?)

    case setNewOrderedList(OneToOneInquiryOrderHistory)
    case setLoadMoreSections(OneToOneInquiryOrderHistory)
    case setLoadMoreProducts(section: Int)
    case setIsNoDataRetrived(Bool)

    case setIsLoading(Bool)
    case setIsLoadingNextPage(Bool)

    case setIsExpaned(section: Int)
    case setSectionSelectState(indexPath: IndexPath)
    case setItemSelectState(indexPath: IndexPath)
    case setSelectedOrder

    case setIsConfirmButtonEnabled(Bool)
  }

  // MARK: State
  struct State {
    var selectionType: OneToOneInquiryOrderType
    var originalSections: [OneToOneInquiryOrderSection] = []
    @Pulse var workingOrderSections: [OneToOneInquiryOrderSection] = []
    @Pulse var isReloadDataNeeded = true
    @Pulse var reloadingSectionIndexSet = IndexSet()
    @Pulse var indexForViewMoreProducts: Int?
    @Pulse var periodType: OneToOneInquiryPeriodButtonType = .oneWeek
    @Pulse var periodDates: OneToOneInquiryDatePeriod?
    @Pulse var isLoading = false
    @Pulse var isLoadingNextPage = false
    @Pulse var isScrollToTopNeeded = false
    @Pulse var searchType: OneToOneInquirySearchType = .product
    @Pulse var isNoDataRetrieved = false
    @Pulse var searchWord: String?
    var page = 0
    var totalPages: Int?
    var selectionState: OneToOneInquiryOrderSelectionState?
    @Pulse var isConfirmButtonEnabled = false
  }

  // MARK: Properties
  var initialState: State

  private let service: OneToOneInquiryProductService

  private var startDateString: String? {
    let periodStart = self.currentState.periodDates?.startDate
    let startDateString = periodStart?
      .date(bySettingHour: 0, minute: 0, second: 0)?
      .toISO(.withInternetDateTimeExtended)
    return startDateString
  }

  private var endDateString: String? {
    let periodEnd = self.currentState.periodDates?.endDate
    let endDateString = periodEnd?
      .date(bySettingHour: 23, minute: 59, second: 59)?
      .toISO(.withInternetDateTimeExtended)

    return endDateString
  }

  // MARK: - Initializer
  init(
    service: OneToOneInquiryProductService,
    selectionType: OneToOneInquiryOrderType
  ) {
    self.initialState = State(selectionType: selectionType)
    self.service = service
  }

  // MARK: Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .setDefaultSearchTerms:
      let datePeriod = self.makeDatePeriod(type: .oneWeek)
      let parameter = OneToOneInquiryOrderRequestParameter(
        startDateTime: datePeriod.startDate.toISO(.withInternetDateTimeExtended),
        endDateTime: datePeriod.endDate.toISO(.withInternetDateTimeExtended)
      )

      return .concat(
        .just(.setSearchType(type: .product)),
        .just(.setSearchWord(word: "")),
        .just(.setPeriodType(.oneWeek)),
        .just(.setPeriodDates(datePeriod)),
        self.requestOrderHistory(parameter: parameter)
      )

    case .loadSavedSearchTerms(let savedTerms):
      guard let periodType = savedTerms.periodType,
            let datePeriod = savedTerms.period else {
        return .empty()
      }
      let searchedWord = savedTerms.searchWord ?? ""

      var parameter = OneToOneInquiryOrderRequestParameter(
        startDateTime: datePeriod.startDate.toISO(.withInternetDateTimeExtended),
        endDateTime: datePeriod.endDate.toISO(.withInternetDateTimeExtended)
      )
      if savedTerms.searchType == .product {
        parameter.keyword = searchedWord
      } else {
        parameter.orderNo = searchedWord
      }

      return .concat(
        .just(.setSearchType(type: savedTerms.searchType ?? .product)),
        .just(.setSearchWord(word: searchedWord)),
        .just(.setPeriodType(periodType)),
        .just(.setPeriodDates(savedTerms.period)),
        self.requestOrderHistory(parameter: parameter)
      )

    case .selectPeriodType(let type):
      let datePeriod = self.makeDatePeriod(type: type)
      return .concat(
        .just(.setPeriodType(type)),
        .just(.setPeriodDates(datePeriod)),
        .just(.setIsLoading(true)),
        self.requestOrders(date: datePeriod)
      )

    case .selectPeriodDates(let period):
      return .merge(
        .just(.setPeriodDates(period)),
        self.requestOrders(date: period)
      )

    case .searchWord(let word):
      return .merge(
        .just(.setIsLoading(true)),
        .just(.setSearchWord(word: word)),
        self.requestOrders(searchWord: word)
      )

    case .loadMoreSection:
      return .concat(
        .just(.setIsLoadingNextPage(true)),
        self.loadMoreSection()
      )

    case .loadMoreProducts(let section):
      return .just(.setLoadMoreProducts(section: section))

    case .isNoDataRetrived(let bool):
      return .just(.setIsNoDataRetrived(bool))

    case .updateExpansionState(let section):
      guard !self.currentState.isLoading, !self.currentState.isLoadingNextPage else {
        return .empty()
      }

      return .just(.setIsExpaned(section: section))

    case .updateSectionSelectState(let indexPath):
      return .just(.setSectionSelectState(indexPath: indexPath))

    case .updateItemSelectedState(let indexPath):
      return .just(.setItemSelectState(indexPath: indexPath))

    case .selectSearchType(let type):
      return .just(.setSearchType(type: type))

    case .setSelectedOrder:
      return .just(.setSelectedOrder)

    case .setSelectionType(let type):
      return .just(.setSelectionType(type))

    case .setIsConfirmButtonEnabled(let isEnabled):
      return .just(.setIsConfirmButtonEnabled(isEnabled))
    }
  }

  // MARK: Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    newState.isReloadDataNeeded = false
    switch mutation {
    case .setPeriodType(let type):
      newState.periodType = type

    case .setPeriodDates(let period):
      newState.periodDates = period

    case .setSearchWord(let word):
      newState.searchWord = word

    case .setNewOrderedList(let receivedOrderData):
      newState = self.updateStateWithNewOrderHistory(
        state: newState,
        receivedOrderData: receivedOrderData
      )

    case .setLoadMoreSections(let moreLoadedSections):
      newState = self.updateStateWithMoreLoadedHistory(
        state: newState,
        moreLoadedSections: moreLoadedSections
      )

    case .setIsNoDataRetrived(let bool):
      newState.isNoDataRetrieved = bool
      
    case .setIsLoading(let bool):
      newState.isLoading = bool

    case .setIsLoadingNextPage(let bool):
      newState.isLoadingNextPage = bool

    case .setIsExpaned(let section):
      newState.reloadingSectionIndexSet = self.updatedReloadingSectionIndexes(
        at: section
      )
      newState.workingOrderSections = self.expandUpatedSections(
        state: newState,
        at: section
      )

    case .setLoadMoreProducts(let section):
      newState.workingOrderSections[section].isAllProductsShown.toggle()
      newState.workingOrderSections = self.updateLoadMoreProducts(
        isAllShown: newState.workingOrderSections[section].isAllProductsShown,
        orders: newState.workingOrderSections,
        at: section
      )
      newState.indexForViewMoreProducts = section

    case .setSectionSelectState(let indexPath):
      newState = self.updateSelectionState(
        state: newState,
        indexPath: indexPath,
        isForItemSelection: false
      )

    case .setItemSelectState(let indexPath):
      newState = self.updateSelectionState(
        state: newState,
        indexPath: indexPath,
        isForItemSelection: true
      )

    case .setSearchedList(let searchResult):
      let sections = self.mapToOrderSection(
        selectionType: state.selectionType,
        fetchedData: searchResult
      )
      newState.workingOrderSections = sections

    case .setSearchType(let type):
      newState.searchType = type

    case .setSelectedOrder:
      newState.selectionState = self.selectionState(
        type: newState.selectionType,
        orders: newState.originalSections
      )

    case .setSelectionType(let type):
      newState.selectionType = type

    case .setIsConfirmButtonEnabled(let isEnabled):
      newState.isConfirmButtonEnabled = isEnabled
    }

    return newState
  }

  // MARK: Load Data
  private func updateStateWithNewOrderHistory(
    state: State,
    receivedOrderData: OneToOneInquiryOrderHistory
  ) -> State {
    var newState = state
    let sections = self.mapToOrderSection(
      selectionType: state.selectionType,
      fetchedData: receivedOrderData
    )

    newState.originalSections = sections
    newState.workingOrderSections = sections
    newState.workingOrderSections = self.expandUpatedSections(state: newState, at: 0)

    newState.page = receivedOrderData.number ?? 0
    newState.totalPages = receivedOrderData.totalPages

    newState.reloadingSectionIndexSet = []
    newState.isReloadDataNeeded = true
    newState.isLoading = false
    newState.isScrollToTopNeeded = true
    newState.isConfirmButtonEnabled = false

    return newState
  }

  private func updateStateWithMoreLoadedHistory(
    state: State,
    moreLoadedSections: OneToOneInquiryOrderHistory
  ) -> State {
    var newState = state
    newState.page = moreLoadedSections.number ?? 0

    let mappedSections = self.mapToOrderSection(
      selectionType: newState.selectionType,
      fetchedData: moreLoadedSections
    )

    let moreLoadedArrays = self.appendFetchedMoreData(
      state: newState,
      fetchedData: mappedSections
    )

    newState.workingOrderSections = moreLoadedArrays.workingOrderSections
    newState.originalSections = moreLoadedArrays.originalSections
    newState.isLoadingNextPage = false
    newState.isReloadDataNeeded = true

    return newState
  }

  // MARK: API Request
  private func requestOrders(
    date period: OneToOneInquiryDatePeriod
  ) -> Observable<Mutation> {
    guard let startDateString = period.startDate.dateWithLocalBeginningTime?.withDateTimeExtened,
          let endDateString = period.endDate.dateWithLocalEndTime?.withDateTimeExtened else {
      return .empty()
    }

    var parameter = OneToOneInquiryOrderRequestParameter(
      startDateTime: startDateString,
      endDateTime: endDateString
    )

    if !self.currentState.searchWord.isEmpty {
      let searchWord = self.currentState.searchWord
      switch self.currentState.searchType {
      case .orderNumber:
        parameter.orderNo = searchWord
      case .product:
        parameter.keyword = searchWord
      }
    }

    return self.requestOrderHistory(parameter: parameter)
      .catchAndReturn(.setIsLoading(false))
  }

  private func requestOrders(
    searchWord: String
  ) -> Observable<Mutation> {
    guard let startDateString = self.startDateString,
          let endDateString = self.endDateString else {
      return Observable.just(.setIsLoading(false))
    }

    var parameter = OneToOneInquiryOrderRequestParameter(
      startDateTime: startDateString,
      endDateTime: endDateString
    )

    switch self.currentState.searchType {
    case .orderNumber:
      parameter.orderNo = searchWord
    case .product:
      parameter.keyword = searchWord
    }

    return self.requestOrderHistory(parameter: parameter)
      .catch { _ in
        return .merge(
          .just(.setIsLoading(false)),
          .just(.setIsNoDataRetrived(true))
        )
      }
  }

  private func requestOrdersMore() -> Observable<Mutation> {
    guard let startDateString = self.startDateString,
          let endDateString = self.endDateString else {
      return Observable.just(.setIsLoadingNextPage(false))
    }

    let parameter = OneToOneInquiryOrderRequestParameter(
      startDateTime: startDateString,
      endDateTime: endDateString,
      keyword: self.currentState.searchWord,
      page: self.currentState.page + 1
    )

    return self.requestOrderHistory(parameter: parameter, isLoadingMore: true)
      .catchAndReturn(.setIsLoadingNextPage(false))
  }

  private func requestOrderHistory(
    parameter: OneToOneInquiryOrderRequestParameter,
    isLoadingMore: Bool = false
  ) -> Observable<Mutation> {
    let orderedProducts = self.service.requestOrders(parameter: parameter)
      .compactMap { $0 }
      .map { data -> Mutation in
        if isLoadingMore {
          return Mutation.setLoadMoreSections(data)
        }
        return Mutation.setNewOrderedList(data)
      }
      .asObservable()

    return orderedProducts
  }

  private func loadMoreSection() -> Observable<Mutation> {
    if let totalPageCount = self.currentState.totalPages {
      let nextPageNumber = self.currentState.page + 1
      guard nextPageNumber <= totalPageCount else {
        return Observable.just(.setIsLoadingNextPage(false))
      }
    }

    guard !self.currentState.isLoadingNextPage else {
      return .empty()
    }

    return self.requestOrdersMore()
  }

  private func appendFetchedMoreData(
    state: State,
    fetchedData: [OneToOneInquiryOrderSection]
  ) -> State {
    var newState = state
    newState.originalSections.append(contentsOf: fetchedData)
    fetchedData.forEach {
      var copiedSection = $0
      copiedSection.items = []
      newState.workingOrderSections.append(copiedSection)
    }
    return newState
  }

  private func mapToOrderSection(
    selectionType: OneToOneInquiryOrderType,
    fetchedData: OneToOneInquiryOrderHistory
  ) -> [OneToOneInquiryOrderSection] {
    let mappedData = fetchedData.content
      .map { order -> OneToOneInquiryOrderSection in
        OneToOneInquiryOrderSection(
          selectionType: selectionType,
          isExpanded: order.isExpanded,
          selectionState: order.selectionState,
          orderNo: order.orderNo,
          orderedDate: order.orderedDate,
          totalProductCount: order.totalProductCount,
          items: order.products
        )
      }

    return mappedData
  }

  // MARK: Section + Item State Change
  private func expandUpatedSections(
    state: State,
    at section: Int
  ) -> [OneToOneInquiryOrderSection] {
    let workingSections = state.workingOrderSections
      .enumerated()
      .map { index, sectionItem -> OneToOneInquiryOrderSection in
        var copiedSection = sectionItem

        let isExpanded = index == section ? !copiedSection.isExpanded : false
        copiedSection.isExpanded = isExpanded

        var originalProductItems = state.originalSections[section].items

        let shouldShowOnlyThreeProducts = originalProductItems.count > Metric.viewMoreLimitCount && !copiedSection.isAllProductsShown

        if shouldShowOnlyThreeProducts {
          originalProductItems = Array(originalProductItems[0..<Metric.viewMoreLimitCount])
        }

        copiedSection.items = isExpanded ? originalProductItems : []

        return copiedSection
      }

    return workingSections
  }

  private func updateSelectionState(
    state: State,
    indexPath: IndexPath,
    isForItemSelection: Bool
  ) -> State {
    var newState = state
    self.showWarnigIfNeeded(
      sections: newState.originalSections,
      at: indexPath,
      isForOrderSelection: false
    )

    if isForItemSelection {
      let updatedWorkingSection = self.updateProductCheckMarkState(
        sections: newState.workingOrderSections,
        at: indexPath
      )
      let updatedOriginalSection = self.updateProductCheckMarkState(
        sections: newState.originalSections,
        at: indexPath
      )
      let newSectionSelectionState = self.updateSectionCheckStateWithItem(
        sections: updatedOriginalSection,
        at: indexPath
      )

      newState.workingOrderSections = updatedWorkingSection
      newState.originalSections = updatedOriginalSection
      newState.workingOrderSections[indexPath.section].selectionState = newSectionSelectionState
      newState.originalSections[indexPath.section].selectionState = newSectionSelectionState

    } else {
      let updatedWorkingSection = self.updateSectionCheckMarkState(
        sections: newState.workingOrderSections,
        at: indexPath
      )
      let updatedOriginalSection = self.updateSectionCheckMarkState(
        sections: newState.originalSections,
        at: indexPath
      )
      newState.workingOrderSections = updatedWorkingSection
      newState.originalSections = updatedOriginalSection
    }

    newState.isConfirmButtonEnabled = self.shouldEnableConfirmButton(
      orderSections: newState.originalSections
    )
    newState.isReloadDataNeeded = true

    return newState
  }

  private func updateSectionCheckStateWithItem(
    sections: [OneToOneInquiryOrderSection],
    at indexPath: IndexPath
  ) -> CheckMarkState {
    let sectionItems = sections[indexPath.section].items
    let sectionSelectedItems = sectionItems.filter { product in
      product.selectionState == .checked
    }

    if sectionItems.count == sectionSelectedItems.count {
      return .checked
    }
    return .unchecked
  }

  private func updateSectionCheckMarkState(
    sections: [OneToOneInquiryOrderSection],
    at indexPath: IndexPath
  ) -> [OneToOneInquiryOrderSection] {
    let newSections = sections.enumerated()
      .map { section, order -> OneToOneInquiryOrderSection in
        var copiedOrder = order

        var selectionState = copiedOrder.selectionState

        if section == indexPath.section {
          let newState: CheckMarkState = selectionState == .checked ? .unchecked : .checked
          selectionState = newState
        } else {
          selectionState = .unchecked
        }

        copiedOrder.selectionState = selectionState

        let updateItems = copiedOrder.items.map { product -> OneToOneInquiryProduct in
          var copiedProduct = product
          copiedProduct.selectionState = selectionState

          return copiedProduct
        }

        copiedOrder.items = updateItems

        return copiedOrder
      }

    return newSections
  }

  private func updateProductCheckMarkState(
    sections: [OneToOneInquiryOrderSection],
    at indexPath: IndexPath
  ) -> [OneToOneInquiryOrderSection] {
    let newSections = sections.enumerated().map { index, order -> OneToOneInquiryOrderSection in
      var copiedOrder = order
      if index != indexPath.section {
        copiedOrder.selectionState = .unchecked
        copiedOrder.items = copiedOrder.items.map { product in
          var copiedProduct = product
          copiedProduct.selectionState = .unchecked

          return copiedProduct
        }
      } else {
        let selectionState = copiedOrder.items[indexPath.item].selectionState
        let newState: CheckMarkState = selectionState == .checked ? .unchecked : .checked
        copiedOrder.items[indexPath.item].selectionState = newState
      }

      return copiedOrder
    }

    return newSections
  }

  private func showWarnigIfNeeded(
    sections: [OneToOneInquiryOrderSection],
    at indexPath: IndexPath,
    isForOrderSelection: Bool
  ) {
    let message = R.string.localizable.composeInquiryOrderProductToastSelectGuide()
    if let selectedSection = sections.firstIndex(
      where: { $0.items.contains { product in
          product.selectionState == .checked
        }
      }
    ) {
      if selectedSection != indexPath.section {
        ToastManager.shared.show(message, type: .error)
      }
    }
  }

  private func updateLoadMoreProducts(
    isAllShown: Bool,
    orders: [OneToOneInquiryOrderSection] ,
    at section: Int
  ) -> [OneToOneInquiryOrderSection] {
    var newArray = orders
    var products = self.currentState.originalSections[section].items
    if !isAllShown {
      products = Array(products[0..<Metric.viewMoreLimitCount])
    }
    newArray[section].items = products

    return newArray
  }

  private func updatedReloadingSectionIndexes(
    at section: Int
  ) -> IndexSet {
    var currentSections = IndexSet()
    currentSections.insert(section)
    if let expanedSection = self.currentState.workingOrderSections.firstIndex(
      where: { section in
        section.isExpanded == true
      }
    ) {
      currentSections.insert(expanedSection)
    }

    return currentSections
  }

  // MARK: UI Update Related
  private func makeDatePeriod(
    type: OneToOneInquiryPeriodButtonType
  ) -> OneToOneInquiryDatePeriod {
    var startDate = Date().dateWithLocalBeginningTime ?? Date()

    let endDate = Date().dateWithLocalEndTime ?? Date()

    switch type {
    case .oneWeek:
      startDate = startDate.dateByAdding(-7, .day).date

    case .oneMonth:
      startDate = startDate.dateByAdding(-1, .month).date

    case .threeMonth:
      startDate = startDate.dateByAdding(-3, .month).date

    case .specificDates:
      startDate = startDate.dateByAdding(-6, .month).date
    }

    let period = OneToOneInquiryDatePeriod(startDate: startDate, endDate: endDate)

    return period
  }

  private func shouldEnableConfirmButton(orderSections: [OneToOneInquiryOrderSection]) -> Bool {
    let isEnabled = orderSections.contains { section in
      section.items.contains { product in
        product.selectionState == .checked
      }
    }
    return isEnabled
  }

  // MARK: Data to send to apply
  private func selectionState(
    type: OneToOneInquiryOrderType,
    orders: [OneToOneInquiryOrderSection]
  ) -> OneToOneInquiryOrderSelectionState? {
    var items: [OneToOneInquiryProduct]?
    var orderNumber = 0

    switch type {
    case .all:
      if let selectedOrder = orders.first(
        where: { $0.selectionState == .checked }
      ) {
        items = selectedOrder.items
        orderNumber = selectedOrder.orderNo
      }

    default:
      if let selectedOrder = orders.first(
        where: { $0.items.contains { product in
            product.selectionState == .checked
          }
        }
      ) {
        items = selectedOrder.items.filter { $0.selectionState == .checked }
        orderNumber = selectedOrder.orderNo
      }
    }

    guard let items = items else {
      return nil
    }

    let period = self.currentState.periodDates ?? OneToOneInquiryDatePeriod(startDate: Date(), endDate: Date())

    let selectionState = OneToOneInquiryOrderSelectionState(
      id: orderNumber,
      products: items,
      periodType: self.currentState.periodType,
      period: period,
      searchWord: self.currentState.searchWord,
      searchType: self.currentState.searchType,
      selectionType: self.currentState.selectionType
    )

    return selectionState
  }
}
