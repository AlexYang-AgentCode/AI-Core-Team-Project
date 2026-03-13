/**
 * EntryAbility - Test Entry Point
 * 
 * Demonstrates Activity Bridge lifecycle mapping
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LifecycleLogger } from '../test/LifecycleLogger';

const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private _lifecycleLogger: LifecycleLogger = new LifecycleLogger();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'HarmonyOS onCreate');
    this._lifecycleLogger.log('HarmonyOS.onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'HarmonyOS onDestroy');
    this._lifecycleLogger.log('HarmonyOS.onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'HarmonyOS onWindowStageCreate');
    this._lifecycleLogger.log('HarmonyOS.onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, TAG, 'Content loaded successfully');
      this._lifecycleLogger.log('ContentLoaded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, TAG, 'HarmonyOS onWindowStageDestroy');
    this._lifecycleLogger.log('HarmonyOS.onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, 'HarmonyOS onForeground');
    this._lifecycleLogger.log('HarmonyOS.onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, 'HarmonyOS onBackground');
    this._lifecycleLogger.log('HarmonyOS.onBackground');
  }
}
