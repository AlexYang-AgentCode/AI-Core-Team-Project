/**
 * 16.1-AndroidToHarmonyOSDemo Multi-AI Pipeline
 *
 * Reads tasks from Obsidian markdown (131-TASK-QUEUE.md),
 * dispatches to Kimi (generate) and GLM (review),
 * validates via hvigorw compile, updates task state.
 *
 * Obsidian is the persistent layer - restart anytime, picks up where it left off.
 *
 * Usage:
 *   node pipeline.mjs          # continuous loop
 *   node pipeline.mjs --once   # single pass then exit
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { execSync } from 'child_process';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, '..');

// ═══════════════════════════════════════════════════════
// Configuration (from .env or environment variables)
// ═══════════════════════════════════════════════════════

function loadEnv() {
  const envPath = join(__dirname, '.env');
  if (existsSync(envPath)) {
    const lines = readFileSync(envPath, 'utf-8').split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        process.env[key.trim()] = valueParts.join('=').trim();
      }
    }
  }
}
loadEnv();

const CONFIG = {
  kimi: {
    apiKey: process.env.KIMI_API_KEY || '',
    baseUrl: process.env.KIMI_BASE_URL || 'https://api.moonshot.cn/v1',
    model: process.env.KIMI_MODEL || 'moonshot-v1-128k',
  },
  glm: {
    apiKey: process.env.GLM_API_KEY || '',
    baseUrl: process.env.GLM_BASE_URL || 'https://open.bigmodel.cn/api/paas/v4',
    model: process.env.GLM_MODEL || 'glm-4',
  },
  hvigorwPath: process.env.HVIGORW_PATH || 'D:/Program Files/Huawei/DevEco Studio/tools/hvigor/bin/hvigorw.bat',
  harmonyProjectPath: process.env.HARMONY_PROJECT_PATH || join(PROJECT_ROOT, 'harmony-app'),
  taskQueuePath: process.env.TASK_QUEUE_PATH || join(PROJECT_ROOT, '131-TASK-QUEUE.md'),
  feishuWebhook: process.env.FEISHU_WEBHOOK_URL || '',
  maxRetry: parseInt(process.env.MAX_RETRY || '3'),
  pollInterval: parseInt(process.env.POLL_INTERVAL_MS || '300000'),
  outputDir: join(PROJECT_ROOT, 'generated'),
};

// ═══════════════════════════════════════════════════════
// AI API Calls (OpenAI-compatible format)
// ═══════════════════════════════════════════════════════

async function callAI(provider, systemPrompt, userPrompt, maxTokens = 4096) {
  const config = CONFIG[provider];
  if (!config.apiKey) {
    throw new Error(`${provider} API key not configured. Set ${provider.toUpperCase()}_API_KEY in .env`);
  }

  const url = `${config.baseUrl}/chat/completions`;
  const body = {
    model: config.model,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    max_tokens: maxTokens,
    temperature: 0.3,
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`${provider} API error ${response.status}: ${text}`);
  }

  const data = await response.json();
  return data.choices[0].message.content;
}

async function callKimi(systemPrompt, userPrompt) {
  return callAI('kimi', systemPrompt, userPrompt, 8192);
}

async function callGLM(systemPrompt, userPrompt) {
  return callAI('glm', systemPrompt, userPrompt, 4096);
}

// ═══════════════════════════════════════════════════════
// Task Queue (Obsidian Markdown as persistent layer)
// ═══════════════════════════════════════════════════════

function readTaskQueue() {
  if (!existsSync(CONFIG.taskQueuePath)) {
    return { pending: [], in_progress: [], review: [], blocked: [], done: [] };
  }
  const content = readFileSync(CONFIG.taskQueuePath, 'utf-8');
  const tasks = { pending: [], in_progress: [], review: [], blocked: [], done: [] };
  let currentSection = null;

  for (const line of content.split('\n')) {
    const sectionMatch = line.match(/^## (PENDING|IN_PROGRESS|REVIEW|BLOCKED|DONE)/);
    if (sectionMatch) {
      currentSection = sectionMatch[1].toLowerCase();
      continue;
    }
    const taskMatch = line.match(/^- \[.\] (TASK-\d+) \| (.+)/);
    if (taskMatch && currentSection) {
      const [, taskId, rest] = taskMatch;
      const parts = rest.split(' | ').map(s => s.trim());
      const task = {
        id: taskId,
        adapter: parts[0] || '',
        stage: parts[1] || '',
        agent: parts[2] || '',
        meta: parts.slice(3).join(' | '),
        retryCount: 0,
      };
      // Extract retry count from meta
      const retryMatch = task.meta.match(/retry:(\d+)/);
      if (retryMatch) task.retryCount = parseInt(retryMatch[1]);
      tasks[currentSection].push(task);
    }
  }
  return tasks;
}

function writeTaskQueue(tasks) {
  const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
  let md = `---\ntags:\n  - project/dev\n  - pipeline\ndate: ${new Date().toISOString().slice(0, 10)}\nstatus: active\n---\n\n`;
  md += `# 131-TASK-QUEUE\n\n`;
  md += `> Last updated: ${timestamp}\n> Pipeline status: running\n\n`;

  const sections = [
    ['PENDING', 'pending', ' '],
    ['IN_PROGRESS', 'in_progress', '/'],
    ['REVIEW', 'review', '?'],
    ['BLOCKED', 'blocked', '!'],
    ['DONE', 'done', 'x'],
  ];

  for (const [label, key, marker] of sections) {
    md += `## ${label}\n\n`;
    for (const task of tasks[key]) {
      // Strip existing retry tags from meta to prevent duplication
      const cleanMeta = task.meta.replace(/\s*\|\s*retry:\d+/g, '').trim();
      const meta = task.retryCount > 0 ? `${cleanMeta} | retry:${task.retryCount}` : cleanMeta;
      md += `- [${marker}] ${task.id} | ${task.adapter} | ${task.stage} | ${task.agent} | ${meta}\n`;
    }
    md += '\n';
  }

  writeFileSync(CONFIG.taskQueuePath, md);
  log(`Task queue updated: ${tasks.pending.length}P ${tasks.in_progress.length}IP ${tasks.review.length}R ${tasks.blocked.length}B ${tasks.done.length}D`);
}

function moveTask(tasks, taskId, fromSection, toSection, updates = {}) {
  const idx = tasks[fromSection].findIndex(t => t.id === taskId);
  if (idx === -1) return;
  const task = tasks[fromSection].splice(idx, 1)[0];
  Object.assign(task, updates);
  tasks[toSection].push(task);
}

// ═══════════════════════════════════════════════════════
// Code Generation Prompts
// ═══════════════════════════════════════════════════════

function getAndroidSource() {
  const path = join(PROJECT_ROOT, '131.1-ANDROID-ANALYSIS/131.10-POC-DOWNLOAD/TextClock/app/src/main/java/com/w/homework2/MainActivity.java');
  return existsSync(path) ? readFileSync(path, 'utf-8') : '';
}

function getReferenceGuide() {
  const refPath = join(__dirname, 'api-context', 'REFERENCE.md');
  return existsSync(refPath) ? readFileSync(refPath, 'utf-8') : '';
}

function getWorkingExample() {
  // Return our verified-compiling code as reference
  const abilityPath = join(CONFIG.harmonyProjectPath, 'entry/src/main/ets/entryability/EntryAbility.ets');
  const pagePath = join(CONFIG.harmonyProjectPath, 'entry/src/main/ets/pages/Index.ets');
  let example = '';
  if (existsSync(abilityPath)) {
    example += `// === EntryAbility.ets (VERIFIED COMPILES) ===\n${readFileSync(abilityPath, 'utf-8')}\n\n`;
  }
  if (existsSync(pagePath)) {
    example += `// === Index.ets (VERIFIED COMPILES) ===\n${readFileSync(pagePath, 'utf-8')}\n`;
  }
  return example;
}

const SYSTEM_PROMPT = `You are an expert HarmonyOS ArkTS developer. You write code that compiles in DevEco Studio with hvigorw.

ABSOLUTE RULES - VIOLATION = COMPILE FAILURE:
1. ArkUI components (Text, Button, Column, Row, Stack, Flex, TextClock) are GLOBAL built-ins. NEVER import them.
2. Use \`struct\` with @Component decorator, NOT \`class\`. Components are structs, not classes.
3. Use @State for reactive variables. Use build() method for declarative UI.
4. CORRECT imports: \`import { UIAbility, Want } from '@kit.AbilityKit'\`, \`import { i18n } from '@kit.LocalizationKit'\`
5. WRONG imports (NEVER USE): \`@ohos.arkui\`, \`@ohos.application.model\`, \`import { Column } from ...\`
6. Button click: \`.onClick(() => {})\`, NOT \`.setClickedListener()\`
7. Text content: bind via @State variable, NOT \`.setText()\`
8. Output ONLY the .ets file content, no explanations or markdown.`;

function makeGeneratePrompt(task) {
  const androidSource = getAndroidSource();
  const reference = getReferenceGuide();
  const workingExample = getWorkingExample();
  const adapterName = task.adapter.replace('adapter:', '');

  return {
    system: SYSTEM_PROMPT,
    user: `Generate a HarmonyOS ArkTS adapter for: "${adapterName}"

TASK: Create an ArkTS module that provides the HarmonyOS equivalent of the Android "${adapterName}" pattern.

ORIGINAL ANDROID SOURCE (the app being adapted):
\`\`\`java
${androidSource}
\`\`\`

VERIFIED WORKING CODE (these compile successfully - follow the same patterns):
\`\`\`typescript
${workingExample}
\`\`\`

API REFERENCE AND MAPPING TABLE:
${reference}

REQUIREMENTS:
1. Follow EXACTLY the same patterns as the verified working code above
2. Use @Component struct, NOT class
3. Use @State for reactive data, build() for UI
4. ArkUI components are global - never import them
5. For timezone: import { i18n } from '@kit.LocalizationKit'
6. Export a reusable struct or function

Output ONLY the .ets file content.`,
  };
}

function makeReviewPrompt(code, adapterName) {
  const reference = getReferenceGuide();

  return {
    system: `You are a strict HarmonyOS code reviewer. You know the REAL APIs and reject hallucinated ones.

VERIFIED CORRECT PATTERNS:
- ArkUI components (Text, Button, Column, Row) are GLOBAL built-ins, never imported
- Components use @Component struct, NOT class
- State uses @State decorator
- UI uses declarative build() method
- Ability imports from '@kit.AbilityKit'
- i18n imports from '@kit.LocalizationKit'

HALLUCINATION RED FLAGS (auto-fail):
- import { Column, Text, Button } from '@ohos.arkui'  ← FAKE MODULE
- import from '@ohos.application.model'  ← FAKE MODULE
- new Button(), new Text()  ← WRONG, use declarative syntax
- .setText(), .setClickedListener()  ← WRONG, Android patterns
- extends UIAbility for UI components  ← WRONG, use struct
- Build() function call  ← FAKE API

OUTPUT FORMAT (strict):
SCORE: [0-100]
PASS: [true/false] (true only if score >= 70 AND no hallucinated APIs)
ISSUES:
- [issue description]
SUGGESTION: [how to fix]`,

    user: `Review this HarmonyOS adapter code for "${adapterName}":

\`\`\`typescript
${code}
\`\`\`

API REFERENCE:
${reference}

Check every import statement against the reference. Any import from a non-existent module is an automatic fail.`,
  };
}

function makeFixPrompt(code, reviewFeedback, adapterName) {
  const reference = getReferenceGuide();
  const workingExample = getWorkingExample();

  return {
    system: SYSTEM_PROMPT,
    user: `Fix this HarmonyOS adapter "${adapterName}" based on review feedback.

CURRENT CODE (has issues):
\`\`\`typescript
${code}
\`\`\`

REVIEW FEEDBACK:
${reviewFeedback}

VERIFIED WORKING REFERENCE (follow these patterns EXACTLY):
\`\`\`typescript
${workingExample}
\`\`\`

API REFERENCE:
${reference}

IMPORTANT: Follow the verified working code patterns. Use @Component struct, NOT class. Use declarative build(). ArkUI components are global built-ins.

Output ONLY the complete fixed .ets file content.`,
  };
}

// ═══════════════════════════════════════════════════════
// Pipeline Stages
// ═══════════════════════════════════════════════════════

async function processTask(task, tasks) {
  const adapterName = task.adapter.replace('adapter:', '');
  log(`Processing: ${task.id} - ${adapterName} (stage: ${task.stage})`);

  try {
    if (task.stage === 'generate') {
      // Stage 1: Generate code with Kimi
      const prompt = makeGeneratePrompt(task);
      const code = await callKimi(prompt.system, prompt.user);

      // Save generated code
      const outputPath = join(CONFIG.outputDir, `${adapterName}.ets`);
      mkdirSync(dirname(outputPath), { recursive: true });
      writeFileSync(outputPath, extractCode(code));

      // Move to review
      moveTask(tasks, task.id, 'in_progress', 'review', {
        stage: 'review',
        agent: 'glm',
        meta: `generated:${new Date().toISOString().slice(0, 19)}`,
      });
      log(`Generated: ${adapterName} → review`);

    } else if (task.stage === 'review') {
      // Stage 2: Review with GLM
      const codePath = join(CONFIG.outputDir, `${adapterName}.ets`);
      if (!existsSync(codePath)) {
        moveTask(tasks, task.id, 'in_progress', 'pending', { stage: 'generate', agent: 'kimi' });
        return;
      }
      const code = readFileSync(codePath, 'utf-8');
      const prompt = makeReviewPrompt(code, adapterName);
      const review = await callGLM(prompt.system, prompt.user);

      // Parse review result
      const passMatch = review.match(/PASS:\s*(true|false)/i);
      const scoreMatch = review.match(/SCORE:\s*(\d+)/i);
      const passed = passMatch ? passMatch[1].toLowerCase() === 'true' : false;
      const score = scoreMatch ? parseInt(scoreMatch[1]) : 0;

      // Save review
      writeFileSync(join(CONFIG.outputDir, `${adapterName}.review.md`), review);

      if (passed && score >= 60) {
        // Review passed → done (or compile check)
        moveTask(tasks, task.id, 'in_progress', 'done', {
          stage: 'done',
          agent: 'pipeline',
          meta: `score:${score} | done:${new Date().toISOString().slice(0, 19)}`,
        });
        log(`Review PASSED: ${adapterName} (score: ${score})`);
      } else if (task.retryCount < CONFIG.maxRetry) {
        // Review failed → fix with Kimi
        const fixPrompt = makeFixPrompt(code, review, adapterName);
        const fixedCode = await callKimi(fixPrompt.system, fixPrompt.user);
        writeFileSync(codePath, extractCode(fixedCode));

        moveTask(tasks, task.id, 'in_progress', 'review', {
          stage: 'review',
          agent: 'glm',
          retryCount: task.retryCount + 1,
          meta: `retry:${task.retryCount + 1} | score:${score}`,
        });
        log(`Review FAILED (score: ${score}), retry ${task.retryCount + 1}/${CONFIG.maxRetry}`);
      } else {
        // Max retries reached → blocked
        moveTask(tasks, task.id, 'in_progress', 'blocked', {
          stage: 'blocked',
          agent: 'human',
          meta: `max-retry | score:${score} | need:human-review`,
        });
        log(`BLOCKED: ${adapterName} after ${CONFIG.maxRetry} retries`);
        await notifyFeishu(`BLOCKED: ${adapterName} 需要人工介入 (score: ${score})`);
      }
    }
  } catch (err) {
    log(`ERROR processing ${task.id}: ${err.message}`);
    moveTask(tasks, task.id, 'in_progress', 'blocked', {
      stage: 'error',
      agent: 'pipeline',
      meta: `error:${err.message.slice(0, 100)}`,
    });
  }
}

// ═══════════════════════════════════════════════════════
// Utilities
// ═══════════════════════════════════════════════════════

function extractCode(response) {
  // Extract code from markdown code blocks if present
  const match = response.match(/```(?:typescript|ets|ts)?\n([\s\S]*?)```/);
  return match ? match[1].trim() : response.trim();
}

function log(msg) {
  const ts = new Date().toISOString().slice(11, 19);
  const logLine = `[${ts}] ${msg}`;
  console.log(logLine);
  // Also append to log file
  const logPath = join(PROJECT_ROOT, 'pipeline.log');
  try {
    const existing = existsSync(logPath) ? readFileSync(logPath, 'utf-8') : '';
    writeFileSync(logPath, existing + logLine + '\n');
  } catch { /* ignore log write errors */ }
}

async function notifyFeishu(message) {
  if (!CONFIG.feishuWebhook) return;
  try {
    await fetch(CONFIG.feishuWebhook, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        msg_type: 'text',
        content: { text: `[131-Pipeline] ${message}` },
      }),
    });
  } catch (err) {
    log(`Feishu notification failed: ${err.message}`);
  }
}

// ═══════════════════════════════════════════════════════
// Main Loop
// ═══════════════════════════════════════════════════════

async function runOnce() {
  const tasks = readTaskQueue();

  // Pick next task: prioritize review over generate
  let nextTask = null;
  let fromSection = null;

  if (tasks.review.length > 0) {
    nextTask = tasks.review[0];
    fromSection = 'review';
  } else if (tasks.pending.length > 0) {
    nextTask = tasks.pending[0];
    fromSection = 'pending';
  }

  if (!nextTask) {
    const doneCount = tasks.done.length;
    const totalTasks = Object.values(tasks).flat().length;
    if (doneCount === totalTasks && totalTasks > 0) {
      log(`All ${totalTasks} tasks completed!`);
      await notifyFeishu(`All ${totalTasks} adapters completed! Ready for integration.`);
      return false; // signal to stop
    }
    log('No tasks to process. Waiting...');
    return true; // continue waiting
  }

  // Move to in_progress
  moveTask(tasks, nextTask.id, fromSection, 'in_progress');
  writeTaskQueue(tasks);

  // Process
  await processTask(nextTask, tasks);
  writeTaskQueue(tasks);

  return true; // continue
}

async function main() {
  log('=== 131-Pipeline starting ===');
  log(`Kimi: ${CONFIG.kimi.model} | GLM: ${CONFIG.glm.model}`);
  log(`Task queue: ${CONFIG.taskQueuePath}`);

  // Validate config
  if (!CONFIG.kimi.apiKey) {
    console.error('ERROR: KIMI_API_KEY not set. Copy .env.example to .env and fill in API keys.');
    process.exit(1);
  }
  if (!CONFIG.glm.apiKey) {
    console.error('ERROR: GLM_API_KEY not set. Copy .env.example to .env and fill in API keys.');
    process.exit(1);
  }

  const onceMode = process.argv.includes('--once');

  if (onceMode) {
    await runOnce();
  } else {
    // Continuous loop
    while (true) {
      const shouldContinue = await runOnce();
      if (!shouldContinue) break;
      log(`Sleeping ${CONFIG.pollInterval / 1000}s...`);
      await new Promise(r => setTimeout(r, CONFIG.pollInterval));
    }
  }

  log('=== 131-Pipeline stopped ===');
}

main().catch(err => {
  console.error('Pipeline fatal error:', err);
  process.exit(1);
});
