import Foundation
import MediaEditor
import Gridicons

/**
 Displays the Media Editor with our custom styles and tracking
 */
class WPMediaEditor: MediaEditor {

    /// A Bool value indicating if the image being edited is already published. If true, it changes the Media Editor label to "Done"
    var editingAlreadyPublishedImage: Bool = false {
        didSet {
            if editingAlreadyPublishedImage {
                hub.doneButton.setTitle(NSLocalizedString("Done", comment: "Done editing an image"), for: .normal)
            }
        }
    }

    override var styles: MediaEditorStyles {
        get {
            return [
                .insertLabel: NSLocalizedString("Insert %@", comment: "Button title used in media editor. Placeholder will be the number of items that will be inserted."),
                .doneLabel: NSLocalizedString("Done", comment: "Done editing an image"),
                .cancelLabel: NSLocalizedString("Cancel", comment: "Cancel editing an image"),
                .errorLoadingImageMessage: NSLocalizedString("We couldn't retrieve this media.\nPlease tap to retry.", comment: "Description that appears when a media fails to load in the Media Editor."),
                .cancelColor: UIColor.white,
                .resetIcon: Gridicon.iconOfType(.undo),
                .doneIcon: Gridicon.iconOfType(.checkmark),
                .cancelIcon: Gridicon.iconOfType(.cross),
                .rotateClockwiseIcon: Gridicon.iconOfType(.rotate).withHorizontallyFlippedOrientation(),
                .rotateCounterclockwiseButtonHidden: true,
                .retryIcon: Gridicon.iconOfType(.refresh, withSize: CGSize(width: 48, height: 48))
            ]
        }

        set {
            // noop
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track("media_editor_shown")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        trackUsage()
    }

    private func trackUsage() {
        guard !actions.isEmpty else {
            return
        }

        WPAnalytics.track(.mediaEditorUsed, withProperties: ["actions": actions.description])
    }
}
