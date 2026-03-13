/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
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
 * @kit LocalizationKit
 */
import intl from './@ohos.intl';
/**
 * Provides international settings related APIs.
 *
 * @namespace i18n
 * @syscap SystemCapability.Global.I18n
 * @since 7
 */
/**
 * Provides international settings related APIs.
 *
 * @namespace i18n
 * @syscap SystemCapability.Global.I18n
 * @crossplatform
 * @form
 * @atomicservice
 * @since 11
 */
declare namespace i18n {
    /**
     * Obtains the localized name of the specified country/region.
     *
     * @param { string } country - Specified country.
     * @param { string } locale - System locale, which consists of the language, script, and country/region.
     * @param { boolean } [sentenceCase] - Whether to use sentence case to display the text. The value "true" means to
     *                                     display the text in title case format, and the value "false" means to display
     *                                     the text in the default case format of the locale. The default value is true.
     * @returns { string } Localized script for the specified country.
     * @syscap SystemCapability.Global.I18n
     * @since 7
     * @deprecated since 9
     * @useinstead ohos.System.getDisplayCountry
     */
    export function getDisplayCountry(country: string, locale: string, sentenceCase?: boolean): string;
    /**
     * Obtains the localized script for the specified language.
     *
     * @param { string } language - Specified language.
     * @param { string } locale - System locale, which consists of the language, script, and country/region.
     * @param { boolean } [sentenceCase] - Whether to use sentence case to display the text. The value "true" means to
     *                                     display the text in title case format, and the value "false" means to display
     *                                     the text in the default case format of the locale. The default value is true.
     * @returns { string } Localized script for the specified language.
     * @syscap SystemCapability.Global.I18n
     * @since 7
     * @deprecated since 9
     * @useinstead ohos.System.getDisplayLanguage
     */
    export function getDisplayLanguage(language: string, locale: string, sentenceCase?: boolean): string;
    /**
     * Obtains the system language.
     *
     * @returns { string } System language ID.
     * @syscap SystemCapability.Global.I18n
     * @since 7
     * @deprecated since 9
     * @useinstead ohos.System.getSystemLanguage
     */
    export function getSystemLanguage(): string;
    /**
     * Obtains the system region.
     *
     * @returns { string } System region ID.
     * @syscap SystemCapability.Global.I18n
     * @since 7
     * @deprecated since 9
     * @useinstead ohos.System.getSystemRegion
     */
    export function getSystemRegion(): string;
    /**
     * Obtains the system locale.
     *
     * @returns { string } System locale ID.
     * @syscap SystemCapability.Global.I18n
     * @since 7
     * @deprecated since 9
     * @useinstead ohos.System.getSystemLocale
     */
    export function getSystemLocale(): string;
    /**
     * Provides system functions.
     *
     * @syscap SystemCapability.Global.I18n
     * @since 9
     */
    /**
     * Provides system functions.
     *
     * @syscap SystemCapability.Global.I18n
     * @crossplatform
     * @since 10
     */
    /**
     * Provides system functions.
     *
     * @syscap SystemCapability.Global.I18n
     * @crossplatform
     * @form
     * @atomicservice
     * @since 11
     */
    export class System {
        /**
         * Obtains the country or region name localized for display on a given locale.
         *
         * @param { string } country - The locale whose country or region name will be displayed.
         * @param { string } locale - The locale used to display the country or region.
         * @param { boolean } [sentenceCase] - Specifies whether the country or region name is displayed in sentence case.
         * @returns { string } the country or region name localized for display on a given locale.
         * @throws { BusinessError } 401 - check param failed
         * @throws { BusinessError } 890001 - param value not valid
         * @syscap SystemCapability.Global.I18n
         * @since 9
         */
        /**
         * Obtains the country or region name localized for display on a given locale.
         *
         * @param { string } country - The locale whose country or region name will be displayed. It must be a valid country.
         * @param { string } locale - The locale used to display the country or region. It must be a valid locale.
         * @param { boolean } [sentenceCase] - Specifies whether the country or region name is displayed in sentence case.
         * @returns { string } the country or region name localized for display on a given locale.
         * @throws { BusinessError } 401 - Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types.
         * @throws { BusinessError } 890001 - Invalid parameter. Possible causes: Parameter verification failed.
         * @syscap SystemCapability.Global.I18n
         * @crossplatform
         * @since 10
         */
        /**
         * Obtains the country/region display name in the specified language.
         *
         * @param { string } country - Valid country/region code.
         * @param { string } locale - System locale, which consists of the language, script, and country/region.
