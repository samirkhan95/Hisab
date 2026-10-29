const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendPushNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        const userId = data.user_id;

        // 1. Get the user's FCM token from the 'users' collection
        const userDoc = await admin.firestore().collection('users').doc(userId).get();

        if (!userDoc.exists) {
            console.log('User document does not exist:', userId);
            return null;
        }

        const fcmToken = userDoc.data().fcm_token;

        if (!fcmToken) {
            console.log('No FCM token found for user:', userId);
            return null;
        }

        // 2. Construct the message
        const message = {
            notification: {
                title: data.title,
                body: data.body,
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: data.type || 'general',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'high_importance_channel',
                    priority: 'max',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                }
            },
            token: fcmToken,
        };

        // 3. Send the notification
        try {
            await admin.messaging().send(message);
            console.log('Notification sent successfully to:', userId);
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    });
