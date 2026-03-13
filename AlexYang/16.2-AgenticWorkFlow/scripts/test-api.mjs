/**
 * Quick API connectivity test for Kimi and GLM
 */
import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load .env
const envPath = join(__dirname, '.env');
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, 'utf-8').split('\n')) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const [key, ...vp] = trimmed.split('=');
      process.env[key.trim()] = vp.join('=').trim();
    }
  }
}

async function testAPI(name, baseUrl, apiKey, model) {
  console.log(`\n--- Testing ${name} ---`);
  console.log(`  URL: ${baseUrl}/chat/completions`);
  console.log(`  Model: ${model}`);
  console.log(`  Key: ${apiKey ? apiKey.slice(0, 8) + '...' : 'NOT SET'}`);

  if (!apiKey) {
    console.log(`  ❌ ${name} API key not set!`);
    return false;
  }

  try {
    const res = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: [{ role: 'user', content: 'Say "hello" in one word.' }],
        max_tokens: 10,
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      console.log(`  ❌ HTTP ${res.status}: ${text.slice(0, 200)}`);
      return false;
    }

    const data = await res.json();
    const reply = data.choices?.[0]?.message?.content || '(empty)';
    console.log(`  ✅ Response: "${reply}"`);
    return true;
  } catch (err) {
    console.log(`  ❌ Error: ${err.message}`);
    return false;
  }
}

console.log('=== API Connectivity Test ===');

const kimiOk = await testAPI(
  'Kimi',
  process.env.KIMI_BASE_URL || 'https://api.moonshot.cn/v1',
  process.env.KIMI_API_KEY,
  process.env.KIMI_MODEL || 'moonshot-v1-128k'
);

const glmOk = await testAPI(
  'GLM',
  process.env.GLM_BASE_URL || 'https://open.bigmodel.cn/api/paas/v4',
  process.env.GLM_API_KEY,
  process.env.GLM_MODEL || 'glm-4'
);

console.log('\n=== Summary ===');
console.log(`Kimi: ${kimiOk ? '✅ OK' : '❌ FAILED'}`);
console.log(`GLM:  ${glmOk ? '✅ OK' : '❌ FAILED'}`);

if (kimiOk && glmOk) {
  console.log('\n🎉 All APIs connected! Pipeline ready to run.');
} else {
  console.log('\n⚠️  Fix API issues before running pipeline.');
}
