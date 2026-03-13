// coding.ts - ButtonAdapter Implementation
export class ButtonAdapter {
  private text: string = '';
  private width: string | number = 'wrap_content';
  private height: string | number = 'wrap_content';
  private clickListener?: () => void;
  private enabled: boolean = true;
  
  constructor(text: string = '') {
    this.text = text;
  }
  
  setText(text: string): void { this.text = text; }
  getText(): string { return this.text; }
  setWidth(width: string | number): void { this.width = width; }
  setHeight(height: string | number): void { this.height = height; }
  setOnClickListener(listener: () => void): void { this.clickListener = listener; }
  performClick(): void { if (this.clickListener && this.enabled) this.clickListener(); }
  setEnabled(enabled: boolean): void { this.enabled = enabled; }
  isEnabled(): boolean { return this.enabled; }
  toHarmonyConfig(): any { return { text: this.text, width: this.width, height: this.height, enabled: this.enabled }; }
}
export default ButtonAdapter;
