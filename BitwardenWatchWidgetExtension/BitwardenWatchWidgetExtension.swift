import SwiftUI
import WidgetKit

/// Provider that provides the entries for the widget.
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

/// Simple timeline entry to comply with the widget provider.
struct SimpleEntry: TimelineEntry {
    let date: Date
}

/// Entry view to be used to render the widget.
struct BitwardenComplicationEntryView: View {
    /// The widget family.
    @Environment(\.widgetFamily) var family
    /// The widget rendering mode.
    @Environment(\.widgetRenderingMode) var renderingMode

    /// The provider entry
    var entry: Provider.Entry

    var body: some View {
        if renderingMode == .fullColor {
            Image("ComplicationIcon")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .padding()
        } else {
            Image("AccentedComplicationIcon")
                .resizable()
                .scaledToFit()
                .padding(5)
                .widgetAccentable()
        }
    }
}

/// Extension entry point of the widget.
@main
struct BitwardenWatchWidgetExtension: Widget {
    let kind: String = "BitwardenWatchWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(watchOS 10.0, *) {
                BitwardenComplicationEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BitwardenComplicationEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Bitwarden")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

@available(watchOS 10.0, *)
#Preview(as: .accessoryCorner) {
    BitwardenWatchWidgetExtension()
} timeline: {
    SimpleEntry(date: .now)
}
