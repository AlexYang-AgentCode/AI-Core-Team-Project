/*
 * ContentProviderRegistry.java
 *
 * In-process registry for Android ContentProviders running within the adapter.
 *
 * Manages two categories of providers:
 *   1. Local providers: Android App's own ContentProviders, published via
 *      publishContentProviders(). Stored as IContentProvider Binder references.
 *   2. OH bridges: ContentProviderBridge instances that proxy to OH DataShare.
 *      Created on-demand when getContentProvider() is called for OH-backed data.
 *
 * This registry replaces the AMS-side ContentProvider management for the
 * adapter environment, since there is no real Android AMS running.
 *
 * Reference:
 *   Android: services/core/java/com/android/server/am/ContentProviderHelper.java
 */
package adapter.contentprovider;

import android.app.ContentProviderHolder;
import android.content.IContentProvider;
import android.content.pm.ProviderInfo;
import android.util.Log;

import adapter.contentprovider.ContentProviderUriConverter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class ContentProviderRegistry {

    private static final String TAG = "OH_CPRegistry";

    // Singleton
    private static final ContentProviderRegistry sInstance = new ContentProviderRegistry();

    public static ContentProviderRegistry getInstance() {
        return sInstance;
    }

    // Map<authority, ContentProviderHolder> for locally published Android providers
    private final Map<String, ContentProviderHolder> mLocalProviders = new ConcurrentHashMap<>();

    // Map<authority, ContentProviderBridge> for OH DataShare bridges (cached)
    private final Map<String, ContentProviderBridge> mOhBridges = new ConcurrentHashMap<>();

    private ContentProviderRegistry() {}

    // ========================================================================
    // Provider registration (called by ActivityManagerAdapter)
    // ========================================================================

    /**
     * Register locally published Android ContentProviders.
     * Called when an Android App process publishes its providers.
     *
     * @param providers List of ContentProviderHolder from the app
     */
    public void publishProviders(List<ContentProviderHolder> providers) {
        if (providers == null) return;

        for (ContentProviderHolder holder : providers) {
            if (holder == null || holder.info == null) continue;

            String authority = holder.info.authority;
            if (authority == null) continue;

            // An authority string may contain multiple authorities separated by ";"
            String[] authorities = authority.split(";");
            for (String auth : authorities) {
                auth = auth.trim();
                if (!auth.isEmpty()) {
                    mLocalProviders.put(auth, holder);
                    Log.d(TAG, "Published local provider: " + auth);
                }
            }
        }
    }

    /**
     * Remove a local provider reference.
     */
    public void removeProvider(String authority) {
        if (authority == null) return;
        ContentProviderHolder removed = mLocalProviders.remove(authority);
        if (removed != null) {
            Log.d(TAG, "Removed local provider: " + authority);
        }
    }

    // ========================================================================
    // Provider acquisition (called by ActivityManagerAdapter.getContentProvider)
    // ========================================================================

    /**
     * Get a ContentProviderHolder for the given authority.
     *
     * Resolution order:
     *   1. Check locally published Android providers (app-to-app)
     *   2. Create/return OH DataShare bridge (app-to-OH-system)
     *
     * @param authority The content provider authority
     * @return ContentProviderHolder with valid IContentProvider, or null
     */
    public ContentProviderHolder acquireProvider(String authority) {
        if (authority == null) return null;

        // 1. Check locally published Android providers first
        ContentProviderHolder local = mLocalProviders.get(authority);
        if (local != null && local.provider != null) {
            Log.d(TAG, "acquireProvider: found local provider for " + authority);
            return local;
        }

        // 2. Create or retrieve OH DataShare bridge
        ContentProviderBridge bridge = mOhBridges.get(authority);
        if (bridge == null) {
            Log.d(TAG, "acquireProvider: creating OH bridge for " + authority);
            bridge = new ContentProviderBridge(authority);
            mOhBridges.put(authority, bridge);
        }

        // Wrap bridge in a ContentProviderHolder
        ProviderInfo info = new ProviderInfo();
        info.authority = authority;
        info.name = "adapter.contentprovider.ContentProviderBridge";
        info.exported = true;

        ContentProviderHolder holder = new ContentProviderHolder(info);
        holder.provider = bridge;
        holder.noReleaseNeeded = true;

        return holder;
    }

    /**
     * Check if a provider exists (either local or OH-backed).
     */
    public boolean hasProvider(String authority) {
        return mLocalProviders.containsKey(authority) || mOhBridges.containsKey(authority);
    }

    /**
     * Release all OH bridges. Called during adapter shutdown.
     */
    public void releaseAll() {
        for (ContentProviderBridge bridge : mOhBridges.values()) {
            bridge.release();
        }
        mOhBridges.clear();
        mLocalProviders.clear();
        Log.d(TAG, "Released all providers");
    }
}
