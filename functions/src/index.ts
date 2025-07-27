// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as cors from 'cors';
import axios from 'axios';

// Инициализация Admin SDK
admin.initializeApp();

// Настройка CORS
const corsHandler = cors({ origin: true });

// ===== VK Authentication =====
export const createVKCustomToken = functions.https.onRequest((request, response) => {
  corsHandler(request, response, async () => {
    try {
      const { userId, accessToken, email } = request.body;

      if (!userId || !accessToken) {
        response.status(400).json({
          error: 'Missing required parameters: userId, accessToken'
        });
        return;
      }

      // Верификация VK токена
      const vkResponse = await axios.get('https://api.vk.com/method/users.get', {
        params: {
          user_ids: userId,
          fields: 'photo_200,first_name,last_name',
          access_token: accessToken,
          v: '5.131'
        }
      });

      if (!vkResponse.data.response || !vkResponse.data.response[0]) {
        response.status(401).json({
          error: 'Invalid VK token'
        });
        return;
      }

      const vkUser = vkResponse.data.response[0];
      const uid = `vk_${userId}`;

      // Создаем или обновляем пользователя в Firebase Auth
      let firebaseUser;
      try {
        firebaseUser = await admin.auth().getUser(uid);
      } catch (error) {
        // Пользователь не существует, создаем нового
        firebaseUser = await admin.auth().createUser({
          uid: uid,
          email: email || `${userId}@vk.local`,
          displayName: `${vkUser.first_name} ${vkUser.last_name}`,
          photoURL: vkUser.photo_200
        });
      }

      // Создаем custom token
      const customToken = await admin.auth().createCustomToken(uid);

      // Обновляем профиль в Firestore
      const userRef = admin.firestore().collection('users').doc(uid);
      await userRef.set({
        uid: uid,
        email: email || `${userId}@vk.local`,
        displayName: `${vkUser.first_name} ${vkUser.last_name}`,
        photoURL: vkUser.photo_200,
        provider: 'vk.com',
        vkId: userId,
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      response.json({
        customToken: customToken,
        user: {
          uid: uid,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL
        }
      });

    } catch (error) {
      console.error('VK auth error:', error);
      response.status(500).json({
        error: 'Internal server error'
      });
    }
  });
});

// ===== Yandex Authentication =====
export const createYandexCustomToken = functions.https.onRequest((request, response) => {
  corsHandler(request, response, async () => {
    try {
      const { accessToken } = request.body;

      if (!accessToken) {
        response.status(400).json({
          error: 'Missing required parameter: accessToken'
        });
        return;
      }

      // Получаем информацию о пользователе от Яндекс
      const yandexResponse = await axios.get('https://login.yandex.ru/info', {
        headers: {
          'Authorization': `OAuth ${accessToken}`
        }
      });

      if (!yandexResponse.data || !yandexResponse.data.id) {
        response.status(401).json({
          error: 'Invalid Yandex token'
        });
        return;
      }

      const yandexUser = yandexResponse.data;
      const uid = `yandex_${yandexUser.id}`;

      // Создаем или обновляем пользователя в Firebase Auth
      let firebaseUser;
      try {
        firebaseUser = await admin.auth().getUser(uid);
      } catch (error) {
        // Пользователь не существует, создаем нового
        firebaseUser = await admin.auth().createUser({
          uid: uid,
          email: yandexUser.default_email || `${yandexUser.id}@yandex.local`,
          displayName: yandexUser.real_name || yandexUser.display_name || 'Yandex User',
          photoURL: `https://avatars.yandex.net/get-yapic/${yandexUser.default_avatar_id}/islands-200`
        });
      }

      // Создаем custom token
      const customToken = await admin.auth().createCustomToken(uid);

      // Обновляем профиль в Firestore
      const userRef = admin.firestore().collection('users').doc(uid);
      await userRef.set({
        uid: uid,
        email: yandexUser.default_email || `${yandexUser.id}@yandex.local`,
        displayName: yandexUser.real_name || yandexUser.display_name || 'Yandex User',
        photoURL: `https://avatars.yandex.net/get-yapic/${yandexUser.default_avatar_id}/islands-200`,
        provider: 'yandex.ru',
        yandexId: yandexUser.id,
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      response.json({
        customToken: customToken,
        user: {
          uid: uid,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL
        }
      });

    } catch (error) {
      console.error('Yandex auth error:', error);
      response.status(500).json({
        error: 'Internal server error'
      });
    }
  });
});

// ===== Scheduled Functions =====

// Функция для обновления статистики питомцев (запускается каждый день)
export const updatePetStats = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Europe/Moscow')
  .onRun(async (context) => {
    const usersSnapshot = await admin.firestore().collection('users').get();

    const batch = admin.firestore().batch();

    for (const userDoc of usersSnapshot.docs) {
      const childrenSnapshot = await userDoc.ref.collection('children').get();

      for (const childDoc of childrenSnapshot.docs) {
        const childData = childDoc.data();
        const petStats = childData.petStats || {
          happiness: 50,
          energy: 50,
          knowledge: 50
        };

        // Уменьшаем статистику питомца со временем
        const newStats = {
          happiness: Math.max(0, petStats.happiness - 5),
          energy: Math.max(0, petStats.energy - 10),
          knowledge: Math.max(0, petStats.knowledge - 2)
        };

        batch.update(childDoc.ref, { petStats: newStats });
      }
    }

    await batch.commit();
    console.log('Pet stats updated successfully');
  });

// ===== Helper Functions =====

// Функция для отправки уведомлений о достижениях
export const sendAchievementNotification = functions.firestore
  .document('users/{userId}/achievements/{achievementId}')
  .onCreate(async (snap, context) => {
    const achievement = snap.data();
    const userId = context.params.userId;

    if (achievement.unlocked) {
      // Создаем уведомление в Firestore
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          type: 'achievement',
          title: 'Новое достижение!',
          message: `Поздравляем! Вы разблокировали достижение "${achievement.title}"`,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
  });

// Функция для очистки старых сказок (хранить только последние 100)
export const cleanupOldStories = functions.firestore
  .document('users/{userId}/stories/{storyId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;

    // Получаем все сказки пользователя
    const storiesRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('stories')
      .orderBy('createdAt', 'desc');

    const snapshot = await storiesRef.get();

    // Если больше 100 сказок, удаляем старые
    if (snapshot.size > 100) {
      const batch = admin.firestore().batch();
      const toDelete = snapshot.docs.slice(100);

      toDelete.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${toDelete.length} old stories for user ${userId}`);
    }
  });