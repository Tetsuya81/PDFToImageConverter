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
    static var title: LocalizedStringResource = "Convert PDF to Image"
    static var description: IntentDescription = IntentDescription("Converts an annotated PDF into a single image")
    
    // Input parameter: PDF File
    @Parameter(title: "PDF File")
    var pdfFile: IntentFile
    
    @Parameter(title: "Image Quality", default: 1.0)
    var quality: Double
    
    @Parameter(title: "Image Format", default: ImageFormat.png)
    var imageFormat: ImageFormat
    
    enum ImageFormat: String, AppEnum {
        case png
        case jpeg
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            return TypeDisplayRepresentation(name: "Image Format")
        }
        
        static var caseDisplayRepresentations: [ImageFormat : DisplayRepresentation] = [
            .png: DisplayRepresentation(title: "PNG"),
            .jpeg: DisplayRepresentation(title: "JPEG")
        ]
    }
    
    // Definition of output type
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // Retrieve PDF data
        // Error Fix 1: Check for data existence
        guard let pdfData = try? pdfFile.data else {
            throw Error.invalidPDFData
        }
        
        // Convert PDF to image
        guard let convertedImageData = try await convertPDFToImage(pdfData: pdfData) else {
            throw Error.conversionFailed
        }
        
        // Process image format
        let mimeType: String
        let finalImageData: Data
        
        switch imageFormat {
        case .png:
            mimeType = "image/png"
            finalImageData = convertedImageData
        case .jpeg:
            mimeType = "image/jpeg"
            // Convert PNG image to JPEG
            guard let image = UIImage(data: convertedImageData),
                  let jpegData = image.jpegData(compressionQuality: CGFloat(quality)) else {
                throw Error.conversionFailed
            }
            finalImageData = jpegData
        }
        
        // Create result file
        let fileName = (pdfFile.filename ?? "document").replacingOccurrences(of: ".pdf", with: "") +
                       (imageFormat == .png ? ".png" : ".jpg")
        
        let resultFile = IntentFile(data: finalImageData, filename: fileName, type: UTType(mimeType: mimeType)!)
        
        return .result(value: resultFile)
    }
    
    // Error definitions
    enum Error: Swift.Error {
        case invalidPDFData
        case conversionFailed
    }
    
    // Function to convert PDF to image
    private func convertPDFToImage(pdfData: Data) async throws -> Data? {
        return try await Task.detached(priority: .userInitiated) {
            // Create PDF document
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                return nil as Data? // Error Fix 2: Specify explicit type for nil
            }
            
            // Get page count
            let pageCount = pdfDocument.pageCount
            guard pageCount > 0 else { return nil as Data? }
            
            // Create a single image that includes all pages
            var totalHeight: CGFloat = 0
            var maxWidth: CGFloat = 0
            var pageRects: [CGRect] = []
            var pageImages: [UIImage] = []
            
            // First, calculate the size of each page
            for i in 0..<pageCount {
                guard let page = pdfDocument.page(at: i) else { continue }
                
                let pageRect = page.bounds(for: .mediaBox)
                pageRects.append(pageRect)
                
                totalHeight += pageRect.height
                maxWidth = max(maxWidth, pageRect.width)
            }
            
            // Determine the size of the image that includes all pages
            let totalSize = CGSize(width: maxWidth, height: totalHeight)
            
            // Render using UIGraphicsImageRenderer
            let renderer = UIGraphicsImageRenderer(size: totalSize)
            
            let pngData = renderer.pngData { context in
                let cgContext = context.cgContext
                
                var yOffset: CGFloat = 0
                
                // Render each page
                for i in 0..<pageCount {
                    guard let page = pdfDocument.page(at: i) else { continue }
                    let pageRect = pageRects[i]
                    
                    // Calculate the position of the current page
                    let drawingRect = CGRect(
                        x: 0,
                        y: yOffset,
                        width: pageRect.width,
                        height: pageRect.height
                    )
                    
                    // Save context state
                    cgContext.saveGState()
                    
                    // Move to appropriate position
                    cgContext.translateBy(x: 0, y: yOffset)
                    
                    // Correct PDF coordinate system (fix inversion)
                    cgContext.scaleBy(x: 1.0, y: -1.0)
                    cgContext.translateBy(x: 0, y: -pageRect.height)
                    
                    // Draw the page
                    page.draw(with: .mediaBox, to: cgContext)
                    
                    // Restore context state
                    cgContext.restoreGState()
                    
                    // Update Y offset
                    yOffset += pageRect.height
                }
            }
            
            return pngData
        }.value
    }
}
