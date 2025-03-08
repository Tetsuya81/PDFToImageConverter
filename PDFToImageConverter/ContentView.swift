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
                
                Text("PDF Annotation Image Conversion")
                    .font(.title)
                    .bold()
                
                Text("This app converts a PDF file (including annotations) into a single image.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("You can use this app's actions in Shortcuts.app.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("PDF Conversion")
        }
    }
}

#Preview {
    ContentView()
}
