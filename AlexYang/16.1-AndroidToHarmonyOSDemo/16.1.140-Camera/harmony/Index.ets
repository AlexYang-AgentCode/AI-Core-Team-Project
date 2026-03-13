// HarmonyOS ArkTS equivalent of Android Camera2 demo
// Android: CameraManager + CameraDevice + CaptureSession → HarmonyOS: @ohos.multimedia.camera
// This maps the Camera2 video preview + capture flow to HarmonyOS camera APIs

import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

@Entry
@Component
struct CameraPage {
  @State hasPermission: boolean = false;
  @State isRecording: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  @State statusText: string = 'Initializing camera...';

  private context: common.UIAbilityContext | undefined = undefined;
  private surfaceId: string = '';
  private cameraManager: camera.CameraManager | undefined = undefined;
  private cameraInput: camera.CameraInput | undefined = undefined;
  private previewOutput: camera.PreviewOutput | undefined = undefined;
  private photoOutput: camera.PhotoOutput | undefined = undefined;
  private session: camera.PhotoSession | undefined = undefined;

  // Android: TextureView → HarmonyOS: XComponent for camera preview surface
  private xComponentController: XComponentController = new XComponentController();

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.requestCameraPermission();
  }

  aboutToDisappear(): void {
    this.releaseCamera();
  }

  // Android: PermissionsFragment checks CAMERA + RECORD_AUDIO
  // HarmonyOS: requestPermissionsFromUser
  private async requestCameraPermission(): Promise<void> {
    const permissions: Permissions[] = ['ohos.permission.CAMERA'];
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context!, permissions);
      if (result.authResults[0] === 0) {
        this.hasPermission = true;
        // Camera init happens after XComponent surface is ready
      } else {
        this.statusText = 'Camera permission denied';
      }
    } catch (error) {
      this.statusText = `Permission error: ${JSON.stringify(error)}`;
    }
  }

  // Android: CameraManager.getCameraIdList() → HarmonyOS: getSupportedCameras()
  // Android: openCamera(cameraId, StateCallback) → HarmonyOS: createCameraInput + open
  // Android: createCaptureSession(surfaces, StateCallback) → HarmonyOS: createSession
  private async initializeCamera(): Promise<void> {
    if (!this.surfaceId) {
      this.statusText = 'Surface not ready';
      return;
    }

    try {
      // Android: getSystemService(CAMERA_SERVICE) as CameraManager
      this.cameraManager = camera.getCameraManager(this.context!);

      // Android: cameraManager.getCameraIdList()
      const cameras: camera.CameraDevice[] = this.cameraManager.getSupportedCameras();
      if (cameras.length === 0) {
        this.statusText = 'No cameras available';
        return;
      }

      // Find camera matching desired position
      // Android: CameraCharacteristics.LENS_FACING → HarmonyOS: CameraPosition
      let targetCamera: camera.CameraDevice = cameras[0];
      for (const cam of cameras) {
        if (cam.cameraPosition === this.cameraPosition) {
          targetCamera = cam;
          break;
        }
      }

      // Get supported output profiles
      const outputCapability = this.cameraManager.getSupportedOutputCapability(targetCamera, camera.SceneMode.NORMAL_PHOTO);
      if (!outputCapability) {
        this.statusText = 'No output capability';
        return;
      }

      const previewProfiles = outputCapability.previewProfiles;
      const photoProfiles = outputCapability.photoProfiles;

      // Android: openCamera(cameraId, callback, handler)
      // HarmonyOS: createCameraInput(camera) + open()
      this.cameraInput = this.cameraManager.createCameraInput(targetCamera);
      await this.cameraInput.open();

      // Android: TextureView/SurfaceView → HarmonyOS: XComponent previewOutput
      this.previewOutput = this.cameraManager.createPreviewOutput(previewProfiles[0], this.surfaceId);

      // Android: ImageReader for capture → HarmonyOS: photoOutput
      this.photoOutput = this.cameraManager.createPhotoOutput(photoProfiles[0]);

      // Android: createCaptureSession(targets, stateCallback, handler)
      // HarmonyOS: createSession(SceneMode) + addInput/addOutput + commitConfig
      this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;

      this.session.beginConfig();
      this.session.addInput(this.cameraInput);
      this.session.addOutput(this.previewOutput);
      this.session.addOutput(this.photoOutput);
      await this.session.commitConfig();

      // Android: session.setRepeatingRequest(previewRequest, null, handler)
      // HarmonyOS: session.start() starts the preview
      await this.session.start();
      this.statusText = 'Camera ready';

    } catch (error) {
      this.statusText = `Camera init error: ${(error as BusinessError).message}`;
      console.error(`Camera init failed: ${JSON.stringify(error)}`);
    }
  }

  // Android: captureBuilder.addTarget(imageReaderSurface); session.capture(captureBuilder.build())
  // HarmonyOS: photoOutput.capture()
  private async capturePhoto(): Promise<void> {
    if (!this.photoOutput) {
      this.statusText = 'Camera not ready';
      return;
    }

    try {
      const captureSettings: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
        rotation: camera.ImageRotation.ROTATION_0
      };
      await this.photoOutput.capture(captureSettings);
      this.statusText = 'Photo captured!';
    } catch (error) {
      this.statusText = `Capture error: ${(error as BusinessError).message}`;
    }
  }

  // Android: camera.close() + session.close()
  // HarmonyOS: session.stop() + release inputs/outputs
  private async releaseCamera(): Promise<void> {
    try {
      if (this.session) {
        await this.session.stop();
        this.session.release();
        this.session = undefined;
      }
      if (this.cameraInput) {
        await this.cameraInput.close();
        this.cameraInput = undefined;
      }
      if (this.previewOutput) {
        this.previewOutput.release();
        this.previewOutput = undefined;
      }
      if (this.photoOutput) {
        this.photoOutput.release();
        this.photoOutput = undefined;
      }
    } catch (error) {
      console.error(`Release camera error: ${JSON.stringify(error)}`);
    }
  }

  // Android: Switch between LENS_FACING_BACK / LENS_FACING_FRONT
  // HarmonyOS: Recreate session with different CameraPosition
  private async switchCamera(): Promise<void> {
    await this.releaseCamera();
    this.cameraPosition = (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK)
      ? camera.CameraPosition.CAMERA_POSITION_FRONT
      : camera.CameraPosition.CAMERA_POSITION_BACK;
    this.statusText = 'Switching camera...';
    await this.initializeCamera();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.hasPermission) {
        // Android: AutoFitSurfaceView → HarmonyOS: XComponent
        XComponent({
          id: 'cameraPreview',
          type: XComponentType.SURFACE,
          controller: this.xComponentController
        })
          .onLoad(() => {
            this.surfaceId = this.xComponentController.getXComponentSurfaceId();
            this.initializeCamera();
          })
          .width('100%')
          .height('100%')
      } else {
        Column() {
          Text(this.statusText)
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.Black)
      }

      // Overlay controls
      Column() {
        Text(this.statusText)
          .fontSize(14)
          .fontColor(Color.White)
          .margin({ bottom: 16 })

        Row() {
          // Switch camera button
          Button('Switch')
            .onClick(() => this.switchCamera())
            .margin({ right: 24 })
            .backgroundColor('#80000000')
            .fontColor(Color.White)

          // Android: capture_button ImageButton → HarmonyOS: Button
          Button('Capture')
            .width(80)
            .height(80)
            .borderRadius(40)
            .backgroundColor(Color.Red)
            .fontColor(Color.White)
            .onClick(() => this.capturePhoto())
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding({ bottom: 48 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
