import SwiftUI
import UIKit

struct NoteEditorView: UIViewControllerRepresentable {
  @Binding var content: String
  var onContentChange: ((String) -> Void)?

  func makeUIViewController(context: Context) -> EditorViewController {
    let vc = EditorViewController()
    vc.content = content
    let coordinator = context.coordinator
    vc.onContentChange = { newContent in
      coordinator.handleContentChange(newContent)
    }
    return vc
  }

  func updateUIViewController(_ vc: EditorViewController, context: Context) {
    guard !context.coordinator.isUpdatingFromEditor else { return }
    guard vc.content != content else { return }
    vc.content = content
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(binding: $content, onContentChange: onContentChange)
  }

  // MARK: - Coordinator

  final class Coordinator {
    private var binding: Binding<String>
    private let onContentChange: ((String) -> Void)?
    var isUpdatingFromEditor = false

    init(binding: Binding<String>, onContentChange: ((String) -> Void)?) {
      self.binding = binding
      self.onContentChange = onContentChange
    }

    func handleContentChange(_ newContent: String) {
      guard newContent != binding.wrappedValue else { return }
      isUpdatingFromEditor = true
      binding.wrappedValue = newContent
      onContentChange?(newContent)
      isUpdatingFromEditor = false
    }
  }
}
