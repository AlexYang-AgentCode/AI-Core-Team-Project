// HarmonyOS ArkTS - Reusable sub-page component (Fragment equivalent)
// This demonstrates how to create reusable page components similar to Android Fragments
// that can be navigated to via NavPathStack.

@Component
export struct DemoPage {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @Prop title: string = 'Demo Page';
  @Prop content: string = 'This is a demo sub-page, equivalent to an Android Fragment.';

  build() {
    NavDestination() {
      Column() {
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text(this.content)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .padding(16)

        Button('Go Back')
          .margin({ top: 24 })
          .onClick(() => {
            // Equivalent of FragmentManager.popBackStack()
            this.navPathStack.pop();
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .title(this.title)
  }
}
