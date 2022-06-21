//
//  OneToOneInquiryService.swift
//  MarketKurly
//
//  Created by MK-Mac-255 on 2021/12/14.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//

import RxSwift
import UIKit

protocol OneToOneInquiryService: AnyObject {
  func loadInquiryList(page: Int) -> Single<OneToOneInquiryList?>
  func loadInquiryNoticeList() -> Single<[OneToOneInquiryNotice]?>
  func loadKakaoInquiryInfo() -> Single<Dialog>
  func loadKakaoIsEnableFlag() -> Single<Bool>
  func deleteInquiry(id: Int) -> Single<Bool>
  func createOneToOneInquiryId() -> Single<Int?>
  func loadInquiryTypes() -> Single<[OneToOneInquiryType]?>
  func loadMemberInfo() -> Single<String?>
  func postInquiry(inquiry: OneToOneInquiryApply) -> Single<Bool>
  func updateInquiry(inquiry: OneToOneInquiryApply) -> Single<Bool>
  func uploadPhoto(id: Int, photo: UIImage, index: Int) -> Single<OneToOneInquiryImage?>
  func deletePhoto(id: Int, photoId: Int) -> Single<Bool>
}

final class OneToOneInquiryServiceImpl: OneToOneInquiryService {

  // MARK: Properties
  private let provider: MemberBoardProvider

  // MARK: Initializer
  init(provider: MemberBoardProvider) {
    self.provider = provider
  }

  // MARK: `OneToOneInquiryService` implementaion
  func loadInquiryList(page: Int) -> Single<OneToOneInquiryList?> {
    self.provider.rx.request(.getInquiryList(page: page + 1))
      .map(OneToOneInquiryPayload<OneToOneInquiryList>.self)
      .map(\.data)
  }

  func loadInquiryNoticeList() -> Single<[OneToOneInquiryNotice]?> {
    self.provider.rx.request(.getInquiryNoticeList)
      .map(OneToOneInquiryPayload<[OneToOneInquiryNotice]>.self)
      .map(\.data)
  }

  func loadKakaoInquiryInfo() -> Single<Dialog> {
    self.provider.rx.request(.getKakaoInfo)
      .mapResponse(Dialog.self)
  }

  func loadKakaoIsEnableFlag() -> Single<Bool> {
    self.provider.rx.request(.getKakaoIsEnableFlag)
      .map(OneToOneInquiryKakaoFlag.self)
      .map(\.isKakaoTalkEnabled)
  }

  func deleteInquiry(id: Int) -> Single<Bool> {
    self.provider.rx.request(.deleteInquiry(id: id))
      .map(OneToOneInquiryPayload<OneToOneInquiryDraft>.self)
      .map(\.success)
  }

  func createOneToOneInquiryId() -> Single<Int?> {
    self.provider.rx.request(.createDraft)
      .map(OneToOneInquiryPayload<OneToOneInquiryDraft>.self)
      .map(\.data?.id)
  }

  func loadInquiryTypes() -> Single<[OneToOneInquiryType]?> {
    self.provider.rx.request(.getInquiryTypes)
        .map(OneToOneInquiryPayload<[OneToOneInquiryType]>.self)
        .map(\.data)
  }

  func loadMemberInfo() -> Single<String?> {
    self.provider.rx.request(.getMemberInfo)
      .map(OneToOneInquiryPayload<OneToOneInquiryMemberInfo>.self)
      .map(\.data?.memberMobileMasked)
  }

  func postInquiry(inquiry: OneToOneInquiryApply) -> Single<Bool> {
    self.provider.rx.request(.postInquiry(inquiry: inquiry))
      .map(OneToOneInquiryPayload<OneToOneInquiryDraft>.self)
      .map(\.success)
  }

  func updateInquiry(inquiry: OneToOneInquiryApply) -> Single<Bool> {
    self.provider.rx.request(.updateInquiry(id: inquiry.oneToOneInquiryNo, inquiry: inquiry))
      .map(OneToOneInquiryPayload<OneToOneInquiryDraft>.self)
      .map(\.success)
  }

  func uploadPhoto(id: Int, photo: UIImage, index: Int) -> Single<OneToOneInquiryImage?> {
    self.provider.rx.request(.uploadPhoto(id: id, photo: photo, index: index))
      .map(OneToOneInquiryPayload<[OneToOneInquiryImage]>.self)
      .map(\.data?.first)
  }

  func deletePhoto(id: Int, photoId: Int) -> Single<Bool> {
    self.provider.rx.request(.deletePhoto(id: id, photoId: photoId))
      .map(OneToOneInquiryPayload<OneToOneInquiryImage>.self)
      .map(\.success)
  }
}
