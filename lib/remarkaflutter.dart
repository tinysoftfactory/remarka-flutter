/// ReMarka for Flutter — a plug-and-play feedback service with shake detection,
/// screenshots, log capturing and moderator responses.
///
/// A faithful port of the React Native `remarka` library.
library;

export 'src/remarka.dart' show ReMarka;
export 'src/remarka_provider.dart' show ReMarkaProvider;
export 'src/types.dart'
    show
        ReMarkaConfig,
        ReMarkaStyles,
        ShowOverrideConfig,
        WelcomeOverrideConfig,
        ShowAnimation,
        FieldType,
        LogEntry,
        FeedbackFieldValue,
        FeedbackPayload,
        ResponseMessage,
        SendData;
