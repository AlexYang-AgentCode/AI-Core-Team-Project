/**
 * ResourceMapper.ts
 * Android R资源ID到HarmonyOS资源引用的映射
 * 
 * 提供编译时资源ID映射表和运行时资源访问
 */

import { ContextBridge } from '../bridges/ContextBridge';

/**
 * 资源类型
 */
export type ResourceType = 'string' | 'color' | 'dimen' | 'drawable' | 'layout' | 'id' | 'bool' | 'integer' | 'array';

/**
 * 资源映射项
 */
export interface ResourceMapping {
  androidId: number;      // Android R.id.xxx
  harmonyPath: string;    // HarmonyOS $r('app.xxx.xxx')
  type: ResourceType;
  name: string;
}

/**
 * 资源映射表
 * 由编译时工具自动生成
 */
export class ResourceMapper {
  // 资源映射表（运行时动态加载）
  private static mappingTable: Map<number, ResourceMapping> = new Map();

  /**
   * 注册资源映射
   * 在应用启动时调用
   */
  static registerMapping(androidId: number, harmonyPath: string, type: ResourceType, name: string): void {
    this.mappingTable.set(androidId, {
      androidId,
      harmonyPath,
      type,
      name
    });
  }

  /**
   * 批量注册资源映射
   */
  static registerMappings(mappings: ResourceMapping[]): void {
    mappings.forEach(m => this.mappingTable.set(m.androidId, m));
  }

  /**
   * 获取资源映射
   * @param androidId Android资源ID
   * @returns 资源映射项或undefined
   */
  static getMapping(androidId: number): ResourceMapping | undefined {
    return this.mappingTable.get(androidId);
  }

  /**
   * 获取HarmonyOS资源路径
   * @param androidId Android资源ID
   * @returns HarmonyOS资源路径
   */
  static getHarmonyPath(androidId: number): string | null {
    const mapping = this.mappingTable.get(androidId);
    return mapping?.harmonyPath || null;
  }

  /**
   * 获取字符串资源
   * 对应Android: getString(R.string.xxx)
   * @param resId Android字符串资源ID
   */
  static async getString(resId: number): Promise<string> {
    const mapping = this.mappingTable.get(resId);
    if (mapping && mapping.type === 'string') {
      return ContextBridge.getString(mapping.harmonyPath);
    }
    console.warn(`String resource not found for ID: ${resId}`);
    return '';
  }

  /**
   * 获取颜色资源
   * 对应Android: getColor(R.color.xxx)
   * @param resId Android颜色资源ID
   */
  static async getColor(resId: number): Promise<string> {
    const mapping = this.mappingTable.get(resId);
    if (mapping && mapping.type === 'color') {
      return ContextBridge.getColor(mapping.harmonyPath);
    }
    console.warn(`Color resource not found for ID: ${resId}`);
    return '#000000';
  }

  /**
   * 获取尺寸资源
   * 对应Android: getDimension(R.dimen.xxx)
   * @param resId Android尺寸资源ID
   */
  static async getDimension(resId: number): Promise<number> {
    const mapping = this.mappingTable.get(resId);
    if (mapping && mapping.type === 'dimen') {
      // 返回数值，可能需要单位转换
      const value = await ContextBridge.getNumber(mapping.harmonyPath);
      return value;
    }
    console.warn(`Dimension resource not found for ID: ${resId}`);
    return 0;
  }

  /**
   * 获取布尔值资源
   * 对应Android: getBoolean(R.bool.xxx)
   * @param resId Android布尔资源ID
   */
  static async getBoolean(resId: number): Promise<boolean> {
    const mapping = this.mappingTable.get(resId);
    if (mapping && mapping.type === 'bool') {
      return ContextBridge.getBoolean(mapping.harmonyPath);
    }
    console.warn(`Boolean resource not found for ID: ${resId}`);
    return false;
  }

  /**
   * 获取整数资源
   * 对应Android: getInteger(R.integer.xxx)
   * @param resId Android整数资源ID
   */
  static async getInteger(resId: number): Promise<number> {
    const mapping = this.mappingTable.get(resId);
    if (mapping && mapping.type === 'integer') {
      return ContextBridge.getNumber(mapping.harmonyPath);
    }
    console.warn(`Integer resource not found for ID: ${resId}`);
    return 0;
  }

  /**
   * 获取资源名称
   * @param resId Android资源ID
   */
  static getResourceName(resId: number): string | null {
    const mapping = this.mappingTable.get(resId);
    return mapping?.name || null;
  }

  /**
   * 获取资源类型
   * @param resId Android资源ID
   */
  static getResourceType(resId: number): ResourceType | null {
    const mapping = this.mappingTable.get(resId);
    return mapping?.type || null;
  }

  /**
   * 检查资源是否存在
   * @param resId Android资源ID
   */
  static hasResource(resId: number): boolean {
    return this.mappingTable.has(resId);
  }

  /**
   * 获取所有映射
   */
  static getAllMappings(): ResourceMapping[] {
    return Array.from(this.mappingTable.values());
  }

  /**
   * 清除所有映射
   */
  static clear(): void {
    this.mappingTable.clear();
  }

  /**
   * 导出映射表为JSON
   */
  static exportToJSON(): string {
    const mappings = this.getAllMappings();
    return JSON.stringify(mappings, null, 2);
  }

  /**
   * 从JSON导入映射表
   */
  static importFromJSON(json: string): void {
    const mappings: ResourceMapping[] = JSON.parse(json);
    this.registerMappings(mappings);
  }
}

/**
 * R类资源引用（模拟Android R类）
 * 示例用法：
 * R.string.app_name  ->  返回对应的HarmonyOS资源路径
 */
export class R {
  // 字符串资源
  static string = {
    // 由编译时工具生成
    // app_name: 'app.string.app_name',
  };

  // 颜色资源
  static color = {
    // 由编译时工具生成
    // primary: 'app.color.primary',
  };

  // 尺寸资源
  static dimen = {
    // 由编译时工具生成
    // activity_margin: 'app.float.activity_margin',
  };

  // ID资源
  static id = {
    // 由编译时工具生成
    // button_submit: 1001,
  };

  /**
   * 初始化R类
   * 在应用启动时调用，加载资源映射
   */
  static init(resourceMappings: Record<string, Record<string, string | number>>): void {
    this.string = resourceMappings.string || {};
    this.color = resourceMappings.color || {};
    this.dimen = resourceMappings.dimen || {};
    this.id = resourceMappings.id || {};
  }
}

export default ResourceMapper;
