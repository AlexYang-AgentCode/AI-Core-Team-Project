/**
 * ViewRegistry - Android View ID到代理对象的映射
 * 提供findViewById功能，返回Android View代理对象
 */

import { TextViewProxy } from '../view/AndroidTextView';
import { ButtonProxy } from '../view/AndroidButton';
import { LinearLayoutProxy } from '../layout/AndroidLinearLayout';
import { EditTextProxy } from '../view/AndroidEditText';
import { TextClockProxy } from '../view/AndroidTextClock';
import { RelativeLayoutProxy } from '../layout/AndroidRelativeLayout';
import { FrameLayoutProxy } from '../layout/AndroidFrameLayout';

export class ViewRegistry {
  private static instance: ViewRegistry | null = null;
  private textViewProxies: Map<number, TextViewProxy> = new Map();
  private buttonProxies: Map<number, ButtonProxy> = new Map();
  private linearLayoutProxies: Map<number, LinearLayoutProxy> = new Map();
  private editTextProxies: Map<number, EditTextProxy> = new Map();
  private textClockProxies: Map<number, TextClockProxy> = new Map();
  private relativeLayoutProxies: Map<number, RelativeLayoutProxy> = new Map();
  private frameLayoutProxies: Map<number, FrameLayoutProxy> = new Map();

  private constructor() {}

  public static getInstance(): ViewRegistry {
    if (!ViewRegistry.instance) {
      ViewRegistry.instance = new ViewRegistry();
    }
    return ViewRegistry.instance;
  }

  /**
   * 模拟Android的findViewById
   * @param id Android R.id.xxx
   * @param viewType 视图类型，如'TextView', 'Button'
   */
  public findViewById<T>(id: number, viewType: string): T | null {
    switch (viewType) {
      case 'TextView':
        return this.getTextViewProxy(id) as unknown as T;
      case 'Button':
        return this.getButtonProxy(id) as unknown as T;
      case 'LinearLayout':
        return this.getLinearLayoutProxy(id) as unknown as T;
      case 'EditText':
        return this.getEditTextProxy(id) as unknown as T;
      case 'TextClock':
        return this.getTextClockProxy(id) as unknown as T;
      case 'RelativeLayout':
        return this.getRelativeLayoutProxy(id) as unknown as T;
      case 'FrameLayout':
        return this.getFrameLayoutProxy(id) as unknown as T;
      default:
        console.error(`Unsupported view type: ${viewType}`);
        return null;
    }
  }

  /**
   * 注册TextView代理（供组件使用）
   */
  public registerTextViewProxy(id: number, proxy: TextViewProxy): void {
    this.textViewProxies.set(id, proxy);
  }

  /**
   * 注册Button代理（供组件使用）
   */
  public registerButtonProxy(id: number, proxy: ButtonProxy): void {
    this.buttonProxies.set(id, proxy);
  }

  /**
   * 获取或创建LinearLayout代理
   */
  public getLinearLayoutProxy(id: number): LinearLayoutProxy {
    let proxy = this.linearLayoutProxies.get(id);
    if (!proxy) {
      proxy = new LinearLayoutProxy(id);
      this.linearLayoutProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 注册LinearLayout代理（供组件使用）
   */
  public registerLinearLayoutProxy(id: number, proxy: LinearLayoutProxy): void {
    this.linearLayoutProxies.set(id, proxy);
  }

  /**
   * 获取或创建EditText代理
   */
  public getEditTextProxy(id: number): EditTextProxy {
    let proxy = this.editTextProxies.get(id);
    if (!proxy) {
      proxy = new EditTextProxy(id);
      this.editTextProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 注册EditText代理（供组件使用）
   */
  public registerEditTextProxy(id: number, proxy: EditTextProxy): void {
    this.editTextProxies.set(id, proxy);
  }

  /**
   * 获取或创建TextClock代理
   */
  public getTextClockProxy(id: number): TextClockProxy {
    let proxy = this.textClockProxies.get(id);
    if (!proxy) {
      proxy = new TextClockProxy(id);
      this.textClockProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 注册TextClock代理（供组件使用）
   */
  public registerTextClockProxy(id: number, proxy: TextClockProxy): void {
    this.textClockProxies.set(id, proxy);
  }

  /**
   * 获取或创建TextView代理
   */
  public getTextViewProxy(id: number): TextViewProxy {
    let proxy = this.textViewProxies.get(id);
    if (!proxy) {
      proxy = new TextViewProxy(id);
      this.textViewProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 获取或创建Button代理
   */
  public getButtonProxy(id: number): ButtonProxy {
    let proxy = this.buttonProxies.get(id);
    if (!proxy) {
      proxy = new ButtonProxy(id);
      this.buttonProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 获取或创建RelativeLayout代理
   */
  public getRelativeLayoutProxy(id: number): RelativeLayoutProxy {
    let proxy = this.relativeLayoutProxies.get(id);
    if (!proxy) {
      proxy = new RelativeLayoutProxy(id);
      this.relativeLayoutProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 注册RelativeLayout代理（供组件使用）
   */
  public registerRelativeLayoutProxy(id: number, proxy: RelativeLayoutProxy): void {
    this.relativeLayoutProxies.set(id, proxy);
  }

  /**
   * 获取或创建FrameLayout代理
   */
  public getFrameLayoutProxy(id: number): FrameLayoutProxy {
    let proxy = this.frameLayoutProxies.get(id);
    if (!proxy) {
      proxy = new FrameLayoutProxy(id);
      this.frameLayoutProxies.set(id, proxy);
    }
    return proxy;
  }

  /**
   * 注册FrameLayout代理（供组件使用）
   */
  public registerFrameLayoutProxy(id: number, proxy: FrameLayoutProxy): void {
    this.frameLayoutProxies.set(id, proxy);
  }

  /**
   * 清除所有注册的View
   */
  public clear(): void {
    this.textViewProxies.clear();
    this.buttonProxies.clear();
    this.linearLayoutProxies.clear();
    this.editTextProxies.clear();
    this.textClockProxies.clear();
    this.relativeLayoutProxies.clear();
    this.frameLayoutProxies.clear();
  }
}