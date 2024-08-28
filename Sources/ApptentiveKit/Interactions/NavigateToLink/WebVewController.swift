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
    var urlRequest: URLRequest {
        var urlComponents = URLComponents(url: self.viewModel.configuration.url, resolvingAgainstBaseURL: false)
        urlComponents?.scheme = "https"
        return URLRequest(url: urlComponents?.url ?? self.viewModel.configuration.url)
    }

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
        super.viewDidLoad()

        self.webView.navigationDelegate = self

        self.view.addSubview(self.webView)
        self.view.addSubview(self.spinner)

        self.spinner.hidesWhenStopped = true
        self.spinner.startAnimating()
        self.spinner.center = self.view.center

        self.navigationItem.rightBarButtonItem = .apptentiveClose
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(close)
        self.navigationItem.rightBarButtonItem?.accessibilityLabel = self.viewModel.closeButtonAccessibilityLabel
        self.navigationItem.rightBarButtonItem?.accessibilityHint = self.viewModel.closeButtonAccessibilityHint

        self.navigationItem.leftBarButtonItem = .appentiveRefresh
        self.navigationItem.leftBarButtonItem?.target = self
        self.navigationItem.leftBarButtonItem?.action = #selector(refresh)
        self.navigationItem.leftBarButtonItem?.accessibilityLabel = self.viewModel.refreshButtonAccessibilityLabel
        self.navigationItem.leftBarButtonItem?.accessibilityHint = self.viewModel.refreshButtonAccessibilityHint

        self.setupConstraints()
        self.checkPermissions()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.spinner.startAnimating()
        self.webView.load(self.urlRequest)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.spinner.center = self.view.center
    }

    func checkPermissions() {
        let cameraUsageDescription = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
        let microphoneUsageDescription = Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String

        if cameraUsageDescription == nil {
            apptentiveCriticalError("NSCameraUsageDescription is missing from Info.plist. Please add it to prevent the app from crashing when accessing the camera.")
        }

        if microphoneUsageDescription == nil {
            apptentiveCriticalError("NSMicrophoneUsageDescription is missing from Info.plist. Please add it to prevent the app from crashing when accessing the microphone.")
        }
    }

    func setupConstraints() {
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.spinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

            self.spinner.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.spinner.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
    }

    @objc func close() {
        self.dismiss(animated: true)
    }

    @objc func refresh() {
        self.webView.load(self.urlRequest)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.spinner.stopAnimating()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.absoluteString.contains("survey.alchemer.com") || url.absoluteString.contains("#sg-gotoerror") {
                decisionHandler(.allow)
            } else {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}
