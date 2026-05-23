import AppKit
import SwiftUI

enum BrandStyle {
  static let accent = Color(red: 1.0, green: 0.416, blue: 0.239)
  static let surface = Color(nsColor: .controlBackgroundColor)
  static let surfaceAlt = Color(nsColor: .windowBackgroundColor)
  static let border = Color(nsColor: .separatorColor)
  static let label = Color(nsColor: .secondaryLabelColor)
}

struct CardSection<Content: View>: View {
  let title: String
  let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(BrandStyle.surface)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(BrandStyle.border, lineWidth: 1)
    )
    .cornerRadius(12)
  }
}

struct GlassCard<Content: View>: View {
  let content: Content
  let padding: CGFloat

  init(padding: CGFloat = 12, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.padding = padding
  }

  var body: some View {
    content
      .padding(padding)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(.ultraThinMaterial)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(BrandStyle.border.opacity(0.6), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
  }
}

struct SectionHeader: View {
  let title: String
  let subtitle: String?

  init(_ title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.title3)
        .fontWeight(.semibold)
      if let subtitle {
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}

struct InfoPill: View {
  let title: String
  let value: String
  let accent: Color?

  init(_ title: String, value: String, accent: Color? = nil) {
    self.title = title
    self.value = value
    self.accent = accent
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      Text(value)
        .font(.headline)
        .foregroundColor(accent ?? .primary)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(BrandStyle.surfaceAlt)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(BrandStyle.border.opacity(0.6), lineWidth: 1)
    )
    .cornerRadius(10)
  }
}

struct BadgePill: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.15))
      .foregroundColor(color)
      .cornerRadius(8)
  }
}

struct FieldRow<Content: View>: View {
  let title: String
  let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Text(title)
        .font(.caption)
        .foregroundColor(BrandStyle.label)
        .frame(width: 100, alignment: .leading)
      content
    }
  }
}

struct FieldContainerModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(BrandStyle.surfaceAlt)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(BrandStyle.border, lineWidth: 1)
      )
      .cornerRadius(8)
  }
}

extension View {
  func fieldContainer() -> some View {
    modifier(FieldContainerModifier())
  }
}

struct PrimaryActionButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(BrandStyle.accent.opacity(configuration.isPressed ? 0.8 : 1))
      .foregroundColor(.white)
      .cornerRadius(8)
  }
}
