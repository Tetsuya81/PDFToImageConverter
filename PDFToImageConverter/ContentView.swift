//
//  ContentView.swift
//  PDFToImageConverter
//
//  Created by Tokunaga Tetsuya on 2025/03/08.
//

import SwiftUI
import AppIntents
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.on.doc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("PDFアノテーション画像変換")
                    .font(.title)
                    .bold()
                
                Text("このアプリはPDFファイル（注釈を含む）を1枚の画像に変換します。")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Shortcuts.appでこのアプリのアクションを使用できます。")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("PDF変換")
        }
    }
}

#Preview {
    ContentView()
}
