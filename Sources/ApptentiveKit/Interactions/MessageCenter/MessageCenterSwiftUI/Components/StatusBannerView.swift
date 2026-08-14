//
//  StatusBannerView.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/07/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Centred status text shown below the message list (e.g. expected response time).
struct StatusBannerView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Color(uiColor: .apptentiveMessageCenterStatus))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}
