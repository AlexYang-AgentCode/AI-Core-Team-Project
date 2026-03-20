/*
 * oh_ability_manager_client.cpp
 *
 * OpenHarmony AbilityManager IPC client implementation.
 *
 * Connects to OH AbilityManagerService via SystemAbilityManager and sends
 * IPC requests (StartAbility, ConnectAbility, etc.) using OH IPC framework.
 *
 * Reference paths:
 *   OH: ability_rt/interfaces/inner_api/ability_manager/include/ability_manager_interface.h
 *   OH: ability_rt/services/abilitymgr/include/ability_manager_proxy.h
 */
#include "oh_ability_manager_client.h"
#include "oh_callback_handler.h"
#include <android/log.h>

#include "ipc_skeleton.h"
#include "system_ability_manager_proxy.h"
#include "ability_manager_interface.h"
#include "ability_manager_proxy.h"
#include "want.h"

#define LOG_TAG "OH_AbilityMgrClient"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

// OH system ability ID for AbilityManagerService
static constexpr int32_t ABILITY_MGR_SERVICE_ID = 180;

namespace oh_adapter {

OHAbilityManagerClient& OHAbilityManagerClient::getInstance() {
    static OHAbilityManagerClient instance;
    return instance;
}

bool OHAbilityManagerClient::connect() {
    LOGI("Connecting to OH AbilityManagerService...");

    auto samgr = OHOS::SystemAbilityManagerClient::GetInstance().GetSystemAbilityManager();
    if (samgr == nullptr) {
        LOGE("Failed to get SystemAbilityManager");
        return false;
    }

    auto remoteObject = samgr->GetSystemAbility(ABILITY_MGR_SERVICE_ID);
    if (remoteObject == nullptr) {
        LOGE("Failed to get AbilityManagerService remote object (SA ID=%d)", ABILITY_MGR_SERVICE_ID);
        return false;
    }

    proxy_ = OHOS::iface_cast<OHOS::AAFwk::IAbilityManager>(remoteObject);
    if (proxy_ == nullptr) {
        LOGE("Failed to cast remote object to IAbilityManager");
        return false;
    }

    connected_ = true;
    LOGI("Connected to OH AbilityManagerService successfully");
    return true;
}

void OHAbilityManagerClient::disconnect() {
    LOGI("Disconnecting from OH AbilityManagerService");
    proxy_ = nullptr;
    connected_ = false;
}

int OHAbilityManagerClient::startAbility(const WantParams& want) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("StartAbility: bundle=%s, ability=%s, action=%s",
         want.bundleName.c_str(), want.abilityName.c_str(), want.action.c_str());

    // Construct OH Want object
    OHOS::AAFwk::Want ohWant;
    OHOS::AppExecFwk::ElementName element("", want.bundleName, want.abilityName);
    ohWant.SetElement(element);

    if (!want.action.empty()) {
        ohWant.SetAction(want.action);
    }
    if (!want.uri.empty()) {
        ohWant.SetUri(want.uri);
    }
    if (!want.parametersJson.empty()) {
        // Pass extras as a string parameter for Java-side parsing
        ohWant.SetParam("android_extras_json", want.parametersJson);
    }

    // Call AbilityManager.StartAbility via IPC
    int result = proxy_->StartAbility(ohWant);

    LOGI("StartAbility returned %d (0=success)", result);
    return result;
}

int OHAbilityManagerClient::connectAbility(const WantParams& want, int connectionId) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("ConnectAbility: bundle=%s, ability=%s, connId=%d",
         want.bundleName.c_str(), want.abilityName.c_str(), connectionId);

    // Construct OH Want
    OHOS::AAFwk::Want ohWant;
    OHOS::AppExecFwk::ElementName element("", want.bundleName, want.abilityName);
    ohWant.SetElement(element);

    // Get per-connection AbilityConnection stub from OHCallbackHandler
    auto connection = OHCallbackHandler::getInstance().getAbilityConnection(connectionId);
    if (connection == nullptr) {
        LOGE("Failed to create AbilityConnection for connId=%d", connectionId);
        return -1;
    }

    int result = proxy_->ConnectAbility(ohWant, connection, -1);
    LOGI("ConnectAbility returned %d", result);
    return result;
}

int OHAbilityManagerClient::disconnectAbility(int connectionId) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("DisconnectAbility: connectionId=%d", connectionId);

    auto connection = OHCallbackHandler::getInstance().getAbilityConnection(connectionId);
    if (connection == nullptr) {
        LOGE("AbilityConnection not found for connId=%d", connectionId);
        return -1;
    }

    int result = proxy_->DisconnectAbility(connection);
    // Clean up the connection adapter
    OHCallbackHandler::getInstance().removeAbilityConnection(connectionId);
    LOGI("DisconnectAbility returned %d", result);
    return result;
}

int OHAbilityManagerClient::stopServiceAbility(const WantParams& want) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("StopServiceAbility: bundle=%s, ability=%s",
         want.bundleName.c_str(), want.abilityName.c_str());

    OHOS::AAFwk::Want ohWant;
    OHOS::AppExecFwk::ElementName element("", want.bundleName, want.abilityName);
    ohWant.SetElement(element);

    int result = proxy_->StopServiceAbility(ohWant);

    LOGI("StopServiceAbility returned %d (0=success)", result);
    return result;
}

int OHAbilityManagerClient::startAbilityInMission(const WantParams& want, int32_t missionId) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("StartAbilityInMission: bundle=%s, ability=%s, missionId=%d",
         want.bundleName.c_str(), want.abilityName.c_str(), missionId);

    OHOS::AAFwk::Want ohWant;
    OHOS::AppExecFwk::ElementName element("", want.bundleName, want.abilityName);
    ohWant.SetElement(element);

    if (!want.action.empty()) {
        ohWant.SetAction(want.action);
    }
    if (!want.uri.empty()) {
        ohWant.SetUri(want.uri);
    }
    if (!want.parametersJson.empty()) {
        ohWant.SetParam("android_extras_json", want.parametersJson);
    }

    int result = proxy_->StartAbilityInMission(ohWant, missionId);

    LOGI("StartAbilityInMission returned %d (0=success)", result);
    return result;
}

int OHAbilityManagerClient::cleanMission(int32_t missionId) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("CleanMission: missionId=%d", missionId);
    int result = proxy_->CleanMission(missionId);
    LOGI("CleanMission returned %d", result);
    return result;
}

int OHAbilityManagerClient::moveMissionToFront(int32_t missionId) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("MoveMissionToFront: missionId=%d", missionId);
    int result = proxy_->MoveMissionToFront(missionId);
    LOGI("MoveMissionToFront returned %d", result);
    return result;
}

int OHAbilityManagerClient::setMultiAbilityMode(int32_t missionId, bool enabled) {
    // This is set on the Mission object via the StartAbility return path.
    // The adapter stores the mapping locally; the actual flag is set
    // via a custom parameter in the StartAbility Want.
    LOGI("setMultiAbilityMode: missionId=%d, enabled=%d", missionId, enabled);
    // The flag is set on the OH side during Mission creation when
    // the Want contains the android adapter marker.
    return 0;
}

bool OHAbilityManagerClient::isTopAbility(int32_t missionId, const std::string& abilityName) {
    if (!connected_ || proxy_ == nullptr) {
        return false;
    }

    // Query the Mission's top Ability via GetMissionInfo
    OHOS::AAFwk::MissionInfo missionInfo;
    int result = proxy_->GetMissionInfo("", missionId, missionInfo);
    if (result != 0) {
        return false;
    }

    auto element = missionInfo.want.GetElement();
    return element.GetAbilityName() == abilityName;
}

int OHAbilityManagerClient::clearAbilitiesAbove(int32_t missionId, const std::string& abilityName) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("ClearAbilitiesAbove: missionId=%d, abilityName=%s", missionId, abilityName.c_str());

    // This operation is handled within OH MissionListManager via a custom IPC call.
    // The adapter sets a Want parameter that triggers stack clearing in the patched
    // TerminateAbilityLocked / StartAbilityInMission path.
    //
    // Approach: start the target ability with a CLEAR_TOP marker in the Want.
    // The patched MissionListManager.StartAbilityInMission checks this marker
    // and calls Mission::PopAbilitiesAbove before pushing.
    OHOS::AAFwk::Want ohWant;
    // Use existing mission's bundle from MissionInfo
    OHOS::AAFwk::MissionInfo missionInfo;
    int result = proxy_->GetMissionInfo("", missionId, missionInfo);
    if (result != 0) {
        LOGE("ClearAbilitiesAbove: failed to get MissionInfo for %d", missionId);
        return -1;
    }

    auto element = missionInfo.want.GetElement();
    OHOS::AppExecFwk::ElementName newElement("", element.GetBundleName(), abilityName);
    ohWant.SetElement(newElement);
    ohWant.SetParam("android_clear_top", true);

    result = proxy_->StartAbilityInMission(ohWant, missionId);
    LOGI("ClearAbilitiesAbove returned %d", result);
    return result;
}

int32_t OHAbilityManagerClient::getMissionIdForBundle(const std::string& bundleName) {
    if (!connected_ || proxy_ == nullptr) {
        LOGE("Not connected to AbilityManagerService");
        return -1;
    }

    LOGI("GetMissionIdForBundle: bundle=%s", bundleName.c_str());

    // Query recent missions and find one matching the bundle name
    std::vector<OHOS::AAFwk::MissionInfo> missionInfos;
    int result = proxy_->GetMissionInfos("", 100, missionInfos);
    if (result != 0) {
        LOGE("GetMissionIdForBundle: GetMissionInfos failed with %d", result);
        return -1;
    }

    // Search for a mission whose Want element matches the bundle name
    for (const auto& info : missionInfos) {
        auto element = info.want.GetElement();
        if (element.GetBundleName() == bundleName) {
            LOGI("GetMissionIdForBundle: found missionId=%d for bundle=%s",
                 info.id, bundleName.c_str());
            return info.id;
        }
    }

    LOGW("GetMissionIdForBundle: no mission found for bundle=%s", bundleName.c_str());
    return -1;
}

}  // namespace oh_adapter
