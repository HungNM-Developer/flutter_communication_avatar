import Flutter
import UIKit
import UserNotifications
import Intents

public class FlutterCommunicationAvatarPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_communication_avatar", binaryMessenger: registrar.messenger())
        let instance = FlutterCommunicationAvatarPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        UNUserNotificationCenter.current().delegate = instance
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "showNotification":
            handleShowNotification(call, result: result)
        case "createNotificationChannel":
            // Android only channel creation
            result(true)
        case "requestPermissions":
            handleRequestPermissions(result: result)
        case "hasPermissions":
            handleHasPermissions(result: result)
        case "cancelNotification":
            handleCancelNotification(call, result: result)
        case "cancelAllNotifications":
            handleCancelAllNotifications(result: result)
        case "clearAvatarCache":
            handleClearAvatarCache(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleShowNotification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments map missing", details: nil))
            return
        }

        let id = args["id"] as? Int ?? Int.random(in: 1...100000)
        let body = args["body"] as? String ?? ""
        let title = args["title"] as? String
        let conversationId = args["conversationId"] as? String ?? "default_conversation"
        let conversationTitle = args["conversationTitle"] as? String
        let isGroupConversation = args["isGroupConversation"] as? Bool ?? false
        let soundName = args["sound"] as? String ?? "default"
        var customPayload = args["payload"] as? [String: String] ?? [:]
        let replyPlaceholder = args["replyPlaceholder"] as? String
        let replyButtonTitle = args["replyButtonTitle"] as? String

        customPayload["conversationId"] = conversationId

        let senderMap = args["sender"] as? [String: Any] ?? [:]
        let senderId = senderMap["id"] as? String ?? "unknown_sender"
        let senderName = senderMap["name"] as? String ?? "Sender"
        let avatarUrl = senderMap["avatarUrl"] as? String
        let fallbackAsset = senderMap["fallbackAsset"] as? String

        // Download or generate avatar image asynchronously
        fetchOrGenerateAvatarImage(avatarUrl: avatarUrl, fallbackAsset: fallbackAsset, senderName: senderName) { avatarImage, avatarData in
            self.postCommunicationNotification(
                id: id,
                title: title,
                body: body,
                conversationId: conversationId,
                conversationTitle: conversationTitle,
                isGroupConversation: isGroupConversation,
                senderId: senderId,
                senderName: senderName,
                avatarImage: avatarImage,
                avatarData: avatarData,
                soundName: soundName,
                payload: customPayload,
                replyPlaceholder: replyPlaceholder,
                replyButtonTitle: replyButtonTitle,
                result: result
            )
        }
    }

    private func postCommunicationNotification(
        id: Int,
        title: String?,
        body: String,
        conversationId: String,
        conversationTitle: String?,
        isGroupConversation: Bool,
        senderId: String,
        senderName: String,
        avatarImage: UIImage?,
        avatarData: Data?,
        soundName: String,
        payload: [String: String],
        replyPlaceholder: String?,
        replyButtonTitle: String?,
        result: @escaping FlutterResult
    ) {
        let content = UNMutableNotificationContent()
        content.title = title ?? senderName
        content.body = body
        if soundName == "default" {
            content.sound = .default
        } else {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        }
        content.userInfo = payload

        // Register category for UNTextInputNotificationAction quick reply if requested
        if replyPlaceholder != nil || replyButtonTitle != nil {
            let categoryId = "COMMUNICATION_REPLY_CATEGORY"
            let replyAction = UNTextInputNotificationAction(
                identifier: "REPLY_ACTION",
                title: replyButtonTitle ?? "Reply",
                options: [.foreground],
                textInputButtonTitle: replyButtonTitle ?? "Send",
                textInputPlaceholder: replyPlaceholder ?? "Reply..."
            )

            let category = UNNotificationCategory(
                identifier: categoryId,
                actions: [replyAction],
                intentIdentifiers: [INSendMessageIntentIdentifier],
                options: [.allowInCarPlay]
            )

            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = categoryId
        }

        // Prepare INPerson handle & avatar image
        let handle = INPersonHandle(value: senderId, type: .unknown)
        var inImage: INImage? = nil
        if let data = avatarData {
            inImage = INImage(imageData: data)
        }

        let senderPerson = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: senderName,
            image: inImage,
            contactIdentifier: nil,
            customIdentifier: senderId,
            isMe: false
        )

        // Construct INSendMessageIntent
        let intent: INSendMessageIntent
        if #available(iOS 16.0, *) {
            intent = INSendMessageIntent(
                recipients: nil,
                outgoingMessageType: .outgoingMessageText,
                content: body,
                speakableGroupName: isGroupConversation && conversationTitle != nil ? INSpeakableString(spokenPhrase: conversationTitle!) : nil,
                conversationIdentifier: conversationId,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )
        } else {
            intent = INSendMessageIntent(
                recipients: nil,
                content: body,
                speakableGroupName: isGroupConversation && conversationTitle != nil ? INSpeakableString(spokenPhrase: conversationTitle!) : nil,
                conversationIdentifier: conversationId,
                serviceName: nil,
                sender: senderPerson
            )
        }

        if let inImage = inImage {
            intent.setImage(inImage, forParameterNamed: \INSendMessageIntent.sender)
        }

        // Donate INInteraction for iOS system learning & avatar display
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { error in
            if let error = error {
                print("[FlutterCommunicationAvatar] INInteraction donation error: \(error.localizedDescription)")
            }
        }

        var finalContent = content

        if #available(iOS 15.0, *) {
            do {
                let updatedContent = try content.updating(from: intent) as! UNMutableNotificationContent
                finalContent = updatedContent
            } catch {
                print("[FlutterCommunicationAvatar] content.updating(from: intent) failed: \(error)")
                self.attachFallbackAttachment(content: finalContent, avatarImage: avatarImage)
            }
        } else {
            self.attachFallbackAttachment(content: finalContent, avatarImage: avatarImage)
        }

        let request = UNNotificationRequest(
            identifier: String(id),
            content: finalContent,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "POST_NOTIFICATION_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let textResponse = response as? UNTextInputNotificationResponse {
            let userText = textResponse.userText
            let reqId = response.notification.request.identifier
            let notificationId = Int(reqId) ?? 0
            let userInfo = response.notification.request.content.userInfo
            let conversationId = userInfo["conversationId"] as? String ?? userInfo["conversation_id"] as? String ?? ""

            channel?.invokeMethod("onReplyReceived", [
                "text": userText,
                "notificationId": notificationId,
                "conversationId": conversationId
            ])
        }
        completionHandler()
    }

    private func attachFallbackAttachment(content: UNMutableNotificationContent, avatarImage: UIImage?) {
        guard let image = avatarImage, let data = image.pngData() else { return }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("avatar_\(UUID().uuidString).png")
        do {
            try data.write(to: fileURL)
            let attachment = try UNNotificationAttachment(identifier: "avatar", url: fileURL, options: nil)
            content.attachments = [attachment]
        } catch {
            print("[FlutterCommunicationAvatar] Failed saving fallback attachment: \(error)")
        }
    }

    private func handleRequestPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "PERMISSION_REQUEST_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(granted)
                }
            }
        }
    }

    private func handleHasPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                result(isAuthorized)
            }
        }
    }

    private func handleCancelNotification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? Int else {
            result(nil)
            return
        }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [String(id)])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(id)])
        result(nil)
    }

    private func handleCancelAllNotifications(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(nil)
    }

    private func handleClearAvatarCache(result: @escaping FlutterResult) {
        let cacheDir = avatarCacheDirectory
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            result(true)
        } catch {
            result(FlutterError(code: "CLEAR_CACHE_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    private var avatarCacheDirectory: URL {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let avatarDir = cachesDir.appendingPathComponent("avatar_cache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: avatarDir.path) {
            try? FileManager.default.createDirectory(at: avatarDir, withIntermediateDirectories: true, attributes: nil)
        }
        return avatarDir
    }

    private func getCacheKey(for urlString: String) -> String {
        var hash: UInt64 = 14695981039346656037
        for byte in urlString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return String(format: "avatar_%016llx.png", hash)
    }

    private func fetchOrGenerateAvatarImage(
        avatarUrl: String?,
        fallbackAsset: String?,
        senderName: String,
        completion: @escaping (UIImage?, Data?) -> Void
    ) {
        // 1. Check persistent disk cache for avatarUrl (0ms instant load)
        if let urlStr = avatarUrl, !urlStr.isEmpty {
            let fileURL = avatarCacheDirectory.appendingPathComponent(getCacheKey(for: urlStr))
            if FileManager.default.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let cachedImage = UIImage(data: data) {
                let circularImage = self.createCircularImage(image: cachedImage)
                completion(circularImage, circularImage.pngData())
                return
            }

            if let url = URL(string: urlStr) {
                var request = URLRequest(url: url)
                request.timeoutInterval = 5.0
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        // Write to disk cache
                        try? data.write(to: fileURL)
                        let circularImage = self.createCircularImage(image: image)
                        let pngData = circularImage.pngData()
                        completion(circularImage, pngData)
                        return
                    }
                    self.fallbackAvatarImage(fallbackAsset: fallbackAsset, senderName: senderName, completion: completion)
                }
                task.resume()
                return
            }
        }

        fallbackAvatarImage(fallbackAsset: fallbackAsset, senderName: senderName, completion: completion)
    }

    private func fallbackAvatarImage(
        fallbackAsset: String?,
        senderName: String,
        completion: @escaping (UIImage?, Data?) -> Void
    ) {
        // 2. Try loading Flutter asset if present
        if let assetName = fallbackAsset, !assetName.isEmpty {
            let key = FlutterDartProject.lookupKey(forAsset: assetName)
            if let image = UIImage(named: key) ?? UIImage(contentsOfFile: Bundle.main.path(forResource: key, ofType: nil) ?? "") {
                let circular = createCircularImage(image: image)
                completion(circular, circular.pngData())
                return
            }
        }

        // 3. Generate letter avatar
        let letterAvatar = generateLetterAvatar(name: senderName)
        completion(letterAvatar, letterAvatar.pngData())
    }

    private func createCircularImage(image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let rect = CGRect(x: 0, y: 0, width: size, height: size)

        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0.0)
        let context = UIGraphicsGetCurrentContext()

        context?.addEllipse(in: rect)
        context?.clip()

        let drawRect = CGRect(
            x: (size - image.size.width) / 2,
            y: (size - image.size.height) / 2,
            width: image.size.width,
            height: image.size.height
        )
        image.draw(in: drawRect)

        let circularImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return circularImage
    }

    private func generateLetterAvatar(name: String) -> UIImage {
        let size: CGFloat = 180.0
        let rect = CGRect(x: 0, y: 0, width: size, height: size)

        let hash = abs(name.hashValue)
        let colors: [UIColor] = [
            UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0),
            UIColor(red: 0.31, green: 0.89, blue: 0.76, alpha: 1.0),
            UIColor(red: 0.72, green: 0.91, blue: 0.52, alpha: 1.0),
            UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1.0),
            UIColor(red: 0.56, green: 0.07, blue: 0.99, alpha: 1.0),
            UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0)
        ]
        let bgColor = colors[hash % colors.count]

        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0.0)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(bgColor.cgColor)
        context?.fillEllipse(in: rect)

        let initial = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
        let text = initial.isEmpty ? "?" : initial

        let font = UIFont.boldSystemFont(ofSize: 80.0)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size - textSize.width) / 2,
            y: (size - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        let avatarImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        return avatarImage
    }
}

/// Standalone helper for formatting remote push notifications in UNNotificationServiceExtension targets.
@objc public class CommunicationAvatarExtensionHelper: NSObject {

    @objc public static func processNotificationRequest(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let userInfo = request.content.userInfo
        let body = request.content.body
        let title = request.content.title.isEmpty ? nil : request.content.title

        let senderId = userInfo["sender_id"] as? String ?? "remote_sender"
        let senderName = userInfo["sender_name"] as? String ?? request.content.title
        let avatarUrl = userInfo["avatar_url"] as? String
        let conversationId = userInfo["conversation_id"] as? String ?? "remote_conversation"

        let content = request.content.mutableCopy() as! UNMutableNotificationContent

        let handle = INPersonHandle(value: senderId, type: .unknown)

        var avatarData: Data? = nil
        if let urlStr = avatarUrl, let url = URL(string: urlStr) {
            avatarData = try? Data(contentsOf: url)
        }

        var inImage: INImage? = nil
        if let data = avatarData {
            inImage = INImage(imageData: data)
        }

        let senderPerson = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: senderName,
            image: inImage,
            contactIdentifier: nil,
            customIdentifier: senderId,
            isMe: false
        )

        let intent: INSendMessageIntent
        if #available(iOS 16.0, *) {
            intent = INSendMessageIntent(
                recipients: nil,
                outgoingMessageType: .outgoingMessageText,
                content: body,
                speakableGroupName: nil,
                conversationIdentifier: conversationId,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )
        } else {
            intent = INSendMessageIntent(
                recipients: nil,
                content: body,
                speakableGroupName: nil,
                conversationIdentifier: conversationId,
                serviceName: nil,
                sender: senderPerson
            )
        }

        if let inImage = inImage {
            intent.setImage(inImage, forParameterNamed: \INSendMessageIntent.sender)
        }

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate(completion: nil)

        if #available(iOS 15.0, *) {
            if let updated = try? content.updating(from: intent) {
                contentHandler(updated)
                return
            }
        }

        contentHandler(content)
    }
}
