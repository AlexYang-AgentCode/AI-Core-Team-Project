/**
 * ContextBridge.ts
 * Android Context API 到 HarmonyOS UIAbilityContext 的桥接实现
 * 
 * 提供应用上下文访问、资源获取等核心功能
 */

import { UIAbilityContext } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

/**
 * Context 桥接类
 * 模拟Android Context的核心功能
 */
export class ContextBridge {
  private static applicationContext: UIAbilityContext | null = null;
  private static resourceManager: resourceManager.ResourceManager | null = null;

  /**
   * 初始化ContextBridge
   * 在UIAbility.onCreate()中调用
   * @param context UIAbilityContext实例
   */
  static initialize(context: UIAbilityContext): void {
    ContextBridge.applicationContext = context;
    ContextBridge.resourceManager = context.resourceManager;
  }

  /**
   * 获取应用上下文
   * 对应Android: getApplicationContext()
   */
  static getApplicationContext(): UIAbilityContext {
    if (!ContextBridge.applicationContext) {
      throw new Error('ContextBridge not initialized. Call initialize() in UIAbility.onCreate()');
    }
    return ContextBridge.applicationContext;
  }

  /**
   * 获取当前Context
   * 对应Android: getContext()
   */
  static getContext(): UIAbilityContext {
    return this.getApplicationContext();
  }

  /**
   * 获取资源管理器
   */
  static getResourceManager(): resourceManager.ResourceManager {
    if (!ContextBridge.resourceManager) {
      throw new Error('ResourceManager not available');
    }
    return ContextBridge.resourceManager;
  }

  /**
   * 获取字符串资源
   * 对应Android: getString(resId)
   * @param resId 资源ID（使用资源名称字符串，如"app.string.app_name"）
   */
  static async getString(resId: string): Promise<string> {
    const rm = this.getResourceManager();
    try {
      const resource = await rm.getStringValue($r(resId).id);
      return resource;
    } catch (error) {
      console.error(`Failed to get string resource: ${resId}`, error);
      return '';
    }
  }

  /**
   * 获取颜色资源
   * 对应Android: getColor(resId)
   * @param resId 资源ID（使用资源名称字符串，如"app.color.primary"）
   */
  static async getColor(resId: string): Promise<string> {
    const rm = this.getResourceManager();
    try {
      const resource = await rm.getColor($r(resId).id);
      return resource;
    } catch (error) {
      console.error(`Failed to get color resource: ${resId}`, error);
      return '#000000';
    }
  }

  /**
   * 获取布尔值资源
   */
  static async getBoolean(resId: string): Promise<boolean> {
    const rm = this.getResourceManager();
    try {
      const resource = await rm.getBoolean($r(resId).id);
      return resource;
    } catch (error) {
      console.error(`Failed to get boolean resource: ${resId}`, error);
      return false;
    }
  }

  /**
   * 获取数值资源
   */
  static async getNumber(resId: string): Promise<number> {
    const rm = this.getResourceManager();
    try {
      const resource = await rm.getNumber($r(resId).id);
      return resource;
    } catch (error) {
      console.error(`Failed to get number resource: ${resId}`, error);
      return 0;
    }
  }

  /**
   * 获取包名
   * 对应Android: getPackageName()
   */
  static getPackageName(): string {
    return this.getApplicationContext().applicationInfo.name;
  }

  /**
   * 获取应用信息
   */
  static getApplicationInfo() {
    return this.getApplicationContext().applicationInfo;
  }

  /**
   * 获取缓存目录
   * 对应Android: getCacheDir()
   */
  static getCacheDir(): string {
    return this.getApplicationContext().cacheDir;
  }

  /**
   * 获取文件目录
   * 对应Android: getFilesDir()
   */
  static getFilesDir(): string {
    return this.getApplicationContext().filesDir;
  }

  /**
   * 获取外部缓存目录
   */
  static getExternalCacheDir(): string {
    return this.getApplicationContext().cacheDir;
  }

  /**
   * 检查是否已初始化
   */
  static isInitialized(): boolean {
    return ContextBridge.applicationContext !== null;
  }
}

/**
 * 简化的Context类（兼容Android API）
 */
export class Context {
  /**
   * 获取应用上下文
   */
  static getApplicationContext(): UIAbilityContext {
    return ContextBridge.getApplicationContext();
  }

  /**
   * 获取字符串资源
   */
  static async getString(resId: string): Promise<string> {
    return ContextBridge.getString(resId);
  }

  /**
   * 获取颜色资源
   */
  static async getColor(resId: string): Promise<string> {
    return ContextBridge.getColor(resId);
  }
}

export default ContextBridge;
