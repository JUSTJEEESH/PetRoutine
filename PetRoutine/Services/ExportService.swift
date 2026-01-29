import SwiftUI
import PDFKit

@MainActor
final class ExportService {

    static func generatePDF(
        petName: String,
        sections: [(title: String, rows: [(label: String, value: String)])]
    ) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            var yOffset: CGFloat = 0

            func beginPageIfNeeded(requiredSpace: CGFloat = 60) {
                if yOffset + requiredSpace > pageHeight - margin || yOffset == 0 {
                    context.beginPage()
                    yOffset = margin
                }
            }

            // Title page
            beginPageIfNeeded()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let title = "\(petName) — Care Report"
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
            yOffset += 40

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Generated: \(dateFormatter.string(from: Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            dateString.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: dateAttributes)
            yOffset += 30

            // Sections
            let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.label
            ]

            for section in sections {
                beginPageIfNeeded(requiredSpace: 80)

                yOffset += 10
                section.title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttributes)
                yOffset += 28

                for row in section.rows {
                    beginPageIfNeeded(requiredSpace: 30)

                    row.label.draw(
                        in: CGRect(x: margin, y: yOffset, width: 150, height: 16),
                        withAttributes: labelAttributes
                    )
                    let valueRect = CGRect(x: margin + 160, y: yOffset, width: contentWidth - 160, height: 16)
                    row.value.draw(in: valueRect, withAttributes: valueAttributes)
                    yOffset += 20
                }
            }
        }
    }
}
