//
//  InstagramLoginViewController.swift
//  SwiftInstagram
//
//  Created by Ander Goig on 8/9/17.
//  Copyright © 2017 Ander Goig. All rights reserved.
//

import UIKit
import WebKit

public class InstagramLoginViewController: UIViewController {
    
    // MARK: - Types
    
    typealias SuccessHandler = (_ accesToken: String) -> Void
    typealias FailureHandler = (_ error: InstagramError?) -> Void
    
    // MARK: - Properties
    
    private var authURL: URL
    private var success: SuccessHandler?
    private var failure: FailureHandler?
    
    private var progressView: UIProgressView!
    private var webViewObservation: NSKeyValueObservation!
    
    private weak var toolbar: UIToolbar!
    private weak var webView: WKWebView!
    
    private var backItem: UIBarButtonItem!
    private var fwdItem: UIBarButtonItem!
    
    // MARK: - Initializers
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(authURL: URL, success: SuccessHandler?, failure: FailureHandler?) {
        self.authURL = authURL
        self.success = success
        self.failure = failure
        
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // Initializes progress view
        setupProgressView()
        
        // Initializes web view
        webView = setupWebView()
        
        // Starts authorization
        webView.load(URLRequest(url: authURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close(_:)))
        
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        toolbar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        toolbar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        let bndl = Bundle(for: type(of: self))
        
        let back = UIBarButtonItem(
            image: UIImage(named: "browser_back", in: bndl, compatibleWith: nil),
            style: .plain, target: nil, action: #selector(browserBack(_:)))
        
        let fix1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fix1.width = 24
        
        let forward = UIBarButtonItem(
            image: UIImage(named: "browser_forward", in: bndl, compatibleWith: nil), style: .plain, target: nil,
            action: #selector(browserForward(_:)))
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let reload = UIBarButtonItem(
            image: UIImage(named: "browser_reload", in: bndl, compatibleWith: nil), style: .plain, target: nil,
            action: #selector(browserReload(_:)))
        
        toolbar.tintColor = .black
        toolbar.items = [back, fix1, forward, flex, reload]
        
        backItem = back
        fwdItem = forward
        updateNavigationButtons()
    }
    
    deinit {
        progressView.removeFromSuperview()
        webViewObservation.invalidate()
    }
    
    // MARK: -
    
    private func setupProgressView() {
        let navBar = navigationController!.navigationBar
        
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.tintColor = UIColor(red: 103/255.0, green: 79/255.0, blue: 241/255.0, alpha: 1.0)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        navBar.addSubview(progressView)
        
        let bottomConstraint = navBar.bottomAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 1)
        let leftConstraint = navBar.leadingAnchor.constraint(equalTo: progressView.leadingAnchor)
        let rightConstraint = navBar.trailingAnchor.constraint(equalTo: progressView.trailingAnchor)
        
        NSLayoutConstraint.activate([bottomConstraint, leftConstraint, rightConstraint])
    }
    
    private func setupWebView() -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent()
        
        let webView = WKWebView(frame: view.frame, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        
        webViewObservation = webView.observe(\.estimatedProgress, changeHandler: progressViewChangeHandler)
        
        view.addSubview(webView)
        
        return webView
    }
    
    private func progressViewChangeHandler<Value>(webView: WKWebView, change: NSKeyValueObservedChange<Value>) {
        progressView.alpha = 1.0
        progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        
        if webView.estimatedProgress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
                self.progressView.alpha = 0.0
            }, completion: { (_ finished) in
                self.progressView.progress = 0
            })
        }
    }
    
    @objc private func browserBack(_ sender: UIBarButtonItem) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func browserForward(_ sender: UIBarButtonItem) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc private func browserReload(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @objc private func close(_ sender: UIBarButtonItem) {
        failure?(nil)
    }
    
}

// MARK: - WKNavigationDelegate

extension InstagramLoginViewController: WKNavigationDelegate {
    
    func updateNavigationButtons() {
        backItem.isEnabled = webView.canGoBack
        fwdItem.isEnabled = webView.canGoForward
    }
    
    func updateScrollViewOffset() {
        let topOffset: CGFloat
        
        if #available(iOS 11.0, *) {
            topOffset = view.safeAreaInsets.top
        } else {
            topOffset = topLayoutGuide.length
        }
        
        webView.scrollView.contentInset = UIEdgeInsetsMake(topOffset, webView.scrollView.contentInset.left, webView.scrollView.contentInset.right, webView.scrollView.contentInset.bottom)
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: -topOffset), animated: false)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationItem.title = webView.title
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let urlString = navigationAction.request.url!.absoluteString
        
        guard let range = urlString.range(of: "#access_token=") else {
            decisionHandler(.allow)
            return
        }
        
        decisionHandler(.cancel)
        
        DispatchQueue.main.async {
            self.success?(String(urlString[range.upperBound...]))
        }
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        guard let httpResponse = navigationResponse.response as? HTTPURLResponse else {
            updateScrollViewOffset()
            updateNavigationButtons()
            decisionHandler(.allow)
            return
        }
        
        switch httpResponse.statusCode {
        case 400:
            decisionHandler(.cancel)
            DispatchQueue.main.async {
                self.failure?(InstagramError.badRequest)
            }
        default:
            updateScrollViewOffset()
            updateNavigationButtons()
            decisionHandler(.allow)
        }
    }
}
