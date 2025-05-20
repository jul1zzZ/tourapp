const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const admin = require("firebase-admin");

initializeApp();

exports.notifyBookingStatusChanged = onDocumentUpdated(
  "hotel_booking/{bookingId}",
  async (event) => {
    const beforeData = event.data.oldValue?.data || {};
    const afterData = event.data.value?.data || {};

    // Если статус не изменился, выходим
    if (beforeData.status === afterData.status) {
      return;
    }

    const userId = afterData.userId;
    if (!userId) {
      console.log("userId отсутствует в обновленном документе");
      return;
    }

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const fcmToken = userDoc.get("fcmToken");

    if (!fcmToken) {
      console.log(`FCM токен не найден для пользователя ${userId}`);
      return;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: "Обновление бронирования",
        body:
          `Статус вашего бронирования "${afterData.hotelName}" изменён: ` +
          `${afterData.status}`,
      },
      data: {
        bookingId: event.params.bookingId,
        status: afterData.status,
      },
    };

    try {
      await admin.messaging().send(payload);
      console.log(`Пуш отправлен пользователю ${userId}`);
    } catch (error) {
      console.error("Ошибка отправки пуша:", error);
    }
  },
);
