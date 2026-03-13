#!/bin/bash

# 飞书 Webhook 测试脚本
# 用途: 测试 16.1-AndroidToHarmonyOSDemo 机器人 Webhook 是否工作正常
# 日期: 2026-03-09
# 来源: 16.1-HAND-001

WEBHOOK_URL="${1:-}"

if [ -z "$WEBHOOK_URL" ]; then
    echo "❌ 错误: 需要提供 Webhook URL 作为参数"
    echo ""
    echo "使用方法:"
    echo "  bash test_webhook.sh 'https://open.feishu.cn/open-apis/bot/v2/hook/xxxxx'"
    echo ""
    echo "或者将 URL 保存到 feishu_webhook.txt 文件中，然后运行:"
    echo "  bash test_webhook.sh"
    exit 1
fi

# 测试消息 1: 简单文本
echo "📤 发送测试消息 1: 简单文本..."
RESPONSE1=$(curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "✅ 16.1-AndroidToHarmonyOSDemo 机器人测试成功！\n时间: 2026-03-09\n状态: Webhook 配置正确"
  }')

echo "服务器响应: $RESPONSE1"

# 检查响应
if echo "$RESPONSE1" | grep -q '"code":0'; then
    echo "✅ 测试消息 1 发送成功！"
else
    echo "❌ 测试消息 1 发送失败，请检查 Webhook URL"
    exit 1
fi

echo ""
echo "⏳ 等待 2 秒..."
sleep 2

# 测试消息 2: 富文本格式
echo "📤 发送测试消息 2: 富文本格式..."
RESPONSE2=$(curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "msg_type": "post",
    "content": {
      "post": {
        "zh_cn": {
          "title": "🤖 131 项目 - Webhook 测试报告",
          "content": [
            [
              {
                "tag": "text",
                "text": "项目: 16.1-AndroidToHarmonyOSDemo"
              }
            ],
            [
              {
                "tag": "text",
                "text": "状态: ✅ Webhook 配置完成"
              }
            ],
            [
              {
                "tag": "text",
                "text": "下一步: 启动 Phase 1 自动化任务"
              }
            ]
          ]
        }
      }
    }
  }')

echo "服务器响应: $RESPONSE2"

if echo "$RESPONSE2" | grep -q '"code":0'; then
    echo "✅ 测试消息 2 发送成功！"
else
    echo "⚠️ 测试消息 2 可能有问题，但这不影响使用"
fi

echo ""
echo "✨ Webhook 测试完成！"
echo "请检查飞书群组中是否收到上述两条消息。"
echo ""
echo "如果收到了消息，说明 Webhook 配置正确 ✅"
echo "如果没有收到，请检查:"
echo "  1. Webhook URL 是否复制正确"
echo "  2. 飞书机器人是否已加入群组"
echo "  3. 飞书群组是否允许机器人发送消息"
