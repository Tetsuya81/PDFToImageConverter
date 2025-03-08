//
//  PDFShortcuts.swift
//  PDFToImageConverter
//
//  Created by Tokunaga Tetsuya on 2025/03/08.
//
import SwiftUI
import AppIntents
import PDFKit
import UniformTypeIdentifiers

struct PDFShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ConvertPDFToImageIntent(),
            phrases: [
                "Convert annotated PDF to image",
                "Convert PDF to image with \(.applicationName)",
                "Convert PDF to image while preserving annotations"
            ],
            shortTitle: "PDF Image Conversion",
            systemImageName: "doc.on.doc"
        )
    }
}
