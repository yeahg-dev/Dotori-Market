//
//  ProductTableViewController.swift
//  OpenMarket
//
//  Created by 예거 on 2022/01/12.
//

import UIKit

class ProductTableViewController: UITableViewController {
    
    private var currentPageNo: Int = .zero
    private var hasNextPage: Bool = false
    private var products: [Product] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        downloadProductsListPage(number: 1)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withClass: ProductTableViewCell.self,
            for: indexPath
        )
        
        guard let product = products[safe: indexPath.row] else {
            return cell
        }
        
        cell.configureTableContent(with: product)
        
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let paginationBuffer = 3
        guard indexPath.row >= products.count - paginationBuffer,
              hasNextPage == true else { return }
        
        downloadProductsListPage(number: currentPageNo + 1)
    }
    
    // MARK: - Custom function
    
    private func downloadProductsListPage(number: Int) {
        let request = ProductsListPageRequest(pageNo: number, itemsPerPage: 20)
        APIExecutor().execute(request) { (result: Result<ProductsListPage, Error>) in
            switch result {
            case .success(let productsListPage):
                self.currentPageNo = productsListPage.pageNo
                self.hasNextPage = productsListPage.hasNext
                self.products.append(contentsOf: productsListPage.pages)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                // Alert 넣기
                print("ProductsListPage 통신 중 에러 발생 : \(error)")
                return
            }
        }
    }
}

// MARK: - UITableView Extension

private extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell>(
        withClass name: T.Type,
        for indexPath: IndexPath
    ) -> T {
        guard let cell = dequeueReusableCell(
            withIdentifier: String(describing: name),
            for: indexPath
        ) as? T else {
            fatalError(
                "Couldn't find UITableViewCell for \(String(describing: name)), make sure the cell is registered with table view")
        }
        return cell
    }
}
