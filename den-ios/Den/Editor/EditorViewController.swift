import UIKit

// MARK: - EditorViewController

final class EditorViewController: UIViewController {
  let textView = DenTextView()
  var onContentChange: ((String) -> Void)?

  private var keyboardBottomConstraint: NSLayoutConstraint?
  private var isUpdatingContent = false

  var content: String {
    get { textView.text ?? "" }
    set {
      guard !isUpdatingContent else { return }
      guard newValue != textView.text else { return }
      isUpdatingContent = true
      textView.text = newValue
      textView.applyMarkdownStyling()
      isUpdatingContent = false
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupTextViewDelegate()
    setupKeyboardObservers()
    setupLinkHandling()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Setup

  private func setupView() {
    view.backgroundColor = .systemBackground
    view.addSubview(textView)

    keyboardBottomConstraint = textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: view.topAnchor),
      textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      keyboardBottomConstraint!,
    ])
  }

  private func setupTextViewDelegate() {
    textView.delegate = self
  }

  private func setupLinkHandling() {
    textView.onLinkTap = { url in
      UIApplication.shared.open(url)
    }
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  // MARK: - Keyboard

  @objc private func keyboardWillShow(_ notification: Notification) {
    guard
      let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
      let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
    else { return }

    let keyboardHeight = keyboardFrame.height
    let animationCurve = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16)

    UIView.animate(withDuration: duration, delay: 0, options: animationCurve) {
      self.keyboardBottomConstraint?.constant = -keyboardHeight
      self.view.layoutIfNeeded()
    }
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    guard
      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
      let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
    else { return }

    let animationCurve = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16)

    UIView.animate(withDuration: duration, delay: 0, options: animationCurve) {
      self.keyboardBottomConstraint?.constant = 0
      self.view.layoutIfNeeded()
    }
  }
}

// MARK: - UITextViewDelegate

extension EditorViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    guard !isUpdatingContent else { return }
    onContentChange?(textView.text)
  }

  func textView(
    _ textView: UITextView,
    shouldInteractWith URL: URL,
    in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    UIApplication.shared.open(URL)
    return false
  }
}
