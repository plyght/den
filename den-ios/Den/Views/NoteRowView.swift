import SwiftUI

struct NoteRowView: View {
    let note: Note
    var appeared: Bool = false

    private var titleText: String {
        let lines = note.content.components(separatedBy: "\n")
        let first = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        return first.isEmpty ? "Untitled" : first
    }

    private var previewText: String {
        let lines = note.content.components(separatedBy: "\n")
        let bodyLines = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return bodyLines.prefix(2).joined(separator: " ")
    }

    private var relativeTime: String {
        let now = Date()
        let diff = now.timeIntervalSince(note.updatedAt)

        if diff < 60 {
            return "Just now"
        } else if diff < 3600 {
            let mins = Int(diff / 60)
            return "\(mins)m ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else if diff < 172800 {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: note.updatedAt)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(titleText)
                        .font(DenTheme.titleFont)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if note.pinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DenTheme.accent)
                    }

                    Text(relativeTime)
                        .font(DenTheme.timestampFont)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if !previewText.isEmpty {
                    Text(previewText)
                        .font(DenTheme.bodyFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, DenTheme.cardPadding)
        .padding(.vertical, 12)
        .background(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: DenTheme.cardRadius, style: .continuous)
                        .glassEffect(.regular)
                } else {
                    RoundedRectangle(cornerRadius: DenTheme.cardRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        )
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1.0 : 0.0)
    }
}
