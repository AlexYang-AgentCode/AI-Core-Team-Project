/**
 * appspawn-x child process entry point.
 *
 * After fork(), the child process calls ChildMain::run() which applies
 * OH security restrictions (DAC, sandbox, SELinux, AccessToken), initializes
 * the adapter layer, and enters the Android ActivityThread event loop.
 */

#pragma once

#include "spawn_msg.h"
#include <jni.h>

namespace appspawnx {

class AppSpawnXRuntime;

class ChildMain {
public:
    // Run in child process after fork.
    // This function does not return – it enters ActivityThread.main() event loop.
    [[noreturn]] static void run(const SpawnMsg& msg, AppSpawnXRuntime* runtime);

private:
    // OH security specialization
    static int applyDac(const SpawnMsg& msg);
    static int applySandbox(const SpawnMsg& msg);
    static int applySELinux(const SpawnMsg& msg);
    static int applyAccessToken(const SpawnMsg& msg);

    // Android initialization
    static int initAdapterLayer(JNIEnv* env);
    static void launchActivityThread(JNIEnv* env, const SpawnMsg& msg);
};

} // namespace appspawnx
