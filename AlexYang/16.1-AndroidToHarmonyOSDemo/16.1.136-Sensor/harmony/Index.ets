// HarmonyOS ArkTS equivalent of Android Sensor (Accelerometer) demo
// Android: SensorManager + SensorEventListener → HarmonyOS: @ohos.sensor

import { sensor } from '@kit.SensorServiceKit';

@Entry
@Component
struct SensorPage {
  @State sensorX: number = 0;
  @State sensorY: number = 0;
  @State sensorZ: number = 0;

  // Accelerometer callback — mirrors SensorEventListener.onSensorChanged
  private accelCallback = (data: sensor.AccelerometerResponse): void => {
    // Android: event.values[0/1/2] → HarmonyOS: data.x, data.y, data.z
    this.sensorX = data.x;
    this.sensorY = data.y;
    this.sensorZ = data.z;
  };

  // Android: onResume → registerListener
  // HarmonyOS: onPageShow → sensor.on
  onPageShow(): void {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, this.accelCallback, {
        interval: 200000000 // 200ms in nanoseconds, ~SENSOR_DELAY_NORMAL
      });
    } catch (error) {
      console.error(`Failed to register accelerometer: ${JSON.stringify(error)}`);
    }
  }

  // Android: onStop → unregisterListener
  // HarmonyOS: onPageHide → sensor.off
  onPageHide(): void {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    } catch (error) {
      console.error(`Failed to unregister accelerometer: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Column() {
      // Mirrors Android LinearLayout with 3 TextViews centered vertically
      Text(`X : ${Math.floor(this.sensorX)}`)
        .fontSize(30)
        .fontWeight(FontWeight.Normal)

      Text(`Y : ${Math.floor(this.sensorY)}`)
        .fontSize(30)
        .fontWeight(FontWeight.Normal)
        .margin({ top: 20 })

      Text(`Z : ${Math.floor(this.sensorZ)}`)
        .fontSize(30)
        .fontWeight(FontWeight.Normal)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
