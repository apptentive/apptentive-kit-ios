//
//  WebViewController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/19/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    let webView: WKWebView
    let spinner: UIActivityIndicatorView
    let viewModel: NavigateToLinkController

    init(viewModel: NavigateToLinkController) {
        self.viewModel = viewModel

        self.webView = WKWebView(frame: .zero)
        self.spinner = UIActivityIndicatorView(style: .large)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.webView.frame = self.view.bounds
        self.view.addSubview(self.webView)

        self.webView.navigationDelegate = self

        self.spinner.hidesWhenStopped = true
        self.view.addSubview(self.spinner)
        self.spinner.startAnimating()
        self.spinner.center = self.view.center

        self.navigationItem.rightBarButtonItem = .apptentiveClose
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(close)
        self.navigationItem.rightBarButtonItem?.accessibilityLabel = self.viewModel.closeButtonAccessibilityLabel
        self.navigationItem.rightBarButtonItem?.accessibilityHint = self.viewModel.closeButtonAccessibilityHint

        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.spinner.startAnimating()
        let request = URLRequest(url: self.viewModel.configuration.url)
        self.webView.load(request)
    }

    @objc func close() {
        self.dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.spinner.stopAnimating()
    }
}
