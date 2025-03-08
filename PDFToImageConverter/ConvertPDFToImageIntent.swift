//
//  ConvertPDFToImageIntent.swift
//  PDFToImageConverter
//
//  Created by Tokunaga Tetsuya on 2025/03/08.
//
import SwiftUI
import AppIntents
import PDFKit
import UniformTypeIdentifiers

struct ConvertPDFToImageIntent: AppIntent {
    static var title: LocalizedStringResource = "PDFを画像に変換"
    static var description: IntentDescription = IntentDescription("注釈付きPDFを1枚の画像に変換します")
    
    // 入力パラメータ: PDFファイル
    @Parameter(title: "PDFファイル")
    var pdfFile: IntentFile
    
    @Parameter(title: "画像品質", default: 1.0)
    var quality: Double
    
    @Parameter(title: "画像フォーマット", default: ImageFormat.png)
    var imageFormat: ImageFormat
    
    enum ImageFormat: String, AppEnum {
        case png
        case jpeg
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            return TypeDisplayRepresentation(name: "画像フォーマット")
        }
        
        static var caseDisplayRepresentations: [ImageFormat : DisplayRepresentation] = [
            .png: DisplayRepresentation(title: "PNG"),
            .jpeg: DisplayRepresentation(title: "JPEG")
        ]
    }
    
    // 出力型の定義
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // PDFデータを取得
        guard let pdfData = pdfFile.data else {
            throw Error.invalidPDFData
        }
        
        // PDFを画像に変換
        guard let convertedImageData = try await convertPDFToImage(pdfData: pdfData) else {
            throw Error.conversionFailed
        }
        
        // 画像フォーマットの処理
        let mimeType: String
        let finalImageData: Data
        
        switch imageFormat {
        case .png:
            mimeType = "image/png"
            finalImageData = convertedImageData
        case .jpeg:
            mimeType = "image/jpeg"
            // PNG画像をJPEGに変換
            guard let image = UIImage(data: convertedImageData),
                  let jpegData = image.jpegData(compressionQuality: CGFloat(quality)) else {
                throw Error.conversionFailed
            }
            finalImageData = jpegData
        }
        
        // 結果のファイルを作成
        let fileName = (pdfFile.filename ?? "document").replacingOccurrences(of: ".pdf", with: "") +
                       (imageFormat == .png ? ".png" : ".jpg")
        
        let resultFile = IntentFile(data: finalImageData, filename: fileName, type: UTType(mimeType: mimeType)!)
        
        return .result(value: resultFile)
    }
    
    // エラー定義
    enum Error: Swift.Error {
        case invalidPDFData
        case conversionFailed
    }
    
    // PDFを画像に変換する関数
    private func convertPDFToImage(pdfData: Data) async throws -> Data? {
        return try await Task.detached(priority: .userInitiated) {
            // PDFドキュメントを作成
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                return nil
            }
            
            // ページ数を取得
            let pageCount = pdfDocument.pageCount
            guard pageCount > 0 else { return nil }
            
            // 全てのページを含む一つの画像を作成
            var totalHeight: CGFloat = 0
            var maxWidth: CGFloat = 0
            var pageRects: [CGRect] = []
            var pageImages: [UIImage] = []
            
            // まず各ページのサイズを計算
            for i in 0..<pageCount {
                guard let page = pdfDocument.page(at: i) else { continue }
                
                let pageRect = page.bounds(for: .mediaBox)
                pageRects.append(pageRect)
                
                totalHeight += pageRect.height
                maxWidth = max(maxWidth, pageRect.width)
            }
            
            // 全ページを含む画像の大きさを決定
            let totalSize = CGSize(width: maxWidth, height: totalHeight)
            
            // UIGraphicsImageRendererでレンダリング
            let renderer = UIGraphicsImageRenderer(size: totalSize)
            
            let pngData = renderer.pngData { context in
                let cgContext = context.cgContext
                
                var yOffset: CGFloat = 0
                
                // 各ページを描画
                for i in 0..<pageCount {
                    guard let page = pdfDocument.page(at: i) else { continue }
                    let pageRect = pageRects[i]
                    
                    // 現在のページの位置を計算
                    let drawingRect = CGRect(
                        x: 0,
                        y: yOffset,
                        width: pageRect.width,
                        height: pageRect.height
                    )
                    
                    // コンテキストの状態を保存
                    cgContext.saveGState()
                    
                    // ページを描画
                    cgContext.translateBy(x: 0, y: totalSize.height - yOffset - pageRect.height)
                    page.draw(with: .mediaBox, to: cgContext)
                    
                    // コンテキストの状態を復元
                    cgContext.restoreGState()
                    
                    // Y位置を更新
                    yOffset += pageRect.height
                }
            }
            
            return pngData
        }
    }
}
