// HarmonyOS ArkTS equivalent of Android MediaPlayer demo
// Android: MediaPlayer + SeekBar → HarmonyOS: AVPlayer + Slider

import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Mirrors PlaybackInfoListener.State
enum PlaybackState {
  INVALID = -1,
  PLAYING = 0,
  PAUSED = 1,
  RESET = 2,
  COMPLETED = 3
}

@Entry
@Component
struct MediaPlayerPage {
  @State debugLog: string = '';
  @State currentPosition: number = 0;
  @State duration: number = 0;
  @State playbackState: PlaybackState = PlaybackState.INVALID;
  @State userIsSeeking: boolean = false;

  private avPlayer: media.AVPlayer | null = null;
  private context: common.UIAbilityContext | undefined = undefined;
  private progressTimerId: number = -1;

  // Mirrors PLAYBACK_POSITION_REFRESH_INTERVAL_MS
  private readonly REFRESH_INTERVAL_MS: number = 1000;

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.initializePlayer();
  }

  aboutToDisappear(): void {
    this.releasePlayer();
  }

  private logToUI(message: string): void {
    this.debugLog += message + '\n';
  }

  private stateToString(state: PlaybackState): string {
    switch (state) {
      case PlaybackState.PLAYING: return 'PLAYING';
      case PlaybackState.PAUSED: return 'PAUSED';
      case PlaybackState.RESET: return 'RESET';
      case PlaybackState.COMPLETED: return 'COMPLETED';
      default: return 'INVALID';
    }
  }

  // Android: new MediaPlayer() + setDataSource + prepare
  // HarmonyOS: media.createAVPlayer() + url/fdSrc + prepare()
  private async initializePlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      this.logToUI('avPlayer = createAVPlayer()');

      // Android: setOnCompletionListener → HarmonyOS: on('stateChange')
      this.avPlayer.on('stateChange', (state: string) => {
        switch (state) {
          case 'initialized':
            this.logToUI('load() {2. prepare}');
            this.avPlayer!.prepare();
            break;
          case 'prepared':
            // Android: initializeProgressCallback — get duration
            this.duration = this.avPlayer!.duration;
            this.currentPosition = 0;
            this.logToUI(`setPlaybackDuration: ${Math.floor(this.duration / 1000)} sec`);
            this.logToUI('setPlaybackPosition(0)');
            break;
          case 'playing':
            this.playbackState = PlaybackState.PLAYING;
            this.logToUI(`onStateChanged(${this.stateToString(this.playbackState)})`);
            this.startProgressUpdate();
            break;
          case 'paused':
            this.playbackState = PlaybackState.PAUSED;
            this.logToUI(`onStateChanged(${this.stateToString(this.playbackState)})`);
            break;
          case 'stopped':
            this.playbackState = PlaybackState.RESET;
            this.logToUI(`onStateChanged(${this.stateToString(this.playbackState)})`);
            this.stopProgressUpdate(true);
            break;
          case 'completed':
            this.playbackState = PlaybackState.COMPLETED;
            this.logToUI('MediaPlayer playback completed');
            this.logToUI(`onStateChanged(${this.stateToString(this.playbackState)})`);
            this.stopProgressUpdate(true);
            break;
          default:
            break;
        }
      });

      this.avPlayer.on('error', (err: BusinessError) => {
        this.logToUI(`Error: ${err.message}`);
      });

      // Load media from rawfile — mirrors MediaPlayer.create(context, R.raw.jazz_in_paris)
      // Android: setDataSource(assetFileDescriptor)
      // HarmonyOS: avPlayer.fdSrc for raw resources
      const resourceManager = this.context!.resourceManager;
      const rawFd = await resourceManager.getRawFd('jazz_in_paris.mp3');
      this.avPlayer.fdSrc = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      };
      this.logToUI('load() {1. setDataSource}');

    } catch (error) {
      this.logToUI(`Init error: ${JSON.stringify(error)}`);
    }
  }

  // Android: mMediaPlayer.start()
  // HarmonyOS: avPlayer.play()
  private play(): void {
    if (this.avPlayer && this.playbackState !== PlaybackState.PLAYING) {
      this.avPlayer.play();
      this.logToUI('playbackStart()');
    }
  }

  // Android: mMediaPlayer.pause()
  // HarmonyOS: avPlayer.pause()
  private pause(): void {
    if (this.avPlayer && this.playbackState === PlaybackState.PLAYING) {
      this.avPlayer.pause();
      this.logToUI('playbackPause()');
    }
  }

  // Android: mMediaPlayer.reset() + loadMedia()
  // HarmonyOS: avPlayer.reset() then re-set source
  private async reset(): Promise<void> {
    if (this.avPlayer) {
      this.logToUI('playbackReset()');
      await this.avPlayer.reset();
      this.stopProgressUpdate(true);

      // Re-load media after reset
      const resourceManager = this.context!.resourceManager;
      const rawFd = await resourceManager.getRawFd('jazz_in_paris.mp3');
      this.avPlayer.fdSrc = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      };
    }
  }

  // Android: mMediaPlayer.seekTo(position)
  // HarmonyOS: avPlayer.seek(ms)
  private seekTo(positionMs: number): void {
    if (this.avPlayer) {
      this.logToUI(`seekTo() ${positionMs} ms`);
      this.avPlayer.seek(positionMs);
    }
  }

  // Android: mMediaPlayer.release()
  // HarmonyOS: avPlayer.release()
  private async releasePlayer(): Promise<void> {
    this.stopProgressUpdate(false);
    if (this.avPlayer) {
      this.logToUI('release() avPlayer');
      await this.avPlayer.release();
      this.avPlayer = null;
    }
  }

  // Mirrors startUpdatingCallbackWithPosition — periodic position update
  private startProgressUpdate(): void {
    if (this.progressTimerId !== -1) {
      return;
    }
    this.progressTimerId = setInterval(() => {
      if (this.avPlayer && this.playbackState === PlaybackState.PLAYING && !this.userIsSeeking) {
        this.currentPosition = this.avPlayer.currentTime;
      }
    }, this.REFRESH_INTERVAL_MS);
  }

  // Mirrors stopUpdatingCallbackWithPosition
  private stopProgressUpdate(resetPosition: boolean): void {
    if (this.progressTimerId !== -1) {
      clearInterval(this.progressTimerId);
      this.progressTimerId = -1;
    }
    if (resetPosition) {
      this.currentPosition = 0;
    }
  }

  build() {
    Column() {
      // Debug log area — mirrors ScrollView + TextView
      Scroll() {
        Text(this.debugLog)
          .fontSize(12)
          .fontFamily('monospace')
          .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .margin(8)

      // SeekBar — Android: SeekBar → HarmonyOS: Slider
      Slider({
        value: this.currentPosition,
        min: 0,
        max: this.duration > 0 ? this.duration : 100,
        step: 1
      })
        .width('100%')
        .margin({ top: 16, bottom: 16 })
        .onChange((value: number, mode: SliderChangeMode) => {
          if (mode === SliderChangeMode.Begin) {
            this.userIsSeeking = true;
          } else if (mode === SliderChangeMode.End) {
            this.userIsSeeking = false;
            this.seekTo(value);
          }
          this.currentPosition = value;
        })

      // Buttons row — mirrors LinearLayout with Play/Pause/Reset
      Row() {
        Button('Play')
          .layoutWeight(4)
          .onClick(() => this.play())

        Button('Pause')
          .layoutWeight(1)
          .margin({ left: 8 })
          .onClick(() => this.pause())

        Button('Reset')
          .layoutWeight(1)
          .margin({ left: 8 })
          .onClick(() => this.reset())
      }
      .width('100%')
      .margin({ bottom: 8 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(8)
  }
}
