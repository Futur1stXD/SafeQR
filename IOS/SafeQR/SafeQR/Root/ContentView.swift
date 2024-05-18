//
//  ContentView.swift
//  SafeQR
//
//  Created by Abylaykhan Myrzakhanov on 11.04.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem {
                    Label(
                        title: { Text("QR") },
                        icon: { Image(systemName: "qrcode.viewfinder") }
                    )
                }
                .tag(0)
        }
    }
}

#Preview {
    ContentView()
}
