/**
 * ToastBridge POC
 * 将Android Toast API桥接到HarmonyOS promptAction
 * 
 * Android API: Toast.makeText(context, message, duration).show()
 * HarmonyOS:  promptAction.showToast({ message, duration })
 */

// 模拟HarmonyOS promptAction (在实际鸿蒙项目中由系统提供)
const promptAction = {
  showToast: (options: { message: string, duration: number }) => {
    console.log(`[TOAST] ${options.message} (duration: ${options.duration}ms)`);
    // 实际鸿蒙环境会显示UI提示
  }
};

// 模拟Android Context
class MockContext {
  getString(resId: number): string {
    return `Resource_${resId}`;
  }
}

type Context = MockContext;

/**
 * ToastBridge - Android Toast API的鸿蒙兼容实现
 */
export class ToastBridge {
  // Android Toast常量
  static readonly LENGTH_SHORT = 2000;  // Android: 2000ms
  static readonly LENGTH_LONG = 3500;   // Android: 3500ms
  
  private message: string;
  private duration: number;
  
  /**
   * 工厂方法 - 对应Android Toast.makeText()
   */
  static makeText(context: Context, message: string, duration: number): ToastBridge {
    // 注意: HarmonyOS不需要context参数，但为了API兼容保留
    console.log(`Toast.makeText() called with context: ${context ? 'provided' : 'null'}`);
    return new ToastBridge(message, duration);
  }
  
  /**
   * 构造函数
   */
  private constructor(message: string, duration: number) {
    this.message = message;
    this.duration = duration;
  }
  
  /**
   * 显示Toast - 对应Android toast.show()
   */
  show(): void {
    promptAction.showToast({
      message: this.message,
      duration: this.duration
    });
  }
  
  /**
   * 获取消息文本 (Android API)
   */
  getView(): null {
    // Android Toast.getView() 返回Toast的View，鸿蒙无此概念
    return null;
  }
  
  /**
   * 设置文字 (Android API)
   */
  setText(text: string): void {
    this.message = text;
  }
  
  /**
   * 设置显示时长 (Android API)
   */
  setDuration(duration: number): void {
    this.duration = duration;
  }
}

/**
 * 简化的Toast工具函数 (常用场景)
 */
export function showToast(message: string, isLong: boolean = false): void {
  const duration = isLong ? ToastBridge.LENGTH_LONG : ToastBridge.LENGTH_SHORT;
  ToastBridge.makeText(new MockContext(), message, duration).show();
}

// ============================================
// POC测试用例
// ============================================

console.log("=== ToastBridge POC测试 ===\n");

// 测试用例1: Calculator错误提示场景
console.log("测试1: Calculator 'Wrong Format' 错误提示");
const context = new MockContext();
ToastBridge.makeText(context, "Wrong Format", ToastBridge.LENGTH_LONG).show();

// 测试用例2: Calculator除以零错误
console.log("\n测试2: Calculator除以零提示");
ToastBridge.makeText(context, "Division by zero is not allowed", ToastBridge.LENGTH_SHORT).show();

// 测试用例3: 简化的工具函数
console.log("\n测试3: 简化工具函数");
showToast("Quick toast message");

// 测试用例4: 多次连续调用 (Calculator中可能出现的场景)
console.log("\n测试4: 连续错误提示");
const errors = [
  "Wrong format",
  "Wrong Format. Operand Without any numbers?",
  "Division by zero is not allowed"
];

errors.forEach((error, index) => {
  setTimeout(() => {
    ToastBridge.makeText(context, error, ToastBridge.LENGTH_LONG).show();
  }, index * 100);
});

console.log("\n=== 所有测试完成 ===");

/**
 * 在鸿蒙项目中的使用方式:
 * 
 * // 导入Bridge
 * import { ToastBridge } from '../system-bridge/ToastBridge';
 * 
 * // Android代码自动映射:
 * // Toast.makeText(getApplicationContext(), "message", Toast.LENGTH_SHORT).show();
 * // ↓ JIT编译后 ↓
 * ToastBridge.makeText(ContextBridge.getApplicationContext(), "message", ToastBridge.LENGTH_SHORT).show();
 */
