import UIKit

// MARK: - Markdown Token Types

enum MarkdownLineType {
  case h1(String)
  case h2(String)
  case h3(String)
  case bold
  case italic
  case unorderedList(indent: Int, content: String)
  case orderedList(indent: Int, number: Int, content: String)
  case checklist(indent: Int, checked: Bool, content: String)
  case codeBlockDelimiter
  case codeBlockContent
  case inlineCode
  case link
  case paragraph
}

// MARK: - Style Constants

enum MarkdownStyle {
  static let bodyFont = UIFont.systemFont(ofSize: 17, weight: .regular)
  static let h1Font = UIFont.systemFont(ofSize: 28, weight: .bold)
  static let h2Font = UIFont.systemFont(ofSize: 22, weight: .bold)
  static let h3Font = UIFont.systemFont(ofSize: 18, weight: .semibold)
  static let codeFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)

  static let bodyColor = UIColor.label
  static let h1Color = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1.0)
  static let syntaxColor = UIColor.tertiaryLabel
  static let codeBackground = UIColor.secondarySystemBackground
  static let linkColor = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1.0)

  static let bodyLineSpacing: CGFloat = 6.8
  static let headingLineSpacing: CGFloat = 4.8
}

// MARK: - MarkdownStyler

final class MarkdownStyler {
  private let h1Regex = try? NSRegularExpression(pattern: #"^(# )(.+)$"#)
  private let h2Regex = try? NSRegularExpression(pattern: #"^(## )(.+)$"#)
  private let h3Regex = try? NSRegularExpression(pattern: #"^(### )(.+)$"#)
  private let boldRegex = try? NSRegularExpression(pattern: #"(\*\*)(.+?)(\*\*)"#)
  private let italicRegex = try? NSRegularExpression(pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#)
  private let inlineCodeRegex = try? NSRegularExpression(pattern: #"`([^`]+)`"#)
  private let linkRegex = try? NSRegularExpression(pattern: #"\[(.+?)\]\((.+?)\)"#)
  private let unorderedListRegex = try? NSRegularExpression(pattern: #"^(\s*)([-*])\s+(.*)$"#)
  private let orderedListRegex = try? NSRegularExpression(pattern: #"^(\s*)(\d+)\.\s+(.*)$"#)
  private let checklistRegex = try? NSRegularExpression(pattern: #"^(\s*)- \[([ x])\]\s+(.*)$"#)
  private let codeBlockDelimiterRegex = try? NSRegularExpression(pattern: #"^```"#)

  func styleText(in textStorage: NSTextStorage) {
    let fullString = textStorage.string
    guard !fullString.isEmpty else { return }

    let fullRange = NSRange(location: 0, length: textStorage.length)

    textStorage.beginEditing()
    textStorage.setAttributes(defaultAttributes(), range: fullRange)

    var isInsideCodeBlock = false
    var lineStart = fullString.startIndex

    while lineStart < fullString.endIndex {
      let lineEnd = fullString.lineRangeEnd(from: lineStart)
      let lineRange = lineStart ..< lineEnd
      let nsLineRange = NSRange(lineRange, in: fullString)
      let lineText = String(fullString[lineRange]).trimmingCharacters(in: .newlines)

      if checkCodeBlockDelimiter(lineText) {
        isInsideCodeBlock.toggle()
        applyCodeBlockDelimiterStyle(to: textStorage, range: nsLineRange)
      } else if isInsideCodeBlock {
        applyCodeBlockContentStyle(to: textStorage, range: nsLineRange)
      } else {
        applyLineStyle(to: textStorage, line: lineText, range: nsLineRange, fullString: fullString)
      }

      if lineEnd >= fullString.endIndex { break }
      lineStart = lineEnd
    }

    textStorage.endEditing()
  }

  // MARK: - Private Helpers

  private func defaultAttributes() -> [NSAttributedString.Key: Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = MarkdownStyle.bodyLineSpacing
    return [
      .font: MarkdownStyle.bodyFont,
      .foregroundColor: MarkdownStyle.bodyColor,
      .paragraphStyle: paragraphStyle,
    ]
  }

  private func checkCodeBlockDelimiter(_ line: String) -> Bool {
    guard let regex = codeBlockDelimiterRegex else { return false }
    let range = NSRange(line.startIndex..., in: line)
    return regex.firstMatch(in: line, range: range) != nil
  }

  private func applyCodeBlockDelimiterStyle(to storage: NSTextStorage, range: NSRange) {
    storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: range)
    storage.addAttribute(.font, value: MarkdownStyle.codeFont, range: range)
  }

  private func applyCodeBlockContentStyle(to storage: NSTextStorage, range: NSRange) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = MarkdownStyle.bodyLineSpacing

    storage.addAttribute(.font, value: MarkdownStyle.codeFont, range: range)
    storage.addAttribute(.foregroundColor, value: MarkdownStyle.bodyColor, range: range)
    storage.addAttribute(.backgroundColor, value: MarkdownStyle.codeBackground, range: range)
    storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
  }

  private func applyLineStyle(
    to storage: NSTextStorage,
    line: String,
    range: NSRange,
    fullString: String
  ) {
    if applyHeadingStyle(to: storage, line: line, range: range) { return }
    if applyChecklistStyle(to: storage, line: line, range: range, fullString: fullString) { return }
    if applyUnorderedListStyle(to: storage, line: line, range: range, fullString: fullString) { return }
    if applyOrderedListStyle(to: storage, line: line, range: range, fullString: fullString) { return }

    applyInlineStyles(to: storage, range: range, fullString: fullString)
  }

  @discardableResult
  private func applyHeadingStyle(to storage: NSTextStorage, line: String, range: NSRange) -> Bool {
    let nsLine = line as NSString
    let lineRange = NSRange(location: 0, length: nsLine.length)

    let headingStyle = NSMutableParagraphStyle()
    headingStyle.lineSpacing = MarkdownStyle.headingLineSpacing

    if let regex = h1Regex, let match = regex.firstMatch(in: line, range: lineRange) {
      let markerRange = adjustRange(match.range(at: 1), offset: range.location)
      let contentRange = adjustRange(match.range(at: 2), offset: range.location)
      storage.addAttribute(.font, value: MarkdownStyle.h1Font, range: range)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.h1Color, range: contentRange)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerRange)
      storage.addAttribute(.paragraphStyle, value: headingStyle, range: range)
      return true
    }

    if let regex = h2Regex, let match = regex.firstMatch(in: line, range: lineRange) {
      let markerRange = adjustRange(match.range(at: 1), offset: range.location)
      let contentRange = adjustRange(match.range(at: 2), offset: range.location)
      storage.addAttribute(.font, value: MarkdownStyle.h2Font, range: range)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.bodyColor, range: contentRange)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerRange)
      storage.addAttribute(.paragraphStyle, value: headingStyle, range: range)
      return true
    }

    if let regex = h3Regex, let match = regex.firstMatch(in: line, range: lineRange) {
      let markerRange = adjustRange(match.range(at: 1), offset: range.location)
      let contentRange = adjustRange(match.range(at: 2), offset: range.location)
      storage.addAttribute(.font, value: MarkdownStyle.h3Font, range: range)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.bodyColor, range: contentRange)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerRange)
      storage.addAttribute(.paragraphStyle, value: headingStyle, range: range)
      return true
    }

    return false
  }

  @discardableResult
  private func applyChecklistStyle(
    to storage: NSTextStorage,
    line: String,
    range: NSRange,
    fullString: String
  ) -> Bool {
    guard let regex = checklistRegex else { return false }
    let nsLine = line as NSString
    let lineRange = NSRange(location: 0, length: nsLine.length)
    guard let match = regex.firstMatch(in: line, range: lineRange) else { return false }

    let indentRange = adjustRange(match.range(at: 1), offset: range.location)
    let checkboxRange = adjustRange(match.range(at: 2), offset: range.location)
    let contentRange = adjustRange(match.range(at: 3), offset: range.location)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = MarkdownStyle.bodyLineSpacing
    paragraphStyle.headIndent = 24
    paragraphStyle.firstLineHeadIndent = 0

    storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: indentRange)

    let markerNSRange = NSRange(
      location: range.location + match.range(at: 1).length,
      length: 5
    )
    if markerNSRange.location + markerNSRange.length <= storage.length {
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerNSRange)
    }

    if contentRange.location != NSNotFound, contentRange.length > 0 {
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.bodyColor, range: contentRange)
    }

    applyInlineStyles(to: storage, range: contentRange, fullString: fullString)
    return true
  }

  @discardableResult
  private func applyUnorderedListStyle(
    to storage: NSTextStorage,
    line: String,
    range: NSRange,
    fullString: String
  ) -> Bool {
    guard let regex = unorderedListRegex else { return false }
    let nsLine = line as NSString
    let lineRange = NSRange(location: 0, length: nsLine.length)
    guard let match = regex.firstMatch(in: line, range: lineRange) else { return false }

    let markerRange = adjustRange(match.range(at: 2), offset: range.location)
    let contentRange = adjustRange(match.range(at: 3), offset: range.location)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = MarkdownStyle.bodyLineSpacing
    paragraphStyle.headIndent = 20
    paragraphStyle.firstLineHeadIndent = 0

    storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerRange)

    if contentRange.location != NSNotFound, contentRange.length > 0 {
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.bodyColor, range: contentRange)
      applyInlineStyles(to: storage, range: contentRange, fullString: fullString)
    }

    return true
  }

  @discardableResult
  private func applyOrderedListStyle(
    to storage: NSTextStorage,
    line: String,
    range: NSRange,
    fullString: String
  ) -> Bool {
    guard let regex = orderedListRegex else { return false }
    let nsLine = line as NSString
    let lineRange = NSRange(location: 0, length: nsLine.length)
    guard let match = regex.firstMatch(in: line, range: lineRange) else { return false }

    let numberRange = adjustRange(match.range(at: 2), offset: range.location)
    let contentRange = adjustRange(match.range(at: 3), offset: range.location)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = MarkdownStyle.bodyLineSpacing
    paragraphStyle.headIndent = 24
    paragraphStyle.firstLineHeadIndent = 0

    storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: numberRange)

    if contentRange.location != NSNotFound, contentRange.length > 0 {
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.bodyColor, range: contentRange)
      applyInlineStyles(to: storage, range: contentRange, fullString: fullString)
    }

    return true
  }

  private func applyInlineStyles(to storage: NSTextStorage, range: NSRange, fullString: String) {
    guard range.location != NSNotFound, range.length > 0 else { return }
    guard range.location + range.length <= storage.length else { return }

    let substring = (fullString as NSString).substring(with: range)

    applyBoldStyle(to: storage, in: substring, offset: range.location)
    applyItalicStyle(to: storage, in: substring, offset: range.location)
    applyInlineCodeStyle(to: storage, in: substring, offset: range.location)
    applyLinkStyle(to: storage, in: substring, offset: range.location)
  }

  private func applyBoldStyle(to storage: NSTextStorage, in text: String, offset: Int) {
    guard let regex = boldRegex else { return }
    let nsText = text as NSString
    let range = NSRange(location: 0, length: nsText.length)

    regex.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match else { return }

      let openMarkerRange = adjustRange(match.range(at: 1), offset: offset)
      let contentRange = adjustRange(match.range(at: 2), offset: offset)
      let closeMarkerRange = adjustRange(match.range(at: 3), offset: offset)

      guard storage.isValidRange(openMarkerRange),
            storage.isValidRange(contentRange),
            storage.isValidRange(closeMarkerRange) else { return }

      let existingFont = storage.attribute(.font, at: contentRange.location, effectiveRange: nil) as? UIFont
        ?? MarkdownStyle.bodyFont
      let boldFont = existingFont.withBoldTrait()

      storage.addAttribute(.font, value: boldFont, range: contentRange)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: openMarkerRange)
      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: closeMarkerRange)
    }
  }

  private func applyItalicStyle(to storage: NSTextStorage, in text: String, offset: Int) {
    guard let regex = italicRegex else { return }
    let nsText = text as NSString
    let range = NSRange(location: 0, length: nsText.length)

    regex.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match else { return }

      let fullMatchRange = adjustRange(match.range(at: 0), offset: offset)
      let contentRange = adjustRange(match.range(at: 1), offset: offset)

      guard storage.isValidRange(fullMatchRange), storage.isValidRange(contentRange) else { return }

      let markerStart = NSRange(location: fullMatchRange.location, length: 1)
      let markerEnd = NSRange(location: fullMatchRange.location + fullMatchRange.length - 1, length: 1)

      let existingFont = storage.attribute(.font, at: contentRange.location, effectiveRange: nil) as? UIFont
        ?? MarkdownStyle.bodyFont
      let italicFont = existingFont.withItalicTrait()

      storage.addAttribute(.font, value: italicFont, range: contentRange)
      if storage.isValidRange(markerStart) {
        storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerStart)
      }
      if storage.isValidRange(markerEnd) {
        storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: markerEnd)
      }
    }
  }

  private func applyInlineCodeStyle(to storage: NSTextStorage, in text: String, offset: Int) {
    guard let regex = inlineCodeRegex else { return }
    let nsText = text as NSString
    let range = NSRange(location: 0, length: nsText.length)

    regex.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match else { return }

      let fullRange = adjustRange(match.range(at: 0), offset: offset)
      let contentRange = adjustRange(match.range(at: 1), offset: offset)

      guard storage.isValidRange(fullRange), storage.isValidRange(contentRange) else { return }

      let backtickStart = NSRange(location: fullRange.location, length: 1)
      let backtickEnd = NSRange(location: fullRange.location + fullRange.length - 1, length: 1)

      storage.addAttribute(.font, value: MarkdownStyle.codeFont, range: contentRange)
      storage.addAttribute(.backgroundColor, value: MarkdownStyle.codeBackground, range: contentRange)
      if storage.isValidRange(backtickStart) {
        storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: backtickStart)
      }
      if storage.isValidRange(backtickEnd) {
        storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: backtickEnd)
      }
    }
  }

  private func applyLinkStyle(to storage: NSTextStorage, in text: String, offset: Int) {
    guard let regex = linkRegex else { return }
    let nsText = text as NSString
    let range = NSRange(location: 0, length: nsText.length)

    regex.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match else { return }

      let fullRange = adjustRange(match.range(at: 0), offset: offset)
      let labelRange = adjustRange(match.range(at: 1), offset: offset)
      let urlRange = adjustRange(match.range(at: 2), offset: offset)

      guard storage.isValidRange(fullRange) else { return }

      storage.addAttribute(.foregroundColor, value: MarkdownStyle.syntaxColor, range: fullRange)

      if storage.isValidRange(labelRange) {
        storage.addAttribute(.foregroundColor, value: MarkdownStyle.linkColor, range: labelRange)
        storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: labelRange)

        if storage.isValidRange(urlRange) {
          let urlString = (storage.string as NSString).substring(with: urlRange)
          if let url = URL(string: urlString) {
            storage.addAttribute(.link, value: url, range: labelRange)
          }
        }
      }
    }
  }

  // MARK: - Utilities

  private func adjustRange(_ range: NSRange, offset: Int) -> NSRange {
    guard range.location != NSNotFound else { return range }
    return NSRange(location: range.location + offset, length: range.length)
  }
}

// MARK: - NSTextStorage Helpers

private extension NSTextStorage {
  func isValidRange(_ range: NSRange) -> Bool {
    guard range.location != NSNotFound, range.length > 0 else { return false }
    return range.location + range.length <= length
  }
}

// MARK: - UIFont Helpers

private extension UIFont {
  func withBoldTrait() -> UIFont {
    let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor
    return UIFont(descriptor: descriptor, size: pointSize)
  }

  func withItalicTrait() -> UIFont {
    let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic) ?? fontDescriptor
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}

// MARK: - String Line Helpers

private extension String {
  func lineRangeEnd(from start: Index) -> Index {
    var end = start
    while end < endIndex {
      let char = self[end]
      end = index(after: end)
      if char == "\n" { break }
    }
    return end
  }
}
