/*
 * Copyright (c) 2022-2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License"),
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * @file
 * @kit AbilityKit
 */
import Ability from './@ohos.app.ability.Ability';
import AbilityConstant from './@ohos.app.ability.AbilityConstant';
import Want from './@ohos.app.ability.Want';
import window from './@ohos.window';
import UIAbilityContext from './application/UIAbilityContext';
import rpc from './@ohos.rpc';
/**
 * The prototype of the listener function interface registered by the Caller.
 *
 * @typedef OnReleaseCallback
 * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
 * @stagemodelonly
 * @since 9
 */
export interface OnReleaseCallback {
    /**
     * Defines the callback that is invoked when the stub on the target UIAbility is disconnected.
     *
     * @param { string } msg - Message used for disconnection.
     * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
     * @stagemodelonly
     * @since 9
     */
    (msg: string): void;
}
/**
 * The prototype of the listener function interface registered by the Caller.
 *
 * @typedef OnRemoteStateChangeCallback
 * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
 * @stagemodelonly
 * @since 10
 */
export interface OnRemoteStateChangeCallback {
    /**
     * Defines the callback that is invoked when the remote UIAbility state changes in the collaboration scenario.
     *
     * @param { string } msg - Message used for disconnection.
     * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
     * @stagemodelonly
     * @since 10
     */
    (msg: string): void;
}
/**
 * The prototype of the message listener function interface registered by the Callee.
 *
 * @typedef CalleeCallback
 * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
 * @stagemodelonly
 * @since 9
 */
export interface CalleeCallback {
    /**
     * Defines the callback of the registration message notification of the UIAbility.
     *
     * @param { rpc.MessageSequence } indata - Data to be transferred.
     * @returns { rpc.Parcelable } Returned data object.
     * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
     * @stagemodelonly
     * @since 9
     */
    (indata: rpc.MessageSequence): rpc.Parcelable;
}
/**
 * Implements sending of parcelable data to the target UIAbility when the CallerAbility invokes the target UIAbility (CalleeAbility).
 *
 * @interface Caller
 * @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
 * @stagemodelonly
 * @since 9
 */
export interface Caller {
    /**
     * Sends parcelable data to the target UIAbility. This API uses a promise to return the result.
     *
     * @param { string } method - Notification message string negotiated between the two UIAbilities. The message is used
     * to instruct the callee to register a function to receive the parcelable data.
     * @param { rpc.Parcelable } data - Parcelable data. You need to customize the data.
     * @returns { Promise<void> } Promise that returns no value.
     * @throws { BusinessError } 401 - Parameter error. Possible causes: 1. Mandatory parameters are left unspecified;
     * 2. Incorrect parameter types.
