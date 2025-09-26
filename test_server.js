const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;

// Имитация AI ответов (без OpenAI API)
const mockAIResponses = {
  story: "Жил-был маленький {name}, который любил приключения. Однажды {name} отправился в волшебный лес...",
  advice: "В возрасте вашего ребенка важно развивать творческие навыки и поощрять любознательность."
};

// Простая база данных в памяти
let users = {};
let stories = {};

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const url = req.url;
  const method = req.method;

  console.log(`${method} ${url}`);

  if (url === '/' && method === 'GET') {
    // Главная страница с API документацией
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`
      <h1>Master Parenthood Test Server 🌟</h1>
      <p>Сервер для тестирования функций приложения</p>
      <h2>API Endpoints:</h2>
      <ul>
        <li><strong>POST /api/auth/register</strong> - Регистрация пользователя</li>
        <li><strong>POST /api/auth/login</strong> - Вход пользователя</li>
        <li><strong>POST /api/stories/generate</strong> - Генерация сказки</li>
        <li><strong>GET /api/stories</strong> - Получить все сказки</li>
        <li><strong>POST /api/ai/advice</strong> - Получить совет от AI</li>
        <li><strong>GET /api/health</strong> - Проверка работы сервера</li>
      </ul>
    `);
  }

  else if (url === '/api/health' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      timestamp: new Date().toISOString(),
      message: 'Master Parenthood Test Server работает!'
    }));
  }

  else if (url === '/api/auth/register' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { email, password, name } = JSON.parse(body);

        if (users[email]) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Пользователь уже существует' }));
          return;
        }

        users[email] = { email, name, password, id: Date.now() };

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          user: { email, name, id: users[email].id }
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/auth/login' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { email, password } = JSON.parse(body);

        if (!users[email] || users[email].password !== password) {
          res.writeHead(401, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Неверные учетные данные' }));
          return;
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          user: { email, name: users[email].name, id: users[email].id }
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/stories/generate' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { childName, theme, userId } = JSON.parse(body);

        let story = mockAIResponses.story.replace(/{name}/g, childName || 'малыш');

        if (theme) {
          story += ` Тема истории: ${theme}. `;
        }

        story += "И они жили долго и счастливо! ✨";

        const storyId = Date.now();
        stories[storyId] = {
          id: storyId,
          childName,
          theme,
          story,
          userId,
          createdAt: new Date().toISOString()
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          story: stories[storyId]
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/stories' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: true,
      stories: Object.values(stories)
    }));
  }

  else if (url === '/api/ai/advice' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { childAge, question } = JSON.parse(body);

        let advice = mockAIResponses.advice;

        if (childAge) {
          advice = `Для ребенка ${childAge} лет: ` + advice;
        }

        if (question) {
          advice += ` Относительно вашего вопроса: "${question}" - рекомендую обратиться к специалисту для более детальной консультации.`;
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          advice: advice
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  // 🚀 NEW 2025 AI ENDPOINTS

  else if (url === '/api/ai/behavior-analysis' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { childName, ageInMonths, behaviors } = JSON.parse(body);

        const analysis = {
          analysis: `${childName} shows typical behavioral patterns for ${ageInMonths} months old. Recent behaviors indicate healthy emotional and social development.`,
          triggers: ['Переутомление', 'Голод', 'Недостаток внимания'],
          strategies: [
            'Поддерживайте регулярный режим дня',
            'Используйте позитивное подкрепление',
            'Обеспечьте достаточное время для отдыха'
          ],
          alerts: [],
          positivePatterns: ['Активное исследование мира', 'Хорошие социальные навыки', 'Любознательность']
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, analysis }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/ai/predict-development' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { childName, ageInMonths, currentMilestones } = JSON.parse(body);

        const predictions = {
          nextMilestones: [
            'Улучшение координации движений',
            'Расширение словарного запаса',
            'Развитие самостоятельности'
          ],
          timeframe: 'Следующие 2-3 месяца',
          recommendations: [
            'Читайте книги каждый день',
            'Поощряйте физическую активность',
            'Развивайте творческие способности'
          ],
          watchFor: [
            'Изменения в аппетите',
            'Нарушения сна',
            'Регресс в навыках'
          ],
          strengths: [
            'Отличная социализация',
            'Хорошее физическое развитие',
            'Активное любопытство'
          ]
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, predictions }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/ai/personalized-activities' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { childName, ageInMonths, interests, skills } = JSON.parse(body);

        const activities = {
          activities: [
            {
              name: 'Сенсорная коробка с природными материалами',
              description: `Создайте коробку с листьями, шишками и камешками для ${childName}. Это развивает тактильные ощущения и любознательность.`,
              materials: ['Коробка', 'Листья', 'Шишки', 'Гладкие камешки'],
              duration: '15-20 минут',
              skills: ['Сенсорное развитие', 'Мелкая моторика', 'Концентрация внимания']
            },
            {
              name: 'Музыкальный оркестр из подручных средств',
              description: `Используйте кастрюли, ложки и бутылочки с крупой для создания музыкальных инструментов для ${childName}.`,
              materials: ['Кастрюли', 'Ложки', 'Бутылочки с крупой', 'Металлические миски'],
              duration: '10-15 минут',
              skills: ['Слуховое восприятие', 'Ритм', 'Крупная моторика']
            },
            {
              name: 'Игра в сортировку по цветам',
              description: `Соберите предметы разных цветов и предложите ${childName} рассортировать их по группам.`,
              materials: ['Цветные игрушки', 'Контейнеры', 'Цветная бумага'],
              duration: '10-12 минут',
              skills: ['Цветовосприятие', 'Логическое мышление', 'Классификация']
            }
          ]
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, activities }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/ai/mood-analysis' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { childName, moodEntries, behaviorNotes } = JSON.parse(body);

        const moodAnalysis = {
          moodPattern: 'Стабильные эмоциональные колебания, соответствующие возрасту',
          emotionalDevelopment: 'Здоровое эмоциональное развитие с хорошей способностью к самовыражению',
          concerns: [],
          strategies: [
            'Подтверждайте эмоции ребенка словами',
            'Обучайте названиям эмоций',
            'Читайте книги о чувствах'
          ],
          positives: [
            'Открытое выражение эмоций',
            'Поиск утешения у взрослых',
            'Способность к саморегуляции'
          ]
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, moodAnalysis }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/ai/chat' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { message, childContext } = JSON.parse(body);

        const responses = [
          `Понимаю ваше беспокойство по поводу "${message}". Каждый ребенок развивается в своем темпе, и это совершенно нормально.`,
          `Отличный вопрос! Относительно "${message}" - рекомендую наблюдать за естественными интересами ребенка и поддерживать их.`,
          `Спасибо за вопрос о "${message}". В этом возрасте важно создавать безопасную и поддерживающую среду для исследований.`,
          `Касательно "${message}" - помните, что последовательность и терпение - ключевые факторы в развитии ребенка.`
        ];

        const randomResponse = responses[Math.floor(Math.random() * responses.length)];

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          response: randomResponse
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else if (url === '/api/smart-notifications/optimal-time' && method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { notificationType, userId } = JSON.parse(body);

        const optimalTimes = {
          feeding_reminder: { optimalHour: 8, confidence: 0.8 },
          sleep_time: { optimalHour: 20, confidence: 0.9 },
          development_tip: { optimalHour: 14, confidence: 0.7 },
          milestone_reminder: { optimalHour: 10, confidence: 0.6 }
        };

        const result = optimalTimes[notificationType] || { optimalHour: 12, confidence: 0.5 };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          ...result,
          reasoning: `На основе анализа ваших взаимодействий, оптимальное время для ${notificationType} - ${result.optimalHour}:00`,
          alternativeTimes: [result.optimalHour - 2, result.optimalHour + 2]
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Неверный формат данных' }));
      }
    });
  }

  else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint не найден' }));
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Master Parenthood Test Server запущен!`);
  console.log(`📱 Локальный адрес: http://localhost:${PORT}`);
  console.log(`🌐 Сетевой адрес: http://[IP-телефона]:${PORT}`);
  console.log(`📋 API документация: http://localhost:${PORT}`);
  console.log(`✅ Готов к тестированию функций приложения!`);
});