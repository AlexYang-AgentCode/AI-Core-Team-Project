import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Integration', '%{public}s', '16.2 Integration Test - onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'Integration', '%{public}s', 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'Integration', '%{public}s', 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'Integration', 'Failed: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'Integration', 'Content loaded successfully');
    });
  }

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
}
