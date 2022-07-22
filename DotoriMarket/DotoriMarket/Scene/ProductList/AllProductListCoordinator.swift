//
//  ALLProductListCoordinator.swift
//  DotoriMarket
//
//  Created by 1 on 2022/07/19.
//

import UIKit

protocol ProductListCoordinator: Coordinator {
    
    func rightNavigationItemDidTapped(from: UIViewController)
    func pushProuductDetail(of productID: Int) 
    
}

class AllProductListCoordinator: ProductListCoordinator {
    
    var childCoordinator = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init () {
        self.navigationController = UINavigationController()
    }
    
    func start() {
        let productListVC = ProductCollectionViewController.make(coordinator: self)
        self.navigationController.pushViewController(productListVC,
                                                     animated: false)
    }
    
    func pushProuductDetail(of productID: Int) {
        let productDetailVC = UIStoryboard.initiateViewController(ProductDetailViewController.self)
        productDetailVC.setProduct(productID)
        self.navigationController.setNavigationBarHidden(false, animated: false)
        self.navigationController.pushViewController(productDetailVC,
                                                     animated: true)
    }
    
    func rightNavigationItemDidTapped(from vc: UIViewController) {
        if vc.className == ProductCollectionViewController.className {
            let productListVC = ProductListViewFactory().make(
                viewType: .allProduct,
                coordinator: self)
            self.navigationController.setViewControllers([productListVC],
                                                         animated: false)
        } else {
            let productListVC = ProductCollectionViewController.make(coordinator: self)
            self.navigationController.setViewControllers([productListVC],
                                                         animated: false)
        }
    }
    
}

extension AllProductListCoordinator: TabCoordinator {
    
    func tabViewController() -> UINavigationController {
        self.start()
        return self.navigationController
    }
    
}
