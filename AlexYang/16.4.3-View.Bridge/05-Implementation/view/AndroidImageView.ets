/**
 * AndroidImageView - 模拟Android ImageView的ArkUI组件
 * 基于ArkUI Image组件，支持图片显示和缩放
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { AppStorage } from '@ohos.app.ability.common';
import { ViewProxy, ViewConstants } from './AndroidView';
import { Padding, Margin } from './LayoutParams';

/**
 * ScaleType constants matching Android ImageView.ScaleType
 */
export class ScaleType {
  /** Scale using the image matrix when drawing. */
  static readonly MATRIX: number = 0;

  /** Scale uniformly (maintain aspect ratio) so that one dimension matches the view. */
  static readonly FIT_XY: number = 1;

  /** Compute a scale that will maintain the original aspect ratio. */
  static readonly FIT_START: number = 2;

  /** Compute a scale that will maintain the original aspect ratio and center. */
  static readonly FIT_CENTER: number = 3;

  /** Compute a scale that will maintain the original aspect ratio and align to end. */
  static readonly FIT_END: number = 4;

  /** Center the image in the view without scaling. */
  static readonly CENTER: number = 5;

  /** Scale the image uniformly (maintain aspect ratio) so both dimensions equal or exceed the view. */
  static readonly CENTER_CROP: number = 6;

  /** Scale the image uniformly (maintain aspect ratio) so both dimensions fit within the view. */
  static readonly CENTER_INSIDE: number = 7;
}

@Component
export struct AndroidImageView {
  @Prop id: number;
  @Prop src: Resource | string = '';
  @Prop scaleType: number = ScaleType.FIT_CENTER;

  // Image specific properties
  @StorageLink(`ImageView_${this.id}_src`) imageSrc: Resource | string = '';
  @StorageLink(`ImageView_${this.id}_scaleType`) imageScaleType: number = ScaleType.FIT_CENTER;
  @StorageLink(`ImageView_${this.id}_alpha`) imageAlpha: number = 255;
  @StorageLink(`ImageView_${this.id}_colorFilter`) colorFilter: number = 0;

  // View base properties
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;
  @StorageLink(`View_${this.id}_padding`) padding: Padding = new Padding();
  @StorageLink(`View_${this.id}_margin`) margin: new Margin();

  aboutToAppear() {
    const registry = ViewRegistry.getInstance();
    registry.getImageViewProxy(this.id);

    // Initialize storage values
    if (!AppStorage.Has(`ImageView_${this.id}_src`)) {
      AppStorage.SetOrCreate(`ImageView_${this.id}_src`, this.src);
    }
    if (!AppStorage.Has(`ImageView_${this.id}_scaleType`)) {
      AppStorage.SetOrCreate(`ImageView_${this.id}_scaleType`, this.scaleType);
    }
    if (!AppStorage.Has(`View_${this.id}_visibility`)) {
      AppStorage.SetOrCreate(`View_${this.id}_visibility`, this.visibility);
    }
    if (!AppStorage.Has(`View_${this.id}_backgroundColor`)) {
      AppStorage.SetOrCreate(`View_${this.id}_backgroundColor`, this.backgroundColor);
    }
    if (!AppStorage.Has(`View_${this.id}_enabled`)) {
      AppStorage.SetOrCreate(`View_${this.id}_enabled`, this.enabled);
    }
    if (!AppStorage.Has(`View_${this.id}_padding`)) {
      AppStorage.SetOrCreate(`View_${this.id}_padding`, this.padding);
    }
    if (!AppStorage.Has(`View_${this.id}_margin`)) {
      AppStorage.SetOrCreate(`View_${this.id}_margin`, this.margin);
    }
  }

  build() {
    Image(this.imageSrc || this.src)
      .objectFit(this.getObjectFit())
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.backgroundColor)
      .enabled(this.enabled)
      .opacity(this.imageAlpha / 255)
      .padding({
        left: this.padding.left,
        right: this.padding.right,
        top: this.padding.top,
        bottom: this.padding.bottom
      })
      .margin({
        left: this.margin.left,
        right: this.margin.right,
        top: this.margin.top,
        bottom: this.margin.bottom
      })
      .width('100%')
      .height('100%')
  }

  private getArkUIVisibility(): number {
    switch (this.visibility) {
      case ViewConstants.INVISIBLE:
        return 1;
      case ViewConstants.GONE:
        return 2;
      default:
        return 0;
    }
  }

  private getObjectFit(): ImageFit {
    const scale = this.imageScaleType || this.scaleType;
    switch (scale) {
      case ScaleType.FIT_XY:
        return ImageFit.Fill;
      case ScaleType.FIT_START:
        return ImageFit.TopStart;
      case ScaleType.FIT_CENTER:
        return ImageFit.Contain;
      case ScaleType.FIT_END:
        return ImageFit.BottomEnd;
      case ScaleType.CENTER:
        return ImageFit.None;
      case ScaleType.CENTER_CROP:
        return ImageFit.Cover;
      case ScaleType.CENTER_INSIDE:
        return ImageFit.ScaleDown;
      default:
        return ImageFit.Contain;
    }
  }
}

/**
 * ImageView proxy for Android code interaction
 */
export class ImageViewProxy extends ViewProxy {
  constructor(id: number) {
    super(id);
  }

  /**
   * Sets the image resource (drawable resource ID).
   * In the bridge, resource IDs need to be resolved to actual resources.
   */
  setImageResource(resId: number): void {
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_src_resId`, resId);
    // Resource lookup would be handled by adapter layer
  }

  /**
   * Sets the image from a URI string.
   */
  setImageURI(uri: string): void {
    AppStorage.SetOrCreate<string>(`ImageView_${this.id}_src`, uri);
  }

  /**
   * Sets the image drawable directly (using resource or pixelmap).
   */
  setImageDrawable(drawable: Resource | string): void {
    AppStorage.SetOrCreate<Resource | string>(`ImageView_${this.id}_src`, drawable);
  }

  /**
   * Sets the scale type for image display.
   */
  setScaleType(scaleType: number): void {
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_scaleType`, scaleType);
  }

  /**
   * Gets the current scale type.
   */
  getScaleType(): number {
    return AppStorage.Get<number>(`ImageView_${this.id}_scaleType`) || ScaleType.FIT_CENTER;
  }

  /**
   * Sets the image alpha (0-255).
   */
  setImageAlpha(alpha: number): void {
    const clampedAlpha = Math.max(0, Math.min(255, alpha));
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_alpha`, clampedAlpha);
  }

  /**
   * Gets the current image alpha.
   */
  getImageAlpha(): number {
    return AppStorage.Get<number>(`ImageView_${this.id}_alpha`) || 255;
  }

  /**
   * Sets a color filter for the image.
   */
  setColorFilter(color: number): void {
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_colorFilter`, color);
  }

  /**
   * Clears any color filter.
   */
  clearColorFilter(): void {
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_colorFilter`, 0);
  }

  /**
   * Gets the maximum width (compatibility method).
   */
  getMaxWidth(): number {
    return AppStorage.Get<number>(`ImageView_${this.id}_maxWidth`) || Integer.MAX_VALUE;
  }

  /**
   * Sets the maximum width.
   */
  setMaxWidth(maxWidth: number): void {
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_maxWidth`, maxWidth);
  }

  /**
   * Gets the maximum height (compatibility method).
   */
  getMaxHeight(): number {
    return AppStorage.Get<number>(`ImageView_${this.id}_maxHeight`) || Integer.MAX_VALUE;
  }

  /**
   * Sets the maximum height.
   */
  setMaxHeight(maxHeight: number): void {
    AppStorage.SetOrCreate<number>(`ImageView_${this.id}_maxHeight`, maxHeight);
  }

  /**
   * Returns true if this view crops to padding.
   */
  getCropToPadding(): boolean {
    return AppStorage.Get<boolean>(`ImageView_${this.id}_cropToPadding`) || false;
  }

  /**
   * Sets whether this view crops to padding.
   */
  setCropToPadding(cropToPadding: boolean): void {
    AppStorage.SetOrCreate<boolean>(`ImageView_${this.id}_cropToPadding`, cropToPadding);
  }
}

/**
 * Integer constants for compatibility
 */
class Integer {
  static readonly MAX_VALUE: number = 2147483647;
}
