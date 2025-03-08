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
                "注釈付きPDFを画像に変換",
                "\(.applicationName)でPDFを画像に変換",
                "PDFの注釈を保持して画像化"
            ],
            shortTitle: "PDF画像変換",
            systemImageName: "doc.on.doc"
        )
    }
}
