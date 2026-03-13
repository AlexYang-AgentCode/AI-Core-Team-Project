// HarmonyOS ArkTS equivalent of Android Location demo
// Android: LocationManager + LocationListener → HarmonyOS: @ohos.geoLocationManager

import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

@Entry
@Component
struct LocationPage {
  @State locationText: string = 'Waiting for location...';
  private context: common.UIAbilityContext | undefined = undefined;

  // Android: LocationListener.onLocationChanged → HarmonyOS callback
  private locationCallback = (location: geoLocationManager.Location): void => {
    // Android: location.getLatitude()/getLongitude() → location.latitude/longitude
    this.locationText = `Lat: ${location.latitude.toFixed(5)}\nLng: ${location.longitude.toFixed(5)}`;
  };

  // Location request config — mirrors requestLocationUpdates(GPS_PROVIDER, 5000, 10, this)
  private locationRequest: geoLocationManager.LocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    scenario: geoLocationManager.LocationRequestScenario.UNSET,
    timeInterval: 5,     // seconds (Android: 5000ms minTime)
    distanceInterval: 10, // meters (Android: 10 minDistance)
    maxAccuracy: 0
  };

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.requestPermissionAndStart();
  }

  aboutToDisappear(): void {
    this.stopLocationUpdates();
  }

  // Android: checkSelfPermission + requestPermissions
  // HarmonyOS: abilityAccessCtrl.requestPermissionsFromUser
  private async requestPermissionAndStart(): Promise<void> {
    const permissions: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION'];
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context!, permissions);
      if (result.authResults[0] === 0) {
        this.startLocationUpdates();
      } else {
        this.locationText = 'Location permission denied';
      }
    } catch (error) {
      console.error(`Permission request failed: ${JSON.stringify(error)}`);
    }
  }

  // Android: locationManager.requestLocationUpdates(GPS_PROVIDER, 5000, 10, this)
  // HarmonyOS: geoLocationManager.on('locationChange', request, callback)
  private startLocationUpdates(): void {
    try {
      geoLocationManager.on('locationChange', this.locationRequest, this.locationCallback);
    } catch (error) {
      console.error(`Failed to start location updates: ${JSON.stringify(error)}`);
      this.locationText = 'Failed to start location';
    }
  }

  // Android: locationManager.removeUpdates(this)
  // HarmonyOS: geoLocationManager.off('locationChange')
  private stopLocationUpdates(): void {
    try {
      geoLocationManager.off('locationChange', this.locationCallback);
    } catch (error) {
      console.error(`Failed to stop location updates: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Column() {
      Text(this.locationText)
        .fontSize(18)
        .fontWeight(FontWeight.Normal)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
