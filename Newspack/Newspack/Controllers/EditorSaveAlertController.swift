import Foundation
import UIKit

class EditorSaveAlertControllerFactory {

    struct ActionTitles {
        static let update = NSLocalizedString( "Update", comment: "Update a post.")
        static let publish = NSLocalizedString("Publish", comment: "Publish a post.")
        static let privately = NSLocalizedString("Publish Privately", comment: "Publish a post giving it a Private post status.")
        static let makePublic = NSLocalizedString("Make Public", comment: "Make a private post public.")
        static let makePrivate = NSLocalizedString("Make Private", comment: "Make a public post private.")
        static let draft = NSLocalizedString("Save Draft", comment: "Save a post as a draft.")
        static let switchDraft = NSLocalizedString("Switch to Draft", comment: "Save a post as a draft.")
        static let pending = NSLocalizedString("Save as Pending", comment: "Save a post as a draft pending review.")
        static let schedule = NSLocalizedString("Schedule", comment: "Schedule a post for future publishing.")
        static let cancel = NSLocalizedString("Cancel", comment: "Cancel")
    }

    func controllerForStagedEdits(stagedEdits : StagedEdits, canUpdate: Bool, for post: Post?) -> UIAlertController {

        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = availableSaveActions(stagedEdits: stagedEdits, canUpdate: canUpdate, for: post)
        for action in actions {
            controller.addAction(action)
        }
        return controller

    }

    func availableSaveActions(stagedEdits: StagedEdits, canUpdate: Bool, for post: Post?) -> [UIAlertAction] {
        let cancelAction = UIAlertAction(title: ActionTitles.cancel, style: .cancel, handler: nil)

        var alertActions = [UIAlertAction]()

        guard let post = post else {

            if stagedEdits.content == nil && stagedEdits.title == nil {
                // Nothing to save. Just provide a cancel option.
                alertActions.append(cancelAction)
                return alertActions
            }

            // Local changes only -- default actions.
            // publish, save draft, cancel
            alertActions = [UIAlertAction]()
            alertActions.append(alertActionWithTitle(title: ActionTitles.draft, and: .saveAsDraft))
            alertActions.append(alertActionWithTitle(title: ActionTitles.publish, and: .publish))
            alertActions.append(cancelAction)
            return alertActions
        }

        if post.dateGMT > Date() || post.status == "future" {
            alertActions = alertActionsForSchedule()

        } else if post.status == "draft" {
            alertActions = alertActionsForDraft()

        } else if post.status == "pending" {
            alertActions = alertActionsForPending()

        } else if post.status == "private" {
            alertActions = alertActionsForPrivate(canUpdate: canUpdate)

        } else if post.status == "publish" {
            alertActions = alertActionsForPublish(canUpdate: canUpdate)
        } else {
            // This might be a status of inherit, trash, or a custom post status.
            LogWarn(message: "availableSaveActions: Post had an unexpected post status: " + post.status)
        }

        // Add a cancel action
        alertActions.append(cancelAction)

        return alertActions
    }

    func alertActionsForDraft() -> [UIAlertAction] {
        var alertActions = [UIAlertAction]()
        alertActions.append(alertActionWithTitle(title: ActionTitles.draft, and: .saveAsDraft))
        alertActions.append(alertActionWithTitle(title: ActionTitles.pending, and: .saveAsPending))
        alertActions.append(alertActionWithTitle(title: ActionTitles.publish, and: .publish))
        alertActions.append(alertActionWithTitle(title: ActionTitles.privately, and: .publishPrivately))
        return alertActions
    }

    func alertActionsForPending() -> [UIAlertAction] {
        var alertActions = [UIAlertAction]()
        alertActions.append(alertActionWithTitle(title: ActionTitles.pending, and: .saveAsPending))
        alertActions.append(alertActionWithTitle(title: ActionTitles.draft, and: .saveAsDraft))
        alertActions.append(alertActionWithTitle(title: ActionTitles.publish, and: .publish))
        alertActions.append(alertActionWithTitle(title: ActionTitles.privately, and: .publishPrivately))
        return alertActions
    }

    func alertActionsForPrivate(canUpdate: Bool) -> [UIAlertAction] {
        var alertActions = [UIAlertAction]()
        if canUpdate {
            alertActions.append(alertActionWithTitle(title: ActionTitles.update, and: .publishPrivately))
        }
        alertActions.append(alertActionWithTitle(title: ActionTitles.makePublic, and: .publish))
        alertActions.append(alertActionWithTitle(title: ActionTitles.switchDraft, and: .saveAsDraft))
        return alertActions
    }

    func alertActionsForPublish(canUpdate: Bool) -> [UIAlertAction] {
        var alertActions = [UIAlertAction]()
        if canUpdate {
            alertActions.append(alertActionWithTitle(title: ActionTitles.update, and: .publish))
        }
        alertActions.append(alertActionWithTitle(title: ActionTitles.makePrivate, and: .publishPrivately))
        alertActions.append(alertActionWithTitle(title: ActionTitles.switchDraft, and: .saveAsDraft))
        return alertActions
    }

    func alertActionsForSchedule() -> [UIAlertAction] {
        var alertActions = [UIAlertAction]()
        alertActions.append(alertActionWithTitle(title: ActionTitles.schedule, and: .publish))
        alertActions.append(alertActionWithTitle(title: ActionTitles.switchDraft, and: .saveAsDraft))
        return alertActions
    }

    func alertActionWithTitle(title: String, and saveAction: PostSaveAction) -> UIAlertAction {
        let dispatcher = SessionManager.shared.sessionDispatcher
        return UIAlertAction(title: title, style: .default) { (_) in
            dispatcher.dispatch(saveAction)
        }
    }
}
