
@testable import WordPress

import Nimble

private typealias ButtonGroups = PostCardStatusViewModel.ButtonGroups

class PostCardStatusViewModelTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDown() {
        context = nil
        contextManager = nil
        super.tearDown()
    }

    func testExpectedButtonGroupsForVariousPostAttributeCombinations() {
        // Arrange
        let expectations: [(String, Post, ButtonGroups)] = [
            (
                "Draft with remote",
                PostBuilder(context).drafted().withRemote().build(),
                ButtonGroups(primary: [.edit, .view, .more], secondary: [.publish, .trash])
            ),
            (
                "Draft that was not uploaded to the server",
                PostBuilder(context).drafted().with(remoteStatus: .failed).build(),
                ButtonGroups(primary: [.edit, .publish, .trash], secondary: [])
            ),
            (
                "Draft with remote and confirmed local changes",
                PostBuilder(context).drafted().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().build(),
                ButtonGroups(primary: [.edit, .cancelAutoUpload, .more], secondary: [.publish, .trash])
            ),
            (
                "Draft with remote and canceled local changes",
                PostBuilder(context).drafted().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().cancelledAutoUpload().build(),
                ButtonGroups(primary: [.edit, .publish, .trash], secondary: [])
            ),
            (
                "Local published draft with confirmed auto-upload",
                PostBuilder(context).published().with(remoteStatus: .failed).confirmedAutoUpload().build(),
                ButtonGroups(primary: [.edit, .cancelAutoUpload, .more], secondary: [.moveToDraft, .trash])
            ),
            (
                "Local published draft with canceled auto-upload",
                PostBuilder(context).published().with(remoteStatus: .failed).build(),
                ButtonGroups(primary: [.edit, .publish, .more], secondary: [.moveToDraft, .trash])
            ),
            (
                "Published post",
                PostBuilder(context).published().withRemote().build(),
                ButtonGroups(primary: [.edit, .view, .more], secondary: [.stats, .share, .moveToDraft, .trash])
            ),
            (
                "Published post with local confirmed changes",
                PostBuilder(context).published().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().build(),
                ButtonGroups(primary: [.edit, .cancelAutoUpload, .more], secondary: [.stats, .share, .moveToDraft, .trash])
            ),
            (
                "Post with the max number of auto uploades retry reached",
                PostBuilder(context).with(remoteStatus: .failed)
                    .with(autoUploadAttemptsCount: 3).confirmedAutoUpload().build(),
                ButtonGroups(primary: [.edit, .retry, .more], secondary: [.publish, .moveToDraft, .trash])
            ),
        ]

        // Act and Assert
        expectations.forEach { scenario, post, expectedButtonGroups in
            let viewModel = PostCardStatusViewModel(post: post, isInternetReachable: false)

            expect({
                guard viewModel.buttonGroups == expectedButtonGroups else {
                    let reason = "The scenario \"\(scenario)\" failed. "
                        + " Expected buttonGroups to be: \(expectedButtonGroups.prettifiedDescription)."
                        + " Actual: \(viewModel.buttonGroups.prettifiedDescription)"

                    return .failed(reason: reason)
                }

                return .succeeded
            }).to(succeed())
        }
    }

    /// If the post fails to upload and there is internet connectivity, show "Upload failed" message
    ///
    func testReturnFailedMessageIfPostFailedAndThereIsConnectivity() {
        let post = PostBuilder(context).revision().with(remoteStatus: .failed).confirmedAutoUpload().build()

        let viewModel = PostCardStatusViewModel(post: post, isInternetReachable: true)

        expect(viewModel.status).to(equal(i18n("Upload failed")))
        expect(viewModel.statusColor).to(equal(.error))
    }

    /// If the post fails to upload and there is NO internet connectivity, show a message that we'll publish when the user is back online
    ///
    func testReturnWillUploadLaterMessageIfPostFailedAndThereIsConnectivity() {
        let post = PostBuilder(context).revision().with(remoteStatus: .failed).confirmedAutoUpload().build()

        let viewModel = PostCardStatusViewModel(post: post, isInternetReachable: false)

        expect(viewModel.status).to(equal(i18n("We'll publish the post when your device is back online.")))
        expect(viewModel.statusColor).to(equal(.warning))
    }

    /// An original post created without a conflicting local post should not show 'Version Conflict' in the cell.
    func testVersionConflictStatusMessageShouldNotShow() {
        let original = PostBuilder(context).revision().with(remoteStatus: .sync).with(dateModified: Date()).build()
        let viewModel = PostCardStatusViewModel(post: original, isInternetReachable: true)

        expect(viewModel.status).to(equal(i18n("Local changes")))
        expect(viewModel.statusColor).to(equal(.warning))
    }

    /// A local post created based on an remote post, but differing by -5ms should show 'Version Conflict
    func testVersionConflictStatusWithPreviousDateMessageShouldShow() {
        let original = PostBuilder(context).published().with(remoteStatus: .sync).with(dateModified: Date()).build()
        let local = original.createRevision() as! Post
        local.dateModified = Date() - 5
        local.tags = "test"

        let viewModel = PostCardStatusViewModel(post: local, isInternetReachable: true)

        expect(viewModel.status).to(equal(i18n("Version Conflict")))
        expect(viewModel.statusColor).to(equal(.error))
    }

    /// A local post created based on an remote post, but differing by +5ms should show 'Version Conflict
    func testVersionConflictStatusWithMoreRecentDateMessageShouldShow() {
        let original = PostBuilder(context).published().with(remoteStatus: .sync).with(dateModified: Date()).build()
        let local = original.createRevision() as! Post
        local.dateModified = Date() + 5
        local.tags = "test"

        let viewModel = PostCardStatusViewModel(post: local, isInternetReachable: true)

        expect(viewModel.status).to(equal(i18n("Version Conflict")))
        expect(viewModel.statusColor).to(equal(.error))
    }
}

private extension ButtonGroups {
    var prettifiedDescription: String {
        return "{ primary: \(primary.prettifiedDescription), secondary: \(secondary.prettifiedDescription) }"
    }
}

private extension Array where Element == PostCardStatusViewModel.Button {
    var prettifiedDescription: String {
        return "[" + map { String(describing: $0) }.joined(separator: ", ") + "]"
    }
}
