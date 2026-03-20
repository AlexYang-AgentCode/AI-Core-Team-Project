/*
 * installd_host_impl_android.cpp
 *
 * OH installd extension: Android APK-specific installation operations.
 *
 * Implements the 5 new IPC methods added to InstalldInterface for APK support:
 *   - CreateAndroidDataDir (code 90)
 *   - ExtractApkNativeLibs (code 91)
 *   - DexOptAndroid (code 92)
 *   - RemoveAndroidDataDir (code 93)
 *   - VerifyApkSignature (code 94)
 *
 * These methods are added to InstalldHostImpl as an extension.
 * The implementation runs in the installd daemon process with root privileges.
 */

#include "installd_host_impl.h"

#include <cerrno>
#include <cstring>
#include <fstream>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

#include <unzip.h>  // minizip

#include "directory_ex.h"
#include "app_log_wrapper.h"

namespace OHOS {
namespace AppExecFwk {

namespace {

constexpr const char* ANDROID_DATA_BASE = "/data/app/el2/0/android";
constexpr const char* ANDROID_EXT_BASE = "/data/app/el2/0/android_ext";
constexpr const char* DEX2OAT_BIN = "/system/android/bin/dex2oat";
constexpr const char* BOOT_IMAGE = "/system/android/framework/boot.art";
constexpr const char* ANDROID_ROOT = "/system/android";
constexpr size_t COPY_BUF_SIZE = 65536;

// Supported ABI priority (ARM64 device)
const std::vector<std::string> kSupportedAbis = {
    "arm64-v8a",
    "armeabi-v7a",
    "armeabi"
};

bool MakeDirWithOwner(const std::string& path, mode_t mode, int32_t uid, int32_t gid) {
    if (!ForceCreateDirectory(path)) {
        APP_LOGE("MakeDirWithOwner: mkdir failed: %{public}s", path.c_str());
        return false;
    }
    if (chmod(path.c_str(), mode) != 0) {
        APP_LOGW("MakeDirWithOwner: chmod failed: %{public}s (%{public}s)",
                 path.c_str(), strerror(errno));
    }
    if (chown(path.c_str(), uid, gid) != 0) {
        APP_LOGW("MakeDirWithOwner: chown failed: %{public}s (%{public}s)",
                 path.c_str(), strerror(errno));
    }
    return true;
}

}  // namespace

ErrCode InstalldHostImpl::CreateAndroidDataDir(
        const std::string& bundleName, int32_t uid, int32_t gid,
        int32_t targetSdkVersion) {
    APP_LOGI("CreateAndroidDataDir: %{public}s uid=%{public}d", bundleName.c_str(), uid);

    std::string baseDir = std::string(ANDROID_DATA_BASE) + "/" + bundleName;

    // Create Android-style subdirectories
    const std::vector<std::pair<std::string, mode_t>> dirs = {
        {"",              0771},
        {"/cache",        0771},
        {"/code_cache",   0771},
        {"/databases",    0771},
        {"/files",        0771},
        {"/shared_prefs", 0771},
        {"/lib",          0755},
    };

    for (const auto& [sub, mode] : dirs) {
        std::string path = baseDir + sub;
        if (!MakeDirWithOwner(path, mode, uid, gid)) {
            return ERR_APPEXECFWK_INSTALLD_CREATE_DIR_FAILED;
        }
    }

    // External storage directory
    std::string extDir = std::string(ANDROID_EXT_BASE) + "/" + bundleName;
    if (!MakeDirWithOwner(extDir, 0771, uid, 1015 /* sdcard_rw */)) {
        APP_LOGW("CreateAndroidDataDir: external dir creation failed (non-fatal)");
    }

    APP_LOGI("CreateAndroidDataDir: success for %{public}s", bundleName.c_str());
    return ERR_OK;
}

ErrCode InstalldHostImpl::ExtractApkNativeLibs(
        const std::string& apkPath,
        const std::string& targetDir,
        const std::string& primaryAbi) {
    APP_LOGI("ExtractApkNativeLibs: apk=%{public}s abi=%{public}s",
             apkPath.c_str(), primaryAbi.c_str());

    ForceCreateDirectory(targetDir);

    unzFile zip = unzOpen(apkPath.c_str());
    if (zip == nullptr) {
        APP_LOGE("ExtractApkNativeLibs: failed to open APK");
        return ERR_APPEXECFWK_INSTALLD_EXTRACT_FILES_FAILED;
    }

    std::string prefix = "lib/" + primaryAbi + "/";
    int extractedCount = 0;

    if (unzGoToFirstFile(zip) == UNZ_OK) {
        do {
            char filename[512];
            unz_file_info fileInfo;
            if (unzGetCurrentFileInfo(zip, &fileInfo, filename, sizeof(filename),
                                       nullptr, 0, nullptr, 0) != UNZ_OK) {
                continue;
            }

            std::string entryName(filename);
            if (entryName.compare(0, prefix.size(), prefix) != 0) continue;
            if (entryName.size() <= prefix.size()) continue;

            std::string soName = entryName.substr(prefix.size());
            if (soName.find('/') != std::string::npos) continue;

            if (unzOpenCurrentFile(zip) != UNZ_OK) continue;

            std::string outPath = targetDir + "/" + soName;
            std::ofstream out(outPath, std::ios::binary | std::ios::trunc);
            if (!out) {
                unzCloseCurrentFile(zip);
                continue;
            }

            char buf[COPY_BUF_SIZE];
            int bytesRead;
            while ((bytesRead = unzReadCurrentFile(zip, buf, sizeof(buf))) > 0) {
                out.write(buf, bytesRead);
            }

            out.close();
            unzCloseCurrentFile(zip);
            chmod(outPath.c_str(), 0755);
            extractedCount++;
        } while (unzGoToNextFile(zip) == UNZ_OK);
    }

    unzClose(zip);
    APP_LOGI("ExtractApkNativeLibs: extracted %{public}d files", extractedCount);
    return ERR_OK;
}

ErrCode InstalldHostImpl::DexOptAndroid(
        const std::string& apkPath,
        const std::string& oatDir,
        int32_t uid,
        const std::string& instructionSet,
        const std::string& compilerFilter) {
    APP_LOGI("DexOptAndroid: apk=%{public}s filter=%{public}s",
             apkPath.c_str(), compilerFilter.c_str());

    ForceCreateDirectory(oatDir);

    std::string oatFile = oatDir + "/base.odex";

    std::vector<std::string> args = {
        DEX2OAT_BIN,
        "--dex-file=" + apkPath,
        "--oat-file=" + oatFile,
        "--instruction-set=" + instructionSet,
        "--compiler-filter=" + compilerFilter,
        "--boot-image=" + std::string(BOOT_IMAGE),
        "--android-root=" + std::string(ANDROID_ROOT),
    };

    pid_t pid = fork();
    if (pid < 0) {
        APP_LOGE("DexOptAndroid: fork failed: %{public}s", strerror(errno));
        return ERR_APPEXECFWK_INSTALLD_DEXOPT_FAILED;
    }

    if (pid == 0) {
        // Child process: drop to app UID before running dex2oat
        if (setuid(uid) != 0) {
            APP_LOGE("DexOptAndroid: setuid failed");
            _exit(127);
        }

        std::vector<const char*> argv;
        for (const auto& arg : args) {
            argv.push_back(arg.c_str());
        }
        argv.push_back(nullptr);

        execv(argv[0], const_cast<char**>(argv.data()));
        // If execv returns, it failed
        _exit(127);
    }

    // Parent: wait for completion
    int status;
    waitpid(pid, &status, 0);

    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
        APP_LOGI("DexOptAndroid: success, output=%{public}s", oatFile.c_str());
        return ERR_OK;
    }

    APP_LOGE("DexOptAndroid: dex2oat failed with exit code %{public}d",
             WEXITSTATUS(status));
    return ERR_APPEXECFWK_INSTALLD_DEXOPT_FAILED;
}

ErrCode InstalldHostImpl::RemoveAndroidDataDir(const std::string& bundleName) {
    APP_LOGI("RemoveAndroidDataDir: %{public}s", bundleName.c_str());

    std::string dataDir = std::string(ANDROID_DATA_BASE) + "/" + bundleName;
    std::string extDir = std::string(ANDROID_EXT_BASE) + "/" + bundleName;

    bool success = true;
    if (!ForceRemoveDirectory(dataDir)) {
        APP_LOGW("RemoveAndroidDataDir: failed to remove: %{public}s", dataDir.c_str());
        success = false;
    }
    if (!ForceRemoveDirectory(extDir)) {
        APP_LOGW("RemoveAndroidDataDir: failed to remove: %{public}s", extDir.c_str());
        success = false;
    }

    return success ? ERR_OK : ERR_APPEXECFWK_INSTALLD_REMOVE_DIR_FAILED;
}

ErrCode InstalldHostImpl::VerifyApkSignature(
        const std::string& apkPath,
        const std::string& expectedCertHash) {
    APP_LOGI("VerifyApkSignature: %{public}s", apkPath.c_str());

    // Delegate to ApkSignatureVerifier
    oh_adapter::ApkSignatureVerifier::VerifyResult result =
        oh_adapter::ApkSignatureVerifier::Verify(apkPath);

    if (!result.verified) {
        APP_LOGE("VerifyApkSignature: failed: %{public}s", result.errorMsg.c_str());
        return ERR_APPEXECFWK_INSTALL_FAILED_VERIFY_SIGNATURE;
    }

    // If expectedCertHash is provided (update scenario), verify certificate matches
    if (!expectedCertHash.empty() &&
        result.certFingerprint != expectedCertHash) {
        APP_LOGE("VerifyApkSignature: certificate mismatch");
        return ERR_APPEXECFWK_INSTALL_FAILED_INCONSISTENT_SIGNATURE;
    }

    APP_LOGI("VerifyApkSignature: success, cert=%{public}s",
             result.certFingerprint.c_str());
    return ERR_OK;
}

}  // namespace AppExecFwk
}  // namespace OHOS
