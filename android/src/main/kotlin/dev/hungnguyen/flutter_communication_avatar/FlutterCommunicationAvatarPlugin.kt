package dev.hungnguyen.flutter_communication_avatar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.*
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * FlutterCommunicationAvatarPlugin
 *
 * Implements native Android communication push notifications with user avatars using
 * NotificationCompat.MessagingStyle and Person icons (Avatar displayed on the LEFT).
 */
class FlutterCommunicationAvatarPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_communication_avatar")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "showNotification" -> handleShowNotification(call, result)
            "createNotificationChannel" -> handleCreateNotificationChannel(call, result)
            "requestPermissions" -> handleRequestPermissions(result)
            "hasPermissions" -> handleHasPermissions(result)
            "cancelNotification" -> handleCancelNotification(call, result)
            "cancelAllNotifications" -> handleCancelAllNotifications(result)
            else -> result.notImplemented()
        }
    }

    private fun handleShowNotification(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            result.error("INVALID_ARGUMENTS", "Arguments map is missing", null)
            return
        }

        executor.execute {
            try {
                val id = (args["id"] as? Number)?.toInt() ?: 1
                val body = args["body"] as? String ?: ""
                val title = args["title"] as? String
                val conversationId = args["conversationId"] as? String ?: "default_conversation"
                val conversationTitle = args["conversationTitle"] as? String
                val isGroupConversation = args["isGroupConversation"] as? Boolean ?: false
                val channelId = args["channelId"] as? String ?: "communication_channel"
                val channelName = args["channelName"] as? String ?: "Messages"
                val channelDescription = args["channelDescription"] as? String
                val timestamp = (args["timestamp"] as? Number)?.toLong() ?: System.currentTimeMillis()

                val senderMap = args["sender"] as? Map<*, *>
                val senderId = senderMap?.get("id") as? String ?: "unknown_sender"
                val senderName = senderMap?.get("name") as? String ?: "Sender"
                val avatarUrl = senderMap?.get("avatarUrl") as? String
                val fallbackAsset = senderMap?.get("fallbackAsset") as? String
                val isBot = senderMap?.get("isBot") as? Boolean ?: false
                val isImportant = senderMap?.get("isImportant") as? Boolean ?: false

                // Ensure notification channel exists
                ensureNotificationChannel(channelId, channelName, channelDescription)

                // Fetch or generate avatar bitmap asynchronously
                val avatarBitmap = fetchOrGenerateAvatar(context, avatarUrl, fallbackAsset, senderName)

                // Build Person for MessagingStyle (Icon placed on LEFT of notification)
                val iconCompat = IconCompat.createWithBitmap(avatarBitmap)
                val personBuilder = Person.Builder()
                    .setName(senderName)
                    .setKey(senderId)
                    .setIcon(iconCompat)
                    .setBot(isBot)
                    .setImportant(isImportant)

                val senderPerson = personBuilder.build()

                // Create MessagingStyle
                val messagingStyle = NotificationCompat.MessagingStyle(senderPerson)
                if (isGroupConversation) {
                    messagingStyle.isGroupConversation = true
                    if (!conversationTitle.isNull_or_empty()) {
                        messagingStyle.conversationTitle = conversationTitle
                    }
                }
                messagingStyle.addMessage(body, timestamp, senderPerson)

                // Get small icon resource ID from app
                val smallIconResId = getSmallIconResId(context)

                // Build Notification
                val notificationBuilder = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(smallIconResId)
                    .setStyle(messagingStyle)
                    .setContentTitle(title ?: senderName)
                    .setContentText(body)
                    .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setAutoCancel(true)
                    .setDefaults(NotificationCompat.DEFAULT_ALL)
                    .setWhen(timestamp)

                val notificationManager = NotificationManagerCompat.from(context)
                if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < 33) {
                    notificationManager.notify(id, notificationBuilder.build())
                    mainHandler.post { result.success(true) }
                } else {
                    mainHandler.post { result.error("PERMISSION_DENIED", "POST_NOTIFICATIONS permission not granted", null) }
                }
            } catch (e: Exception) {
                mainHandler.post { result.error("SHOW_NOTIFICATION_FAILED", e.localizedMessage, e.stackTraceToString()) }
            }
        }
    }

    private fun handleCreateNotificationChannel(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            result.error("INVALID_ARGUMENTS", "Channel config map missing", null)
            return
        }
        val id = args["id"] as? String ?: "communication_channel"
        val name = args["name"] as? String ?: "Messages"
        val description = args["description"] as? String
        val importance = (args["importance"] as? Number)?.toInt() ?: NotificationManager.IMPORTANCE_HIGH
        val enableVibration = args["enableVibration"] as? Boolean ?: true
        val enableLights = args["enableLights"] as? Boolean ?: true

        createChannel(id, name, description, importance, enableVibration, enableLights)
        result.success(true)
    }

    private fun handleRequestPermissions(result: Result) {
        if (Build.VERSION.SDK_INT >= 33) {
            val granted = ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            result.success(granted)
        } else {
            val enabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
            result.success(enabled)
        }
    }

    private fun handleHasPermissions(result: Result) {
        val enabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
        result.success(enabled)
    }

    private fun handleCancelNotification(call: MethodCall, result: Result) {
        val id = (call.argument<Number>("id"))?.toInt() ?: return result.success(null)
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.cancel(id)
        result.success(null)
    }

    private fun handleCancelAllNotifications(result: Result) {
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.cancelAll()
        result.success(null)
    }

    private fun ensureNotificationChannel(id: String, name: String, description: String?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (notificationManager.getNotificationChannel(id) == null) {
                createChannel(id, name, description, NotificationManager.IMPORTANCE_HIGH, true, true)
            }
        }
    }

    private fun createChannel(
        id: String,
        name: String,
        description: String?,
        importance: Int,
        enableVibration: Boolean,
        enableLights: Boolean
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(id, name, importance).apply {
                this.description = description
                enableVibration(enableVibration)
                enableLights(enableLights)
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun fetchOrGenerateAvatar(
        context: Context,
        avatarUrl: String?,
        fallbackAsset: String?,
        senderName: String
    ): Bitmap {
        // 1. Try downloading HTTP/HTTPS avatar URL
        if (!avatarUrl.isNull_or_empty()) {
            try {
                val url = URL(avatarUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                connection.doInput = true
                connection.connect()

                if (connection.responseCode == 200) {
                    val inputStream = connection.inputStream
                    val originalBitmap = BitmapFactory.decodeStream(inputStream)
                    inputStream.close()
                    if (originalBitmap != null) {
                        return getCircularBitmap(originalBitmap)
                    }
                }
            } catch (_: Exception) {
                // Fallback to asset or generated avatar
            }
        }

        // 2. Try loading Flutter asset if specified
        if (!fallbackAsset.isNull_or_empty()) {
            try {
                val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(fallbackAsset)
                val assetStream = context.assets.open(key)
                val assetBitmap = BitmapFactory.decodeStream(assetStream)
                assetStream.close()
                if (assetBitmap != null) {
                    return getCircularBitmap(assetBitmap)
                }
            } catch (_: Exception) {
                // Fallback to letter avatar
            }
        }

        // 3. Generate fallback circular avatar with sender's initial letter
        return generateLetterAvatar(senderName)
    }

    private fun getCircularBitmap(bitmap: Bitmap): Bitmap {
        val size = Math.min(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        val paint = Paint().apply {
            isAntiAlias = true
            color = Color.BLACK
        }

        val rect = Rect(0, 0, size, size)
        val rectF = RectF(rect)

        canvas.drawARGB(0, 0, 0, 0)
        canvas.drawRoundRect(rectF, size / 2f, size / 2f, paint)

        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val srcRect = Rect((bitmap.width - size) / 2, (bitmap.height - size) / 2, (bitmap.width + size) / 2, (bitmap.height + size) / 2)
        canvas.drawBitmap(bitmap, srcRect, rect, paint)

        return output
    }

    private fun generateLetterAvatar(name: String): Bitmap {
        val size = 192
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background color based on name hash
        val colorHash = Math.abs(name.hashCode())
        val colors = intArrayOf(
            Color.parseColor("#4A90E2"),
            Color.parseColor("#50E3C2"),
            Color.parseColor("#B8E986"),
            Color.parseColor("#BD10E0"),
            Color.parseColor("#9013FE"),
            Color.parseColor("#F5A623")
        )
        val bgPaint = Paint().apply {
            isAntiAlias = true
            color = colors[colorHash % colors.size]
        }

        canvas.drawCircle(size / 2f, size / 2f, size / 2f, bgPaint)

        // Initial letter
        val initial = if (name.trim().isNotEmpty()) name.trim().substring(0, 1).uppercase() else "?"
        val textPaint = Paint().apply {
            isAntiAlias = true
            color = Color.WHITE
            textSize = 80f
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
        }

        val yPos = (canvas.height / 2f) - ((textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(initial, size / 2f, yPos, textPaint)

        return bitmap
    }

    private fun getSmallIconResId(context: Context): Int {
        val appIcon = context.applicationInfo.icon
        return if (appIcon != 0) appIcon else android.R.drawable.ic_dialog_info
    }

    private fun String?.isNull_or_empty(): Boolean = this == null || this.trim().isEmpty()

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
