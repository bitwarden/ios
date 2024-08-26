import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "bitwarden-watch-complication",
                displayName: "Bitwarden",
                supportedFamilies: [
                    CLKComplicationFamily.circularSmall,
                    CLKComplicationFamily.graphicCircular,
                    CLKComplicationFamily.graphicCorner,
                    CLKComplicationFamily.utilitarianSmall,
                ]
            ),
        ]

        handler(descriptors)
    }

    // MARK: - Timeline Configuration

    func getPrivacyBehavior(
        for _: CLKComplication,
        withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void
    ) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        guard let icon = UIImage(named: "ComplicationIcon") else {
            handler(nil)
            return
        }
        let imageProvider = CLKFullColorImageProvider(fullColorImage: icon)

        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage(
                imageProvider: CLKImageProvider(onePieceImage: icon)
            )
            handler(CLKComplicationTimelineEntry(date: .now, complicationTemplate: template))
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)
            handler(CLKComplicationTimelineEntry(date: .now, complicationTemplate: template))
        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: imageProvider)
            handler(CLKComplicationTimelineEntry(date: .now, complicationTemplate: template))
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallSquare(
                imageProvider: CLKImageProvider(onePieceImage: icon)
            )
            handler(CLKComplicationTimelineEntry(date: .now, complicationTemplate: template))
        default:
            handler(nil)
        }
    }

    // MARK: - Sample Templates

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        guard let icon = UIImage(named: "ComplicationIcon") else {
            handler(nil)
            return
        }
        let imageProvider = CLKFullColorImageProvider(fullColorImage: icon)

        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage(
                imageProvider: CLKImageProvider(onePieceImage: icon)
            )
            handler(template)
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)
            handler(template)
        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: imageProvider)
            handler(template)
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallSquare(
                imageProvider: CLKImageProvider(onePieceImage: icon)
            )
            handler(template)
        default:
            handler(nil)
        }
    }
}
