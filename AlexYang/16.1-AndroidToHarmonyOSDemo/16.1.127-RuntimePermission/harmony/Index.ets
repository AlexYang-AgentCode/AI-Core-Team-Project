// HarmonyOS ArkTS equivalent of Android RuntimePermission demo
// Android: checkSelfPermission + requestPermissions + onRequestPermissionsResult
// HarmonyOS: abilityAccessCtrl + requestPermissionsFromUser

import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';

@Entry
@Component
struct RuntimePermissionPage {
  @State statusText: string = 'Permission status: unknown'

  private readonly CAMERA_PERMISSION: Permissions = 'ohos.permission.CAMERA'

  private async checkPermission(): Promise<boolean> {
    const context = getContext(this) as common.UIAbilityContext
    const atManager = abilityAccessCtrl.createAtManager()
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      )
      const tokenId = bundleInfo.appInfo.accessTokenId
      const result = atManager.checkAccessTokenSync(tokenId, this.CAMERA_PERMISSION)
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (err) {
      console.error('checkPermission failed: ' + JSON.stringify(err))
      return false
    }
  }

  private async requestCameraPermission(): Promise<void> {
    // First check if already granted
    const alreadyGranted = await this.checkPermission()
    if (alreadyGranted) {
      this.statusText = 'Camera permission already granted'
      return
    }

    // Request the permission
    const context = getContext(this) as common.UIAbilityContext
    const atManager = abilityAccessCtrl.createAtManager()
    try {
      const result = await atManager.requestPermissionsFromUser(context, [this.CAMERA_PERMISSION])

      if (result.authResults.length > 0 && result.authResults[0] === 0) {
        // PERMISSION_GRANTED = 0
        this.statusText = 'Camera permission granted'
        promptAction.showToast({
          message: 'Permission granted!',
          duration: 2000
        })
      } else {
        this.statusText = 'Camera permission denied'
      }
    } catch (err) {
      console.error('requestPermission failed: ' + JSON.stringify(err))
      this.statusText = 'Permission request failed'
    }
  }

  build() {
    Column() {
      Text(this.statusText)
        .fontSize(16)

      Button('Request Camera Permission')
        .margin({ top: 16 })
        .onClick(() => {
          this.requestCameraPermission()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }
}
