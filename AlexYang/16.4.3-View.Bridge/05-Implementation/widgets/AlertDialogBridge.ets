/**
 * AlertDialogBridge.ets
 *
 * Bridge for Android's androidx.appcompat.app.AlertDialog → ArkUI promptAction.showDialog.
 *
 * Android AlertDialog is typically used with a Builder pattern:
 *   new AlertDialog.Builder(context)
 *     .setTitle("Title")
 *     .setMessage("Message")
 *     .setPositiveButton("Yes", listener)
 *     .setNegativeButton("No", listener)
 *     .show();
 *
 * In ArkUI, we use promptAction.showDialog with a buttons array.
 */

import promptAction from '@ohos.promptAction';

/**
 * Button configuration for dialog.
 */
interface DialogButton {
  text: string;
  color?: string;
  action?: () => void;
}

/**
 * AlertDialogBuilder - Builder class for creating alert dialogs.
 * Mirrors Android's AlertDialog.Builder API.
 */
export class AlertDialogBuilder {
  private title: string = '';
  private message: string = '';
  private positiveButton?: DialogButton;
  private negativeButton?: DialogButton;
  private neutralButton?: DialogButton;

  /**
   * Set the title displayed in the dialog.
   * @param title - The title text
   * @returns This builder for method chaining
   */
  setTitle(title: string): AlertDialogBuilder {
    this.title = title;
    return this;
  }

  /**
   * Set the message displayed in the dialog.
   * @param message - The message text
   * @returns This builder for method chaining
   */
  setMessage(message: string): AlertDialogBuilder {
    this.message = message;
    return this;
  }

  /**
   * Set a listener to be invoked when the positive button is pressed.
   * @param text - The text to display on the positive button
   * @param callback - The callback to invoke when button is pressed (optional)
   * @returns This builder for method chaining
   */
  setPositiveButton(text: string, callback?: () => void): AlertDialogBuilder {
    this.positiveButton = {
      text: text,
      color: '#007DFF', // Blue color for positive action
      action: callback
    };
    return this;
  }

  /**
   * Set a listener to be invoked when the negative button is pressed.
   * @param text - The text to display on the negative button
   * @param callback - The callback to invoke when button is pressed (optional)
   * @returns This builder for method chaining
   */
  setNegativeButton(text: string, callback?: () => void): AlertDialogBuilder {
    this.negativeButton = {
      text: text,
      color: '#666666', // Gray color for negative action
      action: callback
    };
    return this;
  }

  /**
   * Set a listener to be invoked when the neutral button is pressed.
   * @param text - The text to display on the neutral button
   * @param callback - The callback to invoke when button is pressed (optional)
   * @returns This builder for method chaining
   */
  setNeutralButton(text: string, callback?: () => void): AlertDialogBuilder {
    this.neutralButton = {
      text: text,
      color: '#999999', // Light gray for neutral action
      action: callback
    };
    return this;
  }

  /**
   * Creates an AlertDialog with the arguments supplied to this builder.
   * Displays the dialog immediately.
   */
  show(): void {
    const buttons: Array<{ text: string; color?: string; action: () => void }> = [];

    // Add positive button if set
    if (this.positiveButton) {
      buttons.push({
        text: this.positiveButton.text,
        color: this.positiveButton.color,
        action: this.positiveButton.action || (() => {})
      });
    }

    // Add negative button if set
    if (this.negativeButton) {
      buttons.push({
        text: this.negativeButton.text,
        color: this.negativeButton.color,
        action: this.negativeButton.action || (() => {})
      });
    }

    // Add neutral button if set
    if (this.neutralButton) {
      buttons.push({
        text: this.neutralButton.text,
        color: this.neutralButton.color,
        action: this.neutralButton.action || (() => {})
      });
    }

    // Show the dialog
    promptAction.showDialog({
      title: this.title,
      message: this.message,
      buttons: buttons.length > 0 ? buttons : undefined,
      autoCancel: true
    });
  }
}

/**
 * AlertDialog bridge class matching Android's AlertDialog API.
 *
 * Usage:
 *   AlertDialogBridge.Builder()
 *     .setTitle("Confirm")
 *     .setMessage("Are you sure?")
 *     .setPositiveButton("Yes", () => { console.log("Yes clicked"); })
 *     .setNegativeButton("No", null)
 *     .show();
 */
export class AlertDialogBridge {
  /**
   * Returns a builder for creating alert dialogs.
   * @param context - Android Context (ignored in ArkUI, pass null or undefined)
   * @returns AlertDialogBuilder instance
   */
  static Builder(context?: Object): AlertDialogBuilder {
    return new AlertDialogBuilder();
  }
}

/**
 * Re-export for convenience - allows import { AlertDialog } from './AlertDialogBridge'.
 */
export const AlertDialog = AlertDialogBridge;
