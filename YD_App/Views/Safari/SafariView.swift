//
//  SafariView.swift
//  YD_App
//
//  Created by Luis Melendez on 09/05/25.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = false
    return SFSafariViewController(url: url, configuration: config)
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}
