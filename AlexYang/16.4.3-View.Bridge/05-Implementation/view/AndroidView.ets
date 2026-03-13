/**
 * Android View常量，匹配android.view.View
 */
export class ViewConstants {
  // Visibility constants
  static readonly VISIBLE = 0;
  static readonly INVISIBLE = 4;
  static readonly GONE = 8;
}

import { AppStorage } from '@ohos.app.ability.common';
import { Padding, Margin, Gravity, LayoutParams } from './LayoutParams';

// View代理基类，供Android代码调用
export class ViewProxy {
  protected id: number;
  private clickListener: (() => void) | null = null;
  private touchListener: ((eventType: number) => boolean) | null = null;

  constructor(id: number) {
    this.id = id;
  }

  // ---- Visibility ----
  setVisibility(visibility: number): void {
    AppStorage.SetOrCreate<number>(`View_${this.id}_visibility`, visibility);
  }

  getVisibility(): number {
    return AppStorage.Get<number>(`View_${this.id}_visibility`) || ViewConstants.VISIBLE;
  }

  // ---- Background ----
  setBackgroundColor(color: number): void {
    AppStorage.SetOrCreate<number>(`View_${this.id}_backgroundColor`, color);
  }

  getBackgroundColor(): number {
    return AppStorage.Get<number>(`View_${this.id}_backgroundColor`) || 0;
  }

  // ---- Enabled ----
  setEnabled(enabled: boolean): void {
    AppStorage.SetOrCreate<boolean>(`View_${this.id}_enabled`, enabled);
  }

  isEnabled(): boolean {
    return AppStorage.Get<boolean>(`View_${this.id}_enabled`) || true;
  }

  // ---- Padding ----
  setPadding(left: number, top: number, right: number, bottom: number): void {
    AppStorage.SetOrCreate<Padding>(`View_${this.id}_padding`, new Padding(left, top, right, bottom));
  }

  setPaddingAll(padding: number): void {
    AppStorage.SetOrCreate<Padding>(`View_${this.id}_padding`, Padding.all(padding));
  }

  getPadding(): Padding {
    return AppStorage.Get<Padding>(`View_${this.id}_padding`) || new Padding();
  }

  // ---- Margin ----
  setMargin(left: number, top: number, right: number, bottom: number): void {
    AppStorage.SetOrCreate<Margin>(`View_${this.id}_margin`, new Margin(left, top, right, bottom));
  }

  setMarginAll(margin: number): void {
    AppStorage.SetOrCreate<Margin>(`View_${this.id}_margin`, Margin.all(margin));
  }

  getMargin(): Margin {
    return AppStorage.Get<Margin>(`View_${this.id}_margin`) || new Margin();
  }

  // ---- Gravity ----
  setGravity(gravity: number): void {
    AppStorage.SetOrCreate<number>(`View_${this.id}_gravity`, gravity);
  }

  getGravity(): number {
    return AppStorage.Get<number>(`View_${this.id}_gravity`) || (Gravity.TOP | Gravity.START);
  }

  // ---- LayoutParams ----
  setLayoutParams(params: LayoutParams): void {
    AppStorage.SetOrCreate<LayoutParams>(`View_${this.id}_layoutParams`, params);
  }

  getLayoutParams(): LayoutParams {
    return AppStorage.Get<LayoutParams>(`View_${this.id}_layoutParams`) || new LayoutParams();
  }

  setWidth(width: number): void {
    const params = this.getLayoutParams();
    params.width = width;
    this.setLayoutParams(params);
  }

  setHeight(height: number): void {
    const params = this.getLayoutParams();
    params.height = height;
    this.setLayoutParams(params);
  }

  getWidth(): number {
    return this.getLayoutParams().width;
  }

  getHeight(): number {
    return this.getLayoutParams().height;
  }

  // ---- Alpha (透明度) ----
  setAlpha(alpha: number): void {
    // Alpha值范围 0.0 - 1.0
    AppStorage.SetOrCreate<number>(`View_${this.id}_alpha`, Math.max(0, Math.min(1, alpha)));
  }

  getAlpha(): number {
    return AppStorage.Get<number>(`View_${this.id}_alpha`) || 1.0;
  }

  // ---- Clickable ----
  setClickable(clickable: boolean): void {
    AppStorage.SetOrCreate<boolean>(`View_${this.id}_clickable`, clickable);
  }

  isClickable(): boolean {
    return AppStorage.Get<boolean>(`View_${this.id}_clickable`) || true;
  }

  // ---- Listeners ----
  setOnClickListener(listener: () => void): void {
    this.clickListener = listener;
  }

  setOnTouchListener(listener: (eventType: number) => boolean): void {
    this.touchListener = listener;
  }

  // 供ArkUI组件调用
  dispatchClick(): void {
    if (this.clickListener && this.isEnabled()) {
      this.clickListener();
    }
  }

  dispatchTouch(eventType: number): boolean {
    if (this.touchListener && this.isEnabled()) {
      return this.touchListener(eventType);
    }
    return false;
  }

  // ---- Invalidation ----
  invalidate(): void {
    // No-op in ArkUI
  }

  // ---- ID ----
  getId(): number {
    return this.id;
  }
}
