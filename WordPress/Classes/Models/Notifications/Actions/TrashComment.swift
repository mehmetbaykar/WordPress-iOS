import MGSwipeTableCell

/// Encapsulates logic to trash a comment
final class TrashComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Trash", comment: "Trashes a comment")
    static let hint = NSLocalizedString("Trashes a comment", comment: "VoiceOver accessibility hint, informing the user the button can be used to Trashes a comment")

    let trashIcon: UIButton = {
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.errorRed())
        button.accessibilityLabel =  title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = hint
        return button
    }()

    override var icon: UIButton? {
        return trashIcon
    }

    override func execute(context: ActionContext) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] requestCompletion in
                self?.actionsService?.deleteCommentWithBlock(context.block, completion: { success in
                    requestCompletion(success)
                })
            })

            context.completion?(request, true)
        }
    }
}
