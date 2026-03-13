// HarmonyOS ArkTS equivalent of Android Fragment demo (MainActivity + HelloFragment)
// Android: Fragment + FragmentManager → HarmonyOS: Navigation + NavPathStack + NavDestination

@Entry
@Component
struct FragmentDemoPage {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  @Builder
  routerMap(name: string, param: Object) {
    if (name === 'HelloFragment') {
      HelloFragmentPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Text('Fragment Demo')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 24 })

        // Equivalent of btnShowFragment
        Button('Show Fragment')
          .width('60%')
          .onClick(() => {
            // Equivalent of FragmentTransaction.replace + addToBackStack + commit
            this.navPathStack.pushPath({ name: 'HelloFragment' });
          })

        Text('Tap the button to navigate to a Fragment-equivalent page.')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 16 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .navDestination(this.routerMap)
    .title('Fragment Demo')
    .mode(NavigationMode.Stack)
  }
}

// ============================================================
// HelloFragmentPage - equivalent of Android HelloFragment
// Android: Fragment.onCreateView → HarmonyOS: @Component + NavDestination
// ============================================================
@Component
struct HelloFragmentPage {
  @Consume('navPathStack') navPathStack: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        // Equivalent of HelloFragment.onCreateView: TextView with "Hello from Fragment!"
        Text('Hello from Fragment!')
          .fontSize(20)
          .padding(32)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .title('Hello Fragment')
  }
}
