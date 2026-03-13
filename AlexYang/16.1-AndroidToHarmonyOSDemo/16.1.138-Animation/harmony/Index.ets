// HarmonyOS ArkTS equivalent of Android ObjectAnimator / AnimatorSet demo
// Android: ObjectAnimator.ofFloat + AnimatorSet → HarmonyOS: animateTo + @State

@Entry
@Component
struct AnimationPage {
  // Animated translation Y for each button — mirrors ObjectAnimator "translationY"
  @State repeatOffsetY: number = 0;
  @State persistOffsetY: number = 0;
  @State randomOffsetY: number = 0;

  // dp to vp conversion not needed in ArkUI (vp is density-independent)
  private readonly TRANSLATION_DISTANCE: number = 30; // vp

  private randomTimerId: number = -1;
  private lastRandomLocation: number = 0;

  // Android: animateButton() — AnimatorSet with infinite bounce
  // First animates down, then bounces infinitely between +/- distance
  private animateRepeatButton(): void {
    const duration = 750;
    const distance = this.TRANSLATION_DISTANCE;

    // Phase 1: translate down (animator1, repeatCount=0)
    animateTo({
      duration: duration,
      curve: Curve.EaseInOut,
      onFinish: () => {
        // Phase 2: bounce infinitely (animator2, INFINITE, REVERSE)
        animateTo({
          duration: duration,
          curve: Curve.EaseInOut,
          iterations: -1,   // Android: Animation.INFINITE
          playMode: PlayMode.Alternate // Android: Animation.REVERSE
        }, () => {
          this.repeatOffsetY = -distance;
        });
      }
    }, () => {
      this.repeatOffsetY = distance;
    });
  }

  // Android: persistAnimationButton() — AnimatorSet with 5 repeats
  private animatePersistButton(): void {
    const duration = 750;
    const distance = this.TRANSLATION_DISTANCE;

    // Phase 1: translate down
    animateTo({
      duration: duration,
      curve: Curve.EaseInOut,
      onFinish: () => {
        // Phase 2: bounce 5 times then stop
        animateTo({
          duration: duration,
          curve: Curve.EaseInOut,
          iterations: 5,
          playMode: PlayMode.Alternate
        }, () => {
          this.persistOffsetY = -distance;
        });
      }
    }, () => {
      this.persistOffsetY = distance;
    });
  }

  // Android: randomAnimationButton() — Handler.postDelayed with random translationY
  // HarmonyOS: setInterval with animateTo
  private animateRandomButton(): void {
    // Stop any previous random animation
    if (this.randomTimerId !== -1) {
      clearInterval(this.randomTimerId);
    }

    const distance = this.TRANSLATION_DISTANCE;
    const animationDuration = 300; // matches ANIMATION_DURATION
    const delayTime = 250;         // matches DELAY_TIME_MS

    this.randomTimerId = setInterval(() => {
      // Random location between -distance and +distance
      const nextLocation = Math.random() * 2 * distance - distance;
      this.lastRandomLocation = nextLocation;

      animateTo({
        duration: animationDuration,
        curve: Curve.EaseInOut
      }, () => {
        this.randomOffsetY = nextLocation;
      });
    }, delayTime);
  }

  aboutToDisappear(): void {
    if (this.randomTimerId !== -1) {
      clearInterval(this.randomTimerId);
      this.randomTimerId = -1;
    }
  }

  build() {
    // Android: RelativeLayout with 3 buttons centered vertically
    Row() {
      Button('Repeat Animation')
        .onClick(() => this.animateRepeatButton())
        .translate({ y: this.repeatOffsetY })
        .margin({ right: 16 })

      Button('Persist Animation')
        .onClick(() => this.animatePersistButton())
        .translate({ y: this.persistOffsetY })
        .margin({ right: 16 })

      Button('Random Animation')
        .onClick(() => this.animateRandomButton())
        .translate({ y: this.randomOffsetY })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding(16)
  }
}
