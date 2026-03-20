/*
 * PackageManagerAdapter.java
 *
 * IPackageManager adapter that routes Android PackageManager queries to OH BMS.
 *
 * Installation path: AOSP PackageManager singleton replaced with this adapter
 * (similar to ActivityManagerAdapter pattern).
 *
 * Query flow:
 *   App -> PackageManager -> IPackageManager.Stub (this class) -> JNI -> OH BMS
 *        -> BundleInfo JSON -> PackageInfoBuilder -> Android PackageInfo -> App
 *
 * Tags:
 *   [BRIDGED] - Fully implemented, routes to BMS
 *   [STUB]    - Returns default/empty value (Phase 1)
 */
package adapter.packagemanager;

import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.IPackageManager;
import android.content.pm.PackageInfo;
import android.content.pm.ProviderInfo;
import android.content.pm.ResolveInfo;
import android.content.pm.ServiceInfo;
import android.os.RemoteException;
import android.util.Log;

import adapter.activity.IntentWantConverter;
import adapter.packagemanager.PackageInfoBuilder;
import adapter.packagemanager.PermissionMapper;

import java.util.ArrayList;
import java.util.List;

public class PackageManagerAdapter extends IPackageManager.Stub {

    private static final String TAG = "OH_PMAdapter";

    // ========================================================================
    // JNI native methods — each calls OH BMS via JNI
    // ========================================================================

    /**
     * Query BMS.GetBundleInfo(bundleName, flags).
     * Returns BundleInfo as JSON string.
     */
    private static native String nativeGetBundleInfo(String bundleName, int flags);

    /**
     * Query BMS.GetApplicationInfo(bundleName, flags).
     * Returns ApplicationInfo as JSON string.
     */
    private static native String nativeGetApplicationInfo(String bundleName, int flags);

    /**
     * Query BMS.GetBundleInfos(flags).
     * Returns JSON array of BundleInfo strings.
     */
    private static native String nativeGetAllBundleInfos(int flags);

    /**
     * Query BMS.QueryAbilityInfos(want, flags).
     * Returns JSON array of AbilityInfo.
     */
    private static native String nativeQueryAbilityInfos(String wantJson, int flags);

    /**
     * Query BMS.GetUidByBundleName(bundleName).
     * Returns UID, or -1 if not found.
     */
    private static native int nativeGetUidByBundleName(String bundleName);

    /**
     * Query BMS.CheckPermission(bundleName, permission).
     * Returns 0 for granted, -1 for denied.
     */
    private static native int nativeCheckPermission(String bundleName, String permission);

    // ========================================================================
    // Category 1: Package Info Queries
    // ========================================================================

    /**
     * [BRIDGED] getPackageInfo -> BMS.GetBundleInfo
     */
    @Override
    public PackageInfo getPackageInfo(String packageName, long flags, int userId) {
        logBridged("getPackageInfo", packageName);
        String json = nativeGetBundleInfo(packageName, (int) flags);
        if (json == null || json.isEmpty()) {
            Log.w(TAG, "getPackageInfo: not found: " + packageName);
            return null;
        }
        return PackageInfoBuilder.fromBundleInfo(json);
    }

    /**
     * [BRIDGED] getApplicationInfo -> BMS.GetApplicationInfo
     */
    @Override
    public ApplicationInfo getApplicationInfo(String packageName, long flags, int userId) {
        logBridged("getApplicationInfo", packageName);
        String json = nativeGetApplicationInfo(packageName, (int) flags);
        if (json == null || json.isEmpty()) {
            return null;
        }
        PackageInfo pi = PackageInfoBuilder.fromBundleInfo(json);
        return pi != null ? pi.applicationInfo : null;
    }

    /**
     * [BRIDGED] getInstalledPackages -> BMS.GetBundleInfos
     */
    @Override
    public List<PackageInfo> getInstalledPackages(long flags, int userId) {
        logBridged("getInstalledPackages", "flags=" + flags);
        String json = nativeGetAllBundleInfos((int) flags);
        List<PackageInfo> result = new ArrayList<>();
        if (json == null || json.isEmpty()) {
            return result;
        }

        try {
            org.json.JSONArray array = new org.json.JSONArray(json);
            for (int i = 0; i < array.length(); i++) {
                String bundleJson = array.getString(i);
                PackageInfo pi = PackageInfoBuilder.fromBundleInfo(bundleJson);
                if (pi != null) {
                    result.add(pi);
                }
            }
        } catch (org.json.JSONException e) {
            Log.e(TAG, "getInstalledPackages: JSON parse error", e);
        }

        return result;
    }

    // ========================================================================
    // Category 2: Component Queries
    // ========================================================================

    /**
     * [BRIDGED] getActivityInfo -> BMS.QueryAbilityInfo
     */
    @Override
    public ActivityInfo getActivityInfo(ComponentName component, long flags, int userId) {
        logBridged("getActivityInfo", component.flattenToShortString());
        // Convert ComponentName to Want-style query
        IntentWantConverter.WantParams want = new IntentWantConverter.WantParams();
        want.bundleName = component.getPackageName();
        want.abilityName = IntentWantConverter.abilityNameToClassName(component.getClassName());
        // Actually we need class->ability name conversion
        String abilityName = component.getClassName();
        int lastDot = abilityName.lastIndexOf('.');
        if (lastDot >= 0) {
            abilityName = abilityName.substring(lastDot + 1);
        }
        abilityName += "Ability";

        String wantJson = "{\"bundleName\":\"" + component.getPackageName()
                + "\",\"abilityName\":\"" + abilityName + "\"}";
        String json = nativeQueryAbilityInfos(wantJson, (int) flags);
        if (json == null || json.isEmpty()) {
            return null;
        }

        try {
            org.json.JSONArray array = new org.json.JSONArray(json);
            if (array.length() > 0) {
                org.json.JSONObject abilityJson = array.getJSONObject(0);
                ActivityInfo ai = new ActivityInfo();
                ai.name = IntentWantConverter.abilityNameToClassName(
                    component.getPackageName(), abilityJson.getString("name"));
                ai.packageName = component.getPackageName();
                ai.exported = abilityJson.optBoolean("visible", false);
                return ai;
            }
        } catch (org.json.JSONException e) {
            Log.e(TAG, "getActivityInfo: parse error", e);
        }
        return null;
    }

    /**
     * [BRIDGED] resolveIntent -> BMS.QueryAbilityInfos
     */
    @Override
    public ResolveInfo resolveIntent(Intent intent, String resolvedType, long flags, int userId) {
        logBridged("resolveIntent", intent.toString());
        List<ResolveInfo> results = queryIntentActivities(intent, resolvedType, flags, userId);
        if (results != null && !results.isEmpty()) {
            return results.get(0);
        }
        return null;
    }

    /**
     * [BRIDGED] queryIntentActivities -> BMS.QueryAbilityInfos
     */
    @Override
    public List<ResolveInfo> queryIntentActivities(Intent intent, String resolvedType,
                                                     long flags, int userId) {
        logBridged("queryIntentActivities", intent.toString());
        IntentWantConverter.WantParams want = IntentWantConverter.intentToWant(intent);
        String wantJson = buildWantJson(want);
        String json = nativeQueryAbilityInfos(wantJson, (int) flags);

        List<ResolveInfo> result = new ArrayList<>();
        if (json == null || json.isEmpty()) {
            return result;
        }

        try {
            org.json.JSONArray array = new org.json.JSONArray(json);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject abilityJson = array.getJSONObject(i);
                ResolveInfo ri = new ResolveInfo();
                ri.activityInfo = new ActivityInfo();
                String bundleName = abilityJson.optString("bundleName", "");
                ri.activityInfo.name = IntentWantConverter.abilityNameToClassName(
                    bundleName, abilityJson.getString("name"));
                ri.activityInfo.packageName = bundleName;
                ri.activityInfo.exported = abilityJson.optBoolean("visible", false);
                result.add(ri);
            }
        } catch (org.json.JSONException e) {
            Log.e(TAG, "queryIntentActivities: parse error", e);
        }

        return result;
    }

    // ========================================================================
    // Category 3: Permission Queries
    // ========================================================================

    /**
     * [BRIDGED] checkPermission -> AccessTokenKit.VerifyPermission
     */
    @Override
    public int checkPermission(String permName, String pkgName, int userId) {
        logBridged("checkPermission", permName + " for " + pkgName);
        String ohPermission = PermissionMapper.mapToOH(permName);
        return nativeCheckPermission(pkgName, ohPermission);
    }

    /**
     * [BRIDGED] getPackageUid -> BMS.GetUidByBundleName
     */
    @Override
    public int getPackageUid(String packageName, long flags, int userId) {
        logBridged("getPackageUid", packageName);
        return nativeGetUidByBundleName(packageName);
    }

    /**
     * [STUB] checkSignatures
     */
    @Override
    public int checkSignatures(String pkg1, String pkg2, int userId) {
        logStub("checkSignatures", pkg1 + " vs " + pkg2);
        return 0;  // SIGNATURE_MATCH
    }

    // ========================================================================
    // Category 4: Feature Queries
    // ========================================================================

    /**
     * [STUB] hasSystemFeature
     */
    @Override
    public boolean hasSystemFeature(String name, int version) {
        logStub("hasSystemFeature", name);
        // Phase 1: report common features as available
        switch (name) {
            case "android.hardware.touchscreen":
            case "android.hardware.wifi":
            case "android.hardware.bluetooth":
            case "android.hardware.camera":
            case "android.hardware.screen.portrait":
            case "android.hardware.screen.landscape":
                return true;
            default:
                return false;
        }
    }

    // ========================================================================
    // Utility Methods
    // ========================================================================

    private String buildWantJson(IntentWantConverter.WantParams want) {
        StringBuilder sb = new StringBuilder("{");
        if (want.bundleName != null) {
            sb.append("\"bundleName\":\"").append(want.bundleName).append("\",");
        }
        if (want.abilityName != null) {
            sb.append("\"abilityName\":\"").append(want.abilityName).append("\",");
        }
        if (want.action != null) {
            sb.append("\"action\":\"").append(want.action).append("\",");
        }
        if (want.uri != null) {
            sb.append("\"uri\":\"").append(want.uri).append("\",");
        }
        // Remove trailing comma
        if (sb.charAt(sb.length() - 1) == ',') {
            sb.setLength(sb.length() - 1);
        }
        sb.append("}");
        return sb.toString();
    }

    private void logBridged(String method, String detail) {
        Log.d(TAG, "[BRIDGED] " + method + ": " + detail);
    }

    private void logStub(String method, String detail) {
        Log.d(TAG, "[STUB] " + method + ": " + detail);
    }
}
