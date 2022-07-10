//
//  ProductRegisterationSceneViewModel.swift
//  OpenMarket
//
//  Created by 1 on 2022/06/20.
//

import Foundation

import RxSwift
import RxCocoa

final class ProductRegisterationSceneViewModel {
    
    private var APIService: APIServcie
    static let maximumProductImageCount = 5
    private var maximutProductImageCellCount: Int { ProductRegisterationSceneViewModel.maximumProductImageCount + 1 }

    init(APIService: APIServcie) {
        self.APIService = APIService
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let imagePickerCellDidSelected: Observable<Int>
        let imageDidSelected: Observable<Data>
        let productTitle: ControlProperty<String?>
        let productCurrency: ControlProperty<Int>
        let productPrice: ControlProperty<String?>
        let prdouctDiscountedPrice: ControlProperty<String?>
        let productStock: ControlProperty<String?>
        let productDescriptionText: ControlProperty<String?>
        let doneDidTapped: ControlEvent<Void>
        let didReceiveSecret: Observable<String>
    }
    
    struct Output {
        let textViewPlaceholder: Driver<String>
        let requireSecret: Driver<AlertViewModel>
        let presentImagePicker: Driver<Void>
        let productImages: Driver<[(CellType, Data)]>
        let excessImageAlert: Driver<AlertViewModel>
        let validationFailureAlert: Driver<AlertViewModel>
        let registrationSuccessAlert: Driver<AlertViewModel>
        let registrationFailureAlert: Driver<AlertViewModel>
    }
    
    func transform(input: Input) -> Output {
        let textViewPlaceholderText = MarketCommon.descriptionTextViewPlaceHolder.rawValue
        
        let textViewPlaceholder = input.viewWillAppear
            .map{ textViewPlaceholderText }
            .asDriver(onErrorJustReturn: "")
        
        let pickerCellImage = input.viewWillAppear
            .map{ _ in [(CellType.imagePickerCell, Data())] }
        
        let selectedImage = input.imageDidSelected
            .map{ image in return [(CellType.productImageCell, image)] }
        
        let productImages = Observable.merge(pickerCellImage, selectedImage)
            .scan(into: []) { images, addedImage in
                images.append(contentsOf: addedImage) }
            .asDriver(onErrorJustReturn: [])
        
        let isAbleToPickImage: Observable<Bool> = productImages
            .asObservable()
            .map{ images in
                images.count < self.maximutProductImageCellCount }
        
        let presentImagePicker = input.imagePickerCellDidSelected
            .withLatestFrom(isAbleToPickImage) { row, isAbleToPickImage in
                return isAbleToPickImage }
            .filter{ $0 == true }
            .map{ _ in }
            .asDriver(onErrorJustReturn: ())
        
        let excessImageAlert = input.imagePickerCellDidSelected
            .withLatestFrom(isAbleToPickImage) { row, isAbleToPickImage in
                return isAbleToPickImage }
            .filter{ $0 == false }
            .map{ _ in ExecessImageAlertViewModel() as AlertViewModel }
            .asDriver(onErrorJustReturn: ErrorAlertViewModel() as AlertViewModel)
        
        let productCurrency = input.productCurrency.asObservable()

        let isValidImage = productImages.asObservable().map { images in images.count > 1 }
        let isValidName = self.validate(name: input.productTitle.asObservable())
        let isValidPrice = self.validate(price: input.productPrice.asObservable())
        let isValidStock = self.validate(stock: input.productStock.asObservable())
        let isvalidDescription = self.validate(description: input.productDescriptionText.asObservable())
        let isValidDiscountedPrice = self.validate(discountedPrice: input.prdouctDiscountedPrice.asObservable(), price: input.productPrice.asObservable())
        
        let validation = Observable.combineLatest(isValidImage, isValidName, isValidPrice, isValidStock, isvalidDescription, isValidDiscountedPrice, resultSelector: {
            self.validate(isValidImage: $0, isValidName: $1, isValidPrice: $2, isValidStock: $3, isValidDescription: $4, isValidDiscountedPrice: $5)})
            .share(replay: 1)
        
        let validationSuccess = validation
            .filter{ (result, descritption) in result == .success }
            .map{ _ in }
        
        let requireSecretAlert = input.doneDidTapped
            .withLatestFrom(validationSuccess)
            .map{ _ in RequireSecretAlertViewModel() as AlertViewModel }
            .asDriver(onErrorJustReturn: ErrorAlertViewModel() as AlertViewModel)
    
        let validationFailAlert = input.doneDidTapped
            .withLatestFrom(validation) { (request, validationResult) in return validationResult }
            .filter{ $0.0 == .failure }
            .map{ ValidationFailureAlertViewModel(title: $0.1, message: nil, actionTitle: MarketCommon.confirm.rawValue) as AlertViewModel }
            .asDriver(onErrorJustReturn: ErrorAlertViewModel() as AlertViewModel)
    
        let registrationFailureAlert = PublishSubject<AlertViewModel>()
        
        let newProductInfo = input.didReceiveSecret
            .flatMap{ secret -> Observable<NewProductInfo> in
                return Observable.combineLatest(input.productTitle.asObservable(), input.productPrice.asObservable(), input.prdouctDiscountedPrice.asObservable(), productCurrency, input.productStock.asObservable(), input.productDescriptionText.asObservable(), Observable.just(secret),
                                   resultSelector: { (name, price, discountedPrice, currency, stock, descritpion, secret) -> NewProductInfo in
                    return self.createNewProductInfo(name: name, price: price, currency: currency, discountedPrice: discountedPrice, stock: stock, description: descritpion, secret: secret)
                }) }
        
        let requestProductRegistration = newProductInfo.withLatestFrom(productImages,
                                                                       resultSelector: { newProductInfo, imgaes in
                 self.createRegistrationRequest(with: newProductInfo, productImages: imgaes) })
                 .flatMap{ request in self.APIService.requestRx(request) }
        
        let registerationSucessAlert = requestProductRegistration
            .do(onError: { _ in
                registrationFailureAlert.onNext(RegistrationFailureAlertViewModel()) })
            .retry(when: { _ in requireSecretAlert.asObservable() })
            .map{ _ in return RegistrationSuccessAlertViewModel() as AlertViewModel }
            .asDriver(onErrorJustReturn: ErrorAlertViewModel() as AlertViewModel)
        
        return Output(textViewPlaceholder: textViewPlaceholder,
                      requireSecret: requireSecretAlert,
                      presentImagePicker: presentImagePicker,
                      productImages: productImages,
                      excessImageAlert: excessImageAlert,
                      validationFailureAlert: validationFailAlert.asDriver(onErrorJustReturn: ErrorAlertViewModel() as AlertViewModel),
                      registrationSuccessAlert: registerationSucessAlert,
                      registrationFailureAlert: registrationFailureAlert .asDriver(onErrorJustReturn: ErrorAlertViewModel() as AlertViewModel))
    }
    
}

// MARK: - Alert View Model

extension ProductRegisterationSceneViewModel {
    
    struct ValidationFailureAlertViewModel: AlertViewModel {
        
        var title: String?
        var message: String?
        var actionTitle: String?
    
    }
 
    struct ExecessImageAlertViewModel: AlertViewModel {
        
        var title: String? = "사진은 최대 \(ProductRegisterationSceneViewModel.maximumProductImageCount)장까지 첨부할 수 있어요"
        var message: String? = nil
        var actionTitle: String? = "확인"
    }
    
    struct RequireSecretAlertViewModel: AlertViewModel {
        
        var title: String? = "판매자 비밀번호를 입력해주세요"
        var actionTitle: String? = "등록"
        var message: String?
        
    }
    
    struct RegistrationSuccessAlertViewModel: AlertViewModel {
        
        var title: String? = "성공적으로 등록되었습니다"
        var message: String?
        var actionTitle: String? = "상품 리스토로 돌아가기"
    }
    
    struct RegistrationFailureAlertViewModel: AlertViewModel {
        
        var title: String? = "등록에 실패했습니다"
        var message: String? = "다시 시도 해주세요"
        var actionTitle: String? = "확인"
    }
    
    // MARK: - Input Validation
    
    enum ValidationResult {
        
        case success
        case failure
    }
    
    private func validate(isValidImage: Bool,
                          isValidName: Bool,
                          isValidPrice: Bool,
                          isValidStock: Bool,
                          isValidDescription: Bool,
                          isValidDiscountedPrice: Bool) -> (ValidationResult, String?) {
        let category = [isValidImage, isValidName, isValidPrice, isValidStock, isValidDescription, isValidDiscountedPrice]
        
        if !isValidDiscountedPrice {
            return (ValidationResult.failure, "할인금액은 상품가격보다 클 수 없습니다.")
        }
        
        if category.contains(false) {
            let description = self.makeAlertDescription(isValidImage: isValidImage,
                                                        isValidName: isValidName,
                                                        isValidPrice: isValidPrice,
                                                        isValidStock: isValidStock,
                                                        isValidDescription: isValidDescription)
            return (ValidationResult.failure, description)
        } else {
            return (ValidationResult.success, nil)
        }
    }
    
    private func makeAlertDescription(isValidImage: Bool,
                                      isValidName: Bool,
                                      isValidPrice: Bool,
                                      isValidStock: Bool,
                                      isValidDescription: Bool) -> String {
        let image = isValidImage ? "" : "대표 사진"
        let name = isValidName ? "" : "상품명"
        let price = isValidPrice ? "" : "가격"
        let stock = isValidStock ? "" : "재고"
        let description = isValidDescription ? "" : "상세정보"
        
        if isValidName == true && isValidPrice == true
            && isValidStock == true && isValidDescription == false {
            return "상세정보는 10자이상 1,000자이하로 작성해주세요"
        } else {
            let categories = [image, name, price, stock, description]
           
            let description = categories
                .filter{ !$0.isEmpty }
                .reduce("") { partialResult, category in
                    partialResult.isEmpty ? category : "\(partialResult), \(category)" }
            
            if isValidDescription == false || isValidStock == false {
                return "\(description)는 필수 입력 항목이에요"
            } else {
                return "\(description)은 필수 입력 항목이에요"
            }
        }
    }
    
    private func validate(name: Observable<String?>) -> Observable<Bool> {
        return name.map{ name -> Bool in
            guard let name = name else { return false }
            return name.isEmpty ? false : true }
    }
    
    private func validate(price: Observable<String?>) -> Observable<Bool> {
        return price.map{ price -> Bool in
            guard let price = price else { return false }
            return price.isEmpty ? false : true }
    }
    
    private func validate(stock: Observable<String?>) -> Observable<Bool> {
        return stock.map{ stock -> Bool in
            guard let stock = stock else { return false }
            return stock.isEmpty ? false : true }
    }
    
    private func validate(description: Observable<String?>) -> Observable<Bool> {
        return description.map{ description -> Bool in
            guard let text = description else { return false }
            if text == MarketCommon.descriptionTextViewPlaceHolder.rawValue { return false }
            return text.count >= 10 && text.count <= 1000 ? true : false }
    }
    
    private func validate(discountedPrice: Observable<String?>, price: Observable<String?>) -> Observable<Bool> {
        return Observable.combineLatest(discountedPrice, price) { (discountedPrice, price) -> Bool in
            let disconutPrice = Int(discountedPrice ?? "") ?? 0
            let price = Int(price ?? "") ?? 0
            return disconutPrice <= price
        }
    }

    // MARK: - API Request
    
    private func createRegistrationRequest(with productInfo: NewProductInfo, productImages: [(CellType, Data)]) -> ProductRegistrationRequest {
        let imageDatas = productImages.filter{ image in image.0 == .productImageCell }
            .map{ image in image.1 }
        let imageFiles = imageDatas.imageFile(fileName: productInfo.name)
        let registrationRequest = ProductRegistrationRequest(identifier: SellerInformation.identifier.rawValue,
                                                             params: productInfo,
                                                             images: imageFiles)
        return registrationRequest
    }
    
    private func createNewProductInfo(name: String?,
                                      price: String?,
                                      currency: Int?,
                                      discountedPrice: String?,
                                      stock: String?,
                                      description: String?,
                                      secret: String) -> NewProductInfo {
        let currency: Currency = currency == .zero ? .krw : .usd
        guard let name = name,
              let price = price,
              let discountedPrice = discountedPrice,
              let stock = stock,
              let description = description else {
            return NewProductInfo(name: "",
                                  descriptions: "",
                                  price: 0,
                                  currency: .usd,
                                  discountedPrice: 0,
                                  stock: 0,
                                  secret: "")
        }

        return NewProductInfo(
            name: name,
            descriptions: description,
            price: (price as NSString).doubleValue,
            currency: currency.toEntity(),
            discountedPrice: ( discountedPrice as NSString).doubleValue,
            stock: (stock as NSString).integerValue,
            secret: secret )
    }
    
}
