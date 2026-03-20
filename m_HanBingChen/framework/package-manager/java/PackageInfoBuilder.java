/*
 * PackageInfoBuilder.java
 *
 * Converts OH BundleInfo (as JSON from JNI) to Android PackageInfo.
 *
 * Used by PackageManagerAdapter to return Android-compatible query results
 * when an app calls PackageManager.getPackageInfo() etc.
 *
 * Reverse conversion chain:
 *   BMS BundleInfo -> JSON (JNI) -> PackageInfoBuilder -> Android PackageInfo
 *
 * Key reverse mappings:
 *   - AbilityInfo.name (with "Ability" suffix) -> ActivityInfo.name (via IntentWantConverter)
 *   - ohos.permission.* -> android.permission.* (via PermissionMapper)
 *   - OH codePath/dataDir -> Android sourceDir/dataDir format
 */
package adapter.packagemanager;

import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.ProviderInfo;
import android.content.pm.ServiceInfo;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class PackageInfoBuilder {

    private static final String TAG = "OH_PkgInfoBuilder";

    /**
     * Convert OH BundleInfo JSON to Android PackageInfo.
     *
     * Expected JSON format (from BMS via JNI):
     * {
     *   "name": "com.example.app",
     *   "versionCode": 1,
     *   "versionName": "1.0",
     *   "uid": 10086,
     *   "maxSdkVersion": 33,
     *   "abilityInfos": [{"name":"MainActivityAbility","visible":true,...}],
     *   "extensionAbilityInfos": [{"name":"MyService","type":"SERVICE",...}],
     *   "reqPermissions": ["ohos.permission.INTERNET",...]
     * }
     */
    public static PackageInfo fromBundleInfo(String bundleInfoJson) {
        PackageInfo pi = new PackageInfo();

        if (bundleInfoJson == null || bundleInfoJson.isEmpty()) {
            Log.w(TAG, "Empty bundleInfoJson");
            return pi;
        }

        try {
            JSONObject json = new JSONObject(bundleInfoJson);
            return fromBundleInfoJson(json);
        } catch (JSONException e) {
            Log.e(TAG, "Failed to parse BundleInfo JSON", e);
            return pi;
        }
    }

    /**
     * Convert OH BundleInfo JSONObject to Android PackageInfo.
     */
    public static PackageInfo fromBundleInfoJson(JSONObject json) throws JSONException {
        PackageInfo pi = new PackageInfo();

        // Basic package info
        pi.packageName = json.getString("name");
        pi.versionCode = json.optInt("versionCode", 0);
        pi.versionName = json.optString("versionName", "");

        // ApplicationInfo
        pi.applicationInfo = buildApplicationInfo(json, pi.packageName);

        // AbilityInfos -> ActivityInfo[] (reverse Ability suffix)
        JSONArray abilities = json.optJSONArray("abilityInfos");
        if (abilities != null && abilities.length() > 0) {
            pi.activities = new ActivityInfo[abilities.length()];
            for (int i = 0; i < abilities.length(); i++) {
                pi.activities[i] = buildActivityInfo(
                    abilities.getJSONObject(i), pi.packageName);
            }
        }

        // ExtensionAbilityInfos -> ServiceInfo[] + ProviderInfo[]
        JSONArray extensions = json.optJSONArray("extensionAbilityInfos");
        if (extensions != null && extensions.length() > 0) {
            buildExtensionInfos(extensions, pi);
        }

        // Permission reverse mapping (ohos.permission.* -> android.permission.*)
        JSONArray perms = json.optJSONArray("reqPermissions");
        if (perms != null && perms.length() > 0) {
            pi.requestedPermissions = new String[perms.length()];
            for (int i = 0; i < perms.length(); i++) {
                pi.requestedPermissions[i] =
                    PermissionMapper.mapToAndroid(perms.getString(i));
            }
        }

        return pi;
    }

    private static ApplicationInfo buildApplicationInfo(JSONObject json, String packageName) {
        ApplicationInfo ai = new ApplicationInfo();
        ai.packageName = packageName;
        ai.sourceDir = "/data/app/android/" + packageName + "/base.apk";
        ai.dataDir = "/data/data/" + packageName;
        ai.nativeLibraryDir = "/data/app/android/" + packageName + "/lib/arm64-v8a";
        ai.uid = json.optInt("uid", -1);
        ai.targetSdkVersion = json.optInt("maxSdkVersion", 33);
        ai.enabled = true;

        // Application class name
        JSONObject appInfoJson = json.optJSONObject("applicationInfo");
        if (appInfoJson != null) {
            ai.className = appInfoJson.optString("name", null);
            ai.uid = appInfoJson.optInt("uid", ai.uid);
        }

        return ai;
    }

    private static ActivityInfo buildActivityInfo(JSONObject abilityJson,
                                                   String packageName) throws JSONException {
        ActivityInfo ai = new ActivityInfo();
        String abilityName = abilityJson.getString("name");

        // Reverse the Ability suffix to get Android class name
        ai.name = IntentWantConverter.abilityNameToClassName(packageName, abilityName);
        ai.packageName = packageName;
        ai.exported = abilityJson.optBoolean("visible", false);

        // Launch mode reverse mapping
        String launchMode = abilityJson.optString("launchMode", "STANDARD");
        if ("SINGLETON".equals(launchMode)) {
            ai.launchMode = ActivityInfo.LAUNCH_SINGLE_TASK;
        } else {
            ai.launchMode = ActivityInfo.LAUNCH_MULTIPLE;
        }

        // Orientation reverse mapping
        String orientation = abilityJson.optString("orientation", "UNSPECIFIED");
        switch (orientation) {
            case "LANDSCAPE":
                ai.screenOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
                break;
            case "PORTRAIT":
                ai.screenOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
                break;
            default:
                ai.screenOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
                break;
        }

        return ai;
    }

    private static void buildExtensionInfos(JSONArray extensions,
                                              PackageInfo pi) throws JSONException {
        int serviceCount = 0;
        int providerCount = 0;

        // Count types first
        for (int i = 0; i < extensions.length(); i++) {
            JSONObject ext = extensions.getJSONObject(i);
            String type = ext.optString("type", "");
            if ("SERVICE".equals(type)) {
                serviceCount++;
            } else if ("DATASHARE".equals(type)) {
                providerCount++;
            }
            // STATICSUBSCRIBER -> Android BroadcastReceiver (handled differently, not in PackageInfo arrays)
        }

        if (serviceCount > 0) {
            pi.services = new ServiceInfo[serviceCount];
            int idx = 0;
            for (int i = 0; i < extensions.length(); i++) {
                JSONObject ext = extensions.getJSONObject(i);
                if ("SERVICE".equals(ext.optString("type", ""))) {
                    ServiceInfo si = new ServiceInfo();
                    si.name = ext.getString("name");
                    si.packageName = pi.packageName;
                    si.exported = ext.optBoolean("visible", false);
                    pi.services[idx++] = si;
                }
            }
        }

        if (providerCount > 0) {
            pi.providers = new ProviderInfo[providerCount];
            int idx = 0;
            for (int i = 0; i < extensions.length(); i++) {
                JSONObject ext = extensions.getJSONObject(i);
                if ("DATASHARE".equals(ext.optString("type", ""))) {
                    ProviderInfo pri = new ProviderInfo();
                    pri.name = ext.getString("name");
                    pri.packageName = pi.packageName;
                    pri.exported = ext.optBoolean("visible", false);
                    String uri = ext.optString("uri", "");
                    if (uri.startsWith("datashare:///")) {
                        pri.authority = uri.substring("datashare:///".length());
                    }
                    pi.providers[idx++] = pri;
                }
            }
        }
    }
}
