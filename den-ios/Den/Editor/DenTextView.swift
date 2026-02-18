import UIKit

// MARK: - DenTextView

final class DenTextView: UITextView {
  var onCheckboxToggle: ((Int, Bool) -> Void)?
  var onLinkTap: ((URL) -> Void)?

  private let styler = MarkdownStyler()
  private var isApplyingStyle = false

  private let checklistRegex = try? NSRegularExpression(pattern: #"^(\s*)- \[([ x])\]\s+"#)
  private let unorderedListRegex = try? NSRegularExpression(pattern: #"^(\s*)([-*])\s+(.*)$"#)
  private let orderedListRegex = try? NSRegularExpression(pattern: #"^(\s*)(\d+)\.\s+(.*)$"#)

  init() {
    let textContainer = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
    textContainer.widthTracksTextView = true

    super.init(frame: .zero, textContainer: textContainer)

    setupTextView()
    setupGestureRecognizers()
    setupNotifications()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Setup

  private func setupTextView() {
    backgroundColor = .systemBackground
    font = MarkdownStyle.bodyFont
    textColor = MarkdownStyle.bodyColor
    tintColor = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1.0)
    textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 80, right: 16)
    translatesAutoresizingMaskIntoConstraints = false
    isScrollEnabled = true
    alwaysBounceVertical = true
    keyboardDismissMode = .interactive
    dataDetectorTypes = []
    linkTextAttributes = [:]

    typingAttributes = defaultTypingAttributes
  }

  private func setupGestureRecognizers() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    tapGesture.delegate = self
    addGestureRecognizer(tapGesture)
  }

  private func setupNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textDidChange),
      name: UITextView.textDidChangeNotification,
      object: self
    )
  }

  // MARK: - Styling

  var defaultTypingAttributes: [NSAttributedString.Key: Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = MarkdownStyle.bodyLineSpacing
    return [
      .font: MarkdownStyle.bodyFont,
      .foregroundColor: MarkdownStyle.bodyColor,
      .paragraphStyle: paragraphStyle,
    ]
  }

  func applyMarkdownStyling() {
    guard !isApplyingStyle else { return }
    isApplyingStyle = true
    defer { isApplyingStyle = false }

    let savedRange = selectedRange
    styler.styleText(in: textStorage)
    selectedRange = savedRange

    resetTypingAttributesForCurrentPosition()
  }

  private func resetTypingAttributesForCurrentPosition() {
    let position = selectedRange.location
    guard position > 0, position <= textStorage.length else {
      typingAttributes = defaultTypingAttributes
      return
    }

    let checkPos = min(position - 1, textStorage.length - 1)
    let existingAttrs = textStorage.attributes(at: checkPos, effectiveRange: nil)
    let existingFont = existingAttrs[.font] as? UIFont ?? MarkdownStyle.bodyFont

    if existingFont == MarkdownStyle.codeFont {
      typingAttributes = [
        .font: MarkdownStyle.codeFont,
        .foregroundColor: MarkdownStyle.bodyColor,
      ]
    } else {
      typingAttributes = defaultTypingAttributes
    }
  }

  // MARK: - Notifications

  @objc private func textDidChange() {
    applyMarkdownStyling()
  }

  // MARK: - Tap Handling

  @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: self)
    let characterIndex = characterIndex(at: location)
    guard characterIndex != NSNotFound, characterIndex < textStorage.length else { return }

    if tryToggleCheckbox(at: characterIndex) { return }
    if tryOpenLink(at: characterIndex) { return }
  }

  private func characterIndex(at point: CGPoint) -> Int {
    let adjustedPoint = CGPoint(
      x: point.x - textContainerInset.left,
      y: point.y - textContainerInset.top
    )
    let index = layoutManager.characterIndex(
      for: adjustedPoint,
      in: textContainer,
      fractionOfDistanceBetweenInsertionPoints: nil
    )
    return index
  }

  private func tryToggleCheckbox(at characterIndex: Int) -> Bool {
    let lineRange = (text as NSString).lineRange(for: NSRange(location: characterIndex, length: 0))
    let lineText = (text as NSString).substring(with: lineRange)
    let nsLineText = lineText as NSString
    let localRange = NSRange(location: 0, length: nsLineText.length)

    guard let regex = checklistRegex,
          let match = regex.firstMatch(in: lineText, range: localRange) else { return false }

    let checkboxRange = match.range(at: 2)
    guard checkboxRange.location != NSNotFound else { return false }

    let checkboxChar = nsLineText.substring(with: checkboxRange)
    let isCurrentlyChecked = checkboxChar == "x"
    let newChar = isCurrentlyChecked ? " " : "x"

    let absoluteCheckboxRange = NSRange(
      location: lineRange.location + checkboxRange.location,
      length: checkboxRange.length
    )

    guard Range(absoluteCheckboxRange, in: text) != nil else { return false }

    let mutableText = NSMutableString(string: text)
    mutableText.replaceCharacters(in: absoluteCheckboxRange, with: newChar)
    text = mutableText as String

    applyMarkdownStyling()
    onCheckboxToggle?(lineRange.location, !isCurrentlyChecked)
    return true
  }

  private func tryOpenLink(at characterIndex: Int) -> Bool {
    let attrs = textStorage.attributes(at: characterIndex, effectiveRange: nil)
    guard let url = attrs[.link] as? URL else { return false }
    onLinkTap?(url)
    return true
  }

  // MARK: - Keyboard Handling

  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    guard let key = presses.first?.key else {
      super.pressesBegan(presses, with: event)
      return
    }

    switch key.keyCode {
    case .keyboardReturnOrEnter:
      if handleReturnKey() { return }
    case .keyboardTab:
      if handleTabKey() { return }
    default:
      break
    }

    super.pressesBegan(presses, with: event)
  }

  private func handleReturnKey() -> Bool {
    let cursorRange = selectedRange
    let lineRange = (text as NSString).lineRange(for: NSRange(location: cursorRange.location, length: 0))
    let lineText = (text as NSString).substring(with: lineRange).trimmingCharacters(in: .newlines)

    if let continuation = listContinuation(for: lineText) {
      if continuation.isEmpty {
        let mutableText = NSMutableString(string: text)
        mutableText.replaceCharacters(in: lineRange, with: "\n")
        text = mutableText as String
        selectedRange = NSRange(location: lineRange.location + 1, length: 0)
      } else {
        let insertText = "\n" + continuation
        let mutableText = NSMutableString(string: text)
        mutableText.insert(insertText, at: cursorRange.location)
        text = mutableText as String
        selectedRange = NSRange(location: cursorRange.location + insertText.count, length: 0)
      }
      applyMarkdownStyling()
      return true
    }

    return false
  }

  private func listContinuation(for line: String) -> String? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)

    if trimmed == "- [ ]" || trimmed == "- [x]" || trimmed == "-" || trimmed == "*" {
      return ""
    }

    if let checklistMatch = checklistRegex?.firstMatch(
      in: line,
      range: NSRange(line.startIndex..., in: line)
    ) {
      let indentRange = Range(checklistMatch.range(at: 1), in: line)
      let indent = indentRange.map { String(line[$0]) } ?? ""
      return indent + "- [ ] "
    }

    if let match = unorderedListRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
      let contentRange = Range(match.range(at: 3), in: line)
      let content = contentRange.map { String(line[$0]) } ?? ""
      if content.trimmingCharacters(in: .whitespaces).isEmpty { return "" }

      let indentRange = Range(match.range(at: 1), in: line)
      let markerRange = Range(match.range(at: 2), in: line)
      let indent = indentRange.map { String(line[$0]) } ?? ""
      let marker = markerRange.map { String(line[$0]) } ?? "-"
      return indent + marker + " "
    }

    if let match = orderedListRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
      let contentRange = Range(match.range(at: 3), in: line)
      let content = contentRange.map { String(line[$0]) } ?? ""
      if content.trimmingCharacters(in: .whitespaces).isEmpty { return "" }

      let indentRange = Range(match.range(at: 1), in: line)
      let numberRange = Range(match.range(at: 2), in: line)
      let indent = indentRange.map { String(line[$0]) } ?? ""
      let number = numberRange.flatMap { Int(line[$0]) } ?? 1
      return indent + "\(number + 1). "
    }

    return nil
  }

  private func handleTabKey() -> Bool {
    let cursorRange = selectedRange
    let lineRange = (text as NSString).lineRange(for: NSRange(location: cursorRange.location, length: 0))
    let lineText = (text as NSString).substring(with: lineRange)

    let isListLine = lineText.hasPrefix("- ") || lineText.hasPrefix("* ") ||
      lineText.range(of: #"^\d+\. "#, options: .regularExpression) != nil

    guard isListLine else { return false }

    let mutableText = NSMutableString(string: text)
    mutableText.insert("  ", at: lineRange.location)
    text = mutableText as String
    selectedRange = NSRange(location: cursorRange.location + 2, length: 0)
    applyMarkdownStyling()
    return true
  }
}

// MARK: - UIGestureRecognizerDelegate

extension DenTextView: UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}
