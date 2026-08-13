package dev.hungnguyen.flutter_communication_avatar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput

class QuickReplyReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_REPLY = "dev.hungnguyen.flutter_communication_avatar.ACTION_REPLY"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_CONVERSATION_ID = "conversation_id"
        const val KEY_TEXT_REPLY = "key_text_reply"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REPLY) {
            val remoteInput = RemoteInput.getResultsFromIntent(intent)
            val replyText = remoteInput?.getCharSequence(KEY_TEXT_REPLY)?.toString()
            val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
            val conversationId = intent.getStringExtra(EXTRA_CONVERSATION_ID) ?: ""

            if (!replyText.isNullOrEmpty()) {
                FlutterCommunicationAvatarPlugin.onReplyReceived(replyText, notificationId, conversationId)
            }
        }
    }
}
