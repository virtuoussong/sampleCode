//
//  AmplitudeManager.swift
//  MarketKurly
//
//  Created by Minha Seong on 19/09/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit
// Library
import Amplitude
import Branch
import FirebaseCrashlytics
import FBSDKCoreKit
import FirebaseAnalytics
import SwiftyJSON

class AmplitudeManager: NSObject {
  static let shared = AmplitudeManager()

  private let instance: Amplitude? = Amplitude.instance()
  private var trackingOptions: AMPTrackingOptions?
  private var isReleaseBuild: Bool = false
  private(set) var isVisibilityTrackingTestMode: Bool = false
  private(set) lazy var browseID: String = {
    return UUID().uuidString
  }()
  private(set) var previousScreenName: String? {
    didSet {
      DLog.info("\(String(describing: previousScreenName))")
    }
  }
  private(set) var screenName: String? {
    willSet {
      previousScreenName = screenName
    }
    didSet {
      DLog.debug("\(String(describing: screenName))")

      Crashlytics.crashlytics().log(screenName)

      updateBrowseScreenName(with: screenName)
      updateSignUpSourceScreenName(with: screenName)
    }
  }
  private(set) var browseTabName: String? {
    didSet {
      DLog.info("\(String(describing: browseTabName))")

      browseScreenName = nil
    }
  }
  private(set) var browseScreenName: String? {
    didSet {
      DLog.info("\(String(describing: browseScreenName))")
    }
  }
  private(set) var browseEventName: String? {
    didSet {
      DLog.info("\(String(describing: browseEventName))")
    }
  }
  private(set) var browseEventInfo: Any? {
    didSet {
      DLog.info("\(String(describing: browseEventInfo))")
    }
  }
  private(set) var browseSubEventName: String? {
    didSet {
      DLog.info("\(String(describing: browseSubEventName))")
    }
  }
  private(set) var browseSubEventInfo: Any? {
    didSet {
      DLog.info("\(String(describing: browseSubEventInfo))")
    }
  }
  private(set) var browseSectionId: Any? {
    didSet {
      DLog.info("browseSectionId!!!: \(String(describing: browseSectionId))")
    }
  }
  private(set) var signUpSourceScreenName: String? {
    didSet {
      DLog.info("\(String(describing: signUpSourceScreenName))")
    }
  }
  private(set) var productReviewPosition: Int? {                                              // 후기 목록에서 선택한 후기의 위치 (.viewReviewDetail 이벤트의 이벤트 프로퍼티에 적용)
    didSet {
      DLog.info("\(String(describing: productReviewPosition))")
    }
  }
  private var userProperties = [String: Any]()

  var isTrackingAvailable: Bool = true                                                        // 특정 상황에서 이벤트를 보내지 않기 위해서 사용
  var sessionID: String? {
    // https://help.amplitude.com/hc/en-us/articles/115002323627#out-of-session-events
    guard let sessionID = instance?.getSessionId(), sessionID != -1 else {
      return nil
    }

    return String(sessionID)
  }

  private var ntpTime: NTPTimeProtocol?

  var fusionQueryId: String?
}

// MARK: - Lifecycle

// MARK: - Public

extension AmplitudeManager {
  func configure(options: AMPTrackingOptions? = nil, ntpTime: NTPTimeProtocol) {
    let trackingOptions = options ?? AMPTrackingOptions.defaultOptions
    self.trackingOptions = trackingOptions

    if UIApplication.shared.configuration == .release {
      isReleaseBuild = true
    } else {
      instance?.eventUploadPeriodSeconds = 1
    }
    // https://help.amplitude.com/hc/en-us/articles/115002323627#amplitude-start-end-session-events
    instance?.trackingSessionEvents = false
    instance?.setTrackingOptions(trackingOptions)

    instance?.initializeApiKey(
      Constants.Library.Amplitude.apiKey,
      userId: SessionManager.shared.jwt?.uuid
    )

    self.ntpTime = ntpTime
  }

  func updateUserID(_ userID: String) {
    instance?.setUserId(userID, startNewSession: true)

    Crashlytics.crashlytics().setUserID(userID)
    Analytics.setUserID(userID)
    Branch.getInstance().setIdentity(userID)
  }

  /// 불필요한 deviceID 갱신을 막기 위해 userID 가 설정된 경우에만 처리
  func clearUserID() {
    guard instance?.userId != nil else {
      return
    }

    instance?.setUserId(nil, startNewSession: true)
    instance?.regenerateDeviceId()
  }

  func refreshBrowseID() {
    browseID = UUID().uuidString
  }

  func updateScreenName(_ screenName: AmplitudeEvent.Property.Value.ScreenName?, isForce: Bool = true) {
    updateScreenName(screenName?.rawValue, isForce: isForce)
  }

  func updateScreenName(_ screenName: String?, isForce: Bool = true) {
    guard let screenName = screenName else {
      DLog.warning("screenName is nil")

      return
    }

    // TODO: 딥링크를 이용하여 화면을 전환하는 경우, 중간에 포함된 화면에서 screenName 을 변경하지 않도록 예외 처리
    if isForce || self.screenName != screenName {
      self.screenName = screenName
    }
  }

  func updateBrowseTabName(_ tabName: AmplitudeEvent.Property.Value.TabName?) {
    guard let tabName = tabName else {
      return
    }

    browseTabName = tabName.rawValue
  }

  func updateProductReviewPosition(_ position: Int, in list: [PostProtocol]) {
    // 공지 사항 - 베스트 후기 - 후기 순서로 정렬된다는 가정하에 공지 사항을 제외한 후기의 첫 번째 위치를 가져온다.
    guard let firstPosition = list.firstIndex(where: { $0.postType != .notice }) else {
      productReviewPosition = nil

      return
    }

    let calculatedPosition = position - firstPosition
    if calculatedPosition < 0 {                             // 공지 사항
      productReviewPosition = nil
    } else {
      productReviewPosition = calculatedPosition
    }
  }

  func addUserProperties(with json: JSON) {
    if let dictionaryObject = json.dictionaryObject {
      self.addUserProperties(dictionaryObject)
    }
  }

  func addUserProperties(_ properties: [String: Any]) {
    properties.forEach { key, value in
      self.addUserProperty(value, for: key)
    }
  }

  func addUserProperty(_ value: Any, for key: String) {
    DLog.debug("set userProperty: \(key): \(value)")
    self.userProperties[key] = value
    self.instance?.setUserProperties(self.userProperties)
  }

  func setUserGradeToUserProperty() {
    guard !SessionManager.shared.isGuest else {
      DLog.debug("isGuest: \(SessionManager.shared.isGuest)")

      return
    }

    RequestManager.shared.requestMyKurly {
      guard let json = $0.json else {
        DLog.error($0.error as Any)
        return
      }
      let data = json["data"]
      let userInformation = UserInformation(data)
      self.addUserProperty(userInformation.userGradeName, for: "membership_level")
    }
  }

  func unsetUserProperty(key: String) {
    DLog.debug("unset userProperty: \(key)")

    self.userProperties.removeValue(forKey: key)
    self.instance?.setUserProperties(self.userProperties)
  }

  func updateClusterCodeUserProperty(_ clusterCode: String?) {
    if let clusterCode = clusterCode {
      self.addUserProperty(clusterCode, for: "center_code")
    } else {
      self.unsetUserProperty(key: "center_code")
    }
  }

  /**
   이벤트 전송

   1. 사전 정의된 eventName 목록과 비교하여 browseEventName, browseEventInfo 를 업데이트
   2. 이벤트에 따라 기존 이벤트 프로퍼티에 AmplitudeManager 에서 관리하고 있는 이벤트 프로퍼티를 추가
   3. 이벤트에 따라 필요 없는 이벤트 프로퍼티를 제거
   4. 이벤트 전송
   */
  func sendEvent(_ event: AmplitudeEvent) {
    Crashlytics.crashlytics().log(event.name)

    updateEventProperties(with: event)
    removeEventProperties(with: event)

    DLog.debug("event: \(event)")

    // 이벤트 전송
    /**
     Expression implicitly coerced from '[String : Any?]' to '[AnyHashable : Any]' 를 제거하는 방법
     
     1. Value 를 Any? 에서 Any 로 변경 (AmplitudeEventProperties 등)
     2. nil 대신 Any?.none 사용
     */
    if let eventName = event.name {
      instance?.logEvent(eventName, withEventProperties: event.properties)
    }

    // 카프카로 실시간 사용자 이벤트 전송
    sendRealtimeUserEvent(event: event)

    // 이벤트 전송 이후, 추가 작업
    if updateBrowseEventName(with: event) {
      updateBrowseEventInfo(with: event)
    }
    if updateBrowseSubEventName(with: event) {
      updateBrowseSubEventInfo(with: event)
    }
    self.updateBrowseSectionId(with: event)
    guard let name = event.predefinedName else {
      return
    }

    switch name {
    case .loginSuccess:
      Analytics.logEvent(AnalyticsEventLogin, parameters: nil)
      AppEvents.logEvent(AppEvents.Name(rawValue: Constants.Library.Facebook.Event.loginSuccess.rawValue))
    case .viewProductDetail:
      productReviewPosition = nil
    default:
      break
    }
  }

  func sendRealtimeUserEvent(event: AmplitudeEvent) {
    let eventName = AmplitudeEvent.Name(rawValue: event.name)
    switch eventName {
    case .selectProduct,
         .selectProductShortcut,
         .viewProductDetail,
         .viewProductSelection,
         .viewReviewDetail,
         .selectSearch,
         .addToCartProduct,
         .addToCartSuccess,
         .addToCartFail,
         .removeCartProductSuccess,
         .purchaseProduct,
         .purchaseSuccess,
         .purchaseFail:
      RequestManager.shared.sendRealtimeUserEvent(event: event, eventTime: ntpTime?.now())
    case .selectRecommendation(_):
      if event.properties?["package_id"] != nil {
        RequestManager.shared.sendRealtimeUserEvent(event: event, eventTime: ntpTime?.now())
      }
    default:
      break
    }
  }

  func forceUpload() {
    instance?.uploadEvents()
  }

  /// 초기화나 정보 갱신이 backgroundQueue 에서 이루어지므로 바로 확인할 수 없음
  func printInfo() {
    DLog.debug("apiKey: \(String(describing: instance?.apiKey))")
    DLog.debug("sessionID: \(String(describing: sessionID))")
    DLog.debug("deviceID: \(String(describing: instance?.deviceId))")
    DLog.debug("userID: \(String(describing: instance?.userId))")
    DLog.debug("trackingSessionEvents: \(String(describing: instance?.trackingSessionEvents))")
    DLog.debug("trackingOptions: \(String(describing: trackingOptions?.getApiPropertiesTrackingOption()))")
    DLog.debug("propertyList: \(String(describing: instance?.propertyList))")
  }

  func printInfo2() {
    DLog.debug("previousScreenName: \(String(describing: previousScreenName))")
    DLog.debug("screenName: \(String(describing: screenName))")
    DLog.debug("browseTabName: \(String(describing: browseTabName))")
    DLog.debug("browseScreenName: \(String(describing: browseScreenName))")
    DLog.debug("browseEventName: \(String(describing: browseEventName))")
    DLog.debug("browseEventInfo: \(String(describing: browseEventInfo))")
    DLog.debug("signUpSourceScreenName: \(String(describing: signUpSourceScreenName))")
    DLog.debug("productReviewPosition: \(String(describing: productReviewPosition))")
  }
}

// MARK: - Private

private extension AmplitudeManager {
  func updateBrowseScreenName(with screenName: String?) {
    let screenNames: [AmplitudeEvent.Property.Value.ScreenName] = [
      .category,
      .search,
      .myKurly,
      .recommendation,
      .newProduct,
      .popularProduct,
      .bargain,
      .eventList,
      .categoryProductList,
      .searchProductList,
      .orderHistory,
      .myReviewableList,
      .myReviewHistory,
      .recipeDetail,
      .kurlyPassGuide,
      .pickList,
      .giftList,
      .giftHistory
    ]

    guard screenNames.contains(where: { $0.rawValue == screenName }) else {
      return
    }

    self.browseScreenName = screenName
    self.resetBrowseSectionIdIfNeeded()
  }

  @discardableResult
  func updateBrowseEventName(with event: AmplitudeEvent) -> Bool {
    switch event.predefinedName {
    case .selectHomeTab,
         .selectCategoryTab,
         .selectSearchTab,
         .selectMyKurlyTab,
         .selectRecommendationSubtab,
         .selectNewProductSubtab,
         .selectPopularProductSubtab,
         .selectBargainSubtab,
         .selectEventListSubtab,
         .selectCategory,
         .selectCategoryBanner,
         .selectSearch,
         .selectRecommendation,
         .selectEventListBanner,
         .selectFrequentlyPurchaseProductList,
         .selectMyKurlyPickList,
         .selectKurlyRecipe,
         .selectGiftList,
         .selectMyKurlyGiftList,
         .selectMyKurlyBanner:

      browseEventName = event.name
      return true

    default:
      return false

    }
  }

  @discardableResult
  func updateBrowseSubEventName(with event: AmplitudeEvent) -> Bool {
    switch event.predefinedName {
    case .selectCategory,
         .selectEventListBanner,
         .selectRecommendation,
         .selectCategorySubtab,
         .selectCategoryBanner,
         .selectGiftList:
      self.browseSubEventName = event.name
      return true

    default:
      return false
    }
  }

  func updateBrowseEventInfo(with event: AmplitudeEvent) {
    switch event.predefinedName {
    case .selectRecommendation?:
      browseEventInfo = event.properties?[.url] as? String
        ?? event.properties?[.selectionType] as? String
        ?? event.properties?[.packageID] as? String
    case .selectCategory?,
         .selectGiftList:
      browseEventInfo = event.properties?[.primaryCategoryID] as? String
    case .selectSearch?:
      browseEventInfo = event.properties?[.selectionType]
    case .selectEventListBanner?:
      browseEventInfo = event.properties?[.url]
    case .selectCategoryBanner?:
      browseEventInfo = event.properties?[.bannerCategoryID]
    case .selectKurlyRecipe?:
      browseEventInfo = event.properties?[.contentTitle]
    case .selectMyKurlyBanner?:
      browseEventInfo = event.properties?[.url]
    default:
      browseEventInfo = nil
    }
  }

  func updateBrowseSubEventInfo(with event: AmplitudeEvent) {
    switch event.predefinedName {
    case .selectEventListBanner:
      let url = event.properties?[.url]
      self.browseSubEventInfo = url
    case .selectRecommendation:
      let url = event.properties?[.url]
      let selectionType = event.properties?[.selectionType]
      self.browseSubEventInfo = url ?? selectionType
    case .selectCategorySubtab:
      let secondaryCategoryId = event.properties?[.secondaryCategoryID]
      self.browseSubEventInfo = secondaryCategoryId
    case .selectCategoryBanner:
      let bannerCategoryId = event.properties?[.bannerCategoryID]
      self.browseSubEventInfo = bannerCategoryId
    case .selectCategory,
         .selectGiftList:
      let secondaryCategoryID = event.properties?[.secondaryCategoryID]
      let primaryCategoryID = event.properties?[.primaryCategoryID]
      self.browseSubEventInfo = secondaryCategoryID ?? primaryCategoryID
    default:
      self.browseSubEventInfo = nil
    }
  }

  func updateBrowseSectionId(with event: AmplitudeEvent) {
    switch event.predefinedName {
    case .selectRecommendation:
      self.browseSectionId = event.properties?[.sectionId]
    default:
      return
    }
  }

  func resetBrowseSectionIdIfNeeded() {
    guard let screenName = self.browseScreenName else {
      self.browseSectionId = nil
      return
    }
    let name = AmplitudeEvent.Property.Value.ScreenName(rawValue: screenName)
    switch name {
    case .recommendation,
         .recipeDetail:
      return
    default:
      self.browseSectionId = nil
    }
  }

  func updateSignUpSourceScreenName(with screenName: String?) {
    let screenNames: [AmplitudeEvent.Property.Value.ScreenName] = [.signUp, .login]

    guard screenNames.allSatisfy({ $0.rawValue != screenName }) else {
      return
    }

    signUpSourceScreenName = screenName
  }

  /**
   이벤트에 따라 특정 이벤트 프로퍼티를 추가하거나 변경
   */
  func updateEventProperties(with event: AmplitudeEvent) {
    // 모든 이벤트에 공통으로 적용되는 이벤트 프로퍼티
    event.properties([
      .adid: SessionManager.shared.advertisingIdentifier,
      .buildNumber: Bundle.main.buildNumber,
      .screenName: self.screenName,
      .previousScreenName: self.previousScreenName,
      .browseID: self.browseID,
      .browseTabName: self.browseTabName,
      .browseScreenName: self.browseScreenName,
      .browseEventName: self.browseEventName,
      .browseEventInfo: self.browseEventInfo,
      .browseSubEventName: self.browseSubEventName,
      .browseSubEventInfo: self.browseSubEventInfo,
      .browseSectionId: self.browseSectionId,
      .isReleaseBuild: self.isReleaseBuild
    ])

    if let id = fusionQueryId, browseTabName == AmplitudeEvent.Property.Value.TabName.search.rawValue {
      event.properties([.fusionQueryId: id])
    }

    switch event.predefinedName {
    case .viewSignUp?, .signUpSuccess?:
      event.properties([.signUpSourceScreenName: signUpSourceScreenName])
    case .viewReviewDetail?:
      event.properties([.position: productReviewPosition.increased()])
    case .addToCartProduct?:
      if event.properties?[.productID] == nil {
        event.properties([.productID: event.properties?[.packageID]])
      }
      if event.properties?[.productName] == nil {
        event.properties([.productName: event.properties?[.packageName]])
      }
    default:
      break
    }
  }

  /**
   이벤트에 따라 특정 이벤트 프로퍼티를 제거
   */
  func removeEventProperties(with event: AmplitudeEvent) {
    switch event.predefinedName {
    case .selectCategory?:
      event.removeProperties(forKeys: .position, .selectionType)
    case .selectRecommendation?:
      event.removeProperties(forKeys: .isSoldOut, .quantity)
    case .impressionRecommendation?:
      event.removeProperties(forKeys: .quantity)
    case .selectEventListBanner?:
      event.removeProperties(forKeys: .selectionType)
    case .selectProduct?, .selectProductShortcut?:
      event.removeProperties(forKeys: .quantity, .selectionType)
    case .selectPurchase?:
      event.removeProperties(forKeys: .position, .quantity, .selectionType)
    case .addToCartProduct?:
      event.removeProperties(forKeys: .isSoldOut, .position, .selectionType)
    case .addToCartSuccess?:
      event.removeProperties(forKeys: .isSoldOut, .originPrice, .position, .price, .quantity, .selectionType)
    case .purchaseSuccess?:
      event.removeProperties(forKeys: .purchaseProducts)
    case .removeCartProductSuccess?:
      event.removeProperties(forKeys: .position)
    default:
      break
    }
  }
}

// MARK: - Action

// MARK: - Override

// MARK: - Notification

// MARK: - Enumeration

// MARK: - Operator Overload

// MARK: - Mock
