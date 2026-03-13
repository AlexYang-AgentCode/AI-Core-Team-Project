// HarmonyOS ArkTS equivalent of Android WebView demo
// Android: android.webkit.WebView → HarmonyOS: Web component + @ohos.web.webview

import web_webview from '@ohos.web.webview';

@Entry
@Component
struct WebViewPage {
  @State urlInput: string = 'https://developer.harmonyos.com';
  @State currentUrl: string = 'https://developer.harmonyos.com';
  @State pageTitle: string = '';
  @State isLoading: boolean = false;
  @State loadProgress: number = 0;

  private webController: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
      // URL input bar
      Row() {
        TextInput({ text: this.urlInput })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.urlInput = value;
          })
          .onSubmit(() => {
            this.navigateToUrl();
          })

        Button('Go')
          .margin({ left: 8 })
          .onClick(() => {
            this.navigateToUrl();
          })
      }
      .width('100%')
      .padding(8)

      // Loading progress bar
      if (this.isLoading) {
        Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(3)
      }

      // Web component - equivalent of Android WebView
      Web({ src: this.currentUrl, controller: this.webController })
        .layoutWeight(1)
        .width('100%')
        // Equivalent of webSettings.setJavaScriptEnabled(true)
        .javaScriptAccess(true)
        // Equivalent of WebViewClient.onPageStarted
        .onPageBegin((event) => {
          this.isLoading = true;
          if (event?.url) {
            this.currentUrl = event.url;
            this.urlInput = event.url;
          }
        })
        // Equivalent of WebViewClient.onPageFinished
        .onPageEnd((event) => {
          this.isLoading = false;
          this.loadProgress = 100;
        })
        // Equivalent of WebChromeClient.onProgressChanged
        .onProgressChange((event) => {
          if (event?.newProgress !== undefined) {
            this.loadProgress = event.newProgress;
          }
        })
        // Equivalent of WebViewClient.onReceivedError
        .onErrorReceive((event) => {
          console.error('Web error: ' + JSON.stringify(event?.error));
        })
        .onTitleReceive((event) => {
          if (event?.title) {
            this.pageTitle = event.title;
          }
        })

      // Navigation bar at bottom
      Row() {
        Button('<')
          .width(48)
          .onClick(() => {
            // Equivalent of webView.goBack()
            try {
              if (this.webController.accessBackward()) {
                this.webController.backward();
              }
            } catch (err) {
              console.error('Backward error: ' + (err as Error).message);
            }
          })

        Button('>')
          .width(48)
          .margin({ left: 8 })
          .onClick(() => {
            // Equivalent of webView.goForward()
            try {
              if (this.webController.accessForward()) {
                this.webController.forward();
              }
            } catch (err) {
              console.error('Forward error: ' + (err as Error).message);
            }
          })

        Button('Reload')
          .margin({ left: 8 })
          .onClick(() => {
            try {
              this.webController.refresh();
            } catch (err) {
              console.error('Refresh error: ' + (err as Error).message);
            }
          })

        Text(this.pageTitle)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(8)
    }
    .width('100%')
    .height('100%')
  }

  private navigateToUrl(): void {
    let url = this.urlInput.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    try {
      this.webController.loadUrl(url);
      this.currentUrl = url;
    } catch (err) {
      console.error('loadUrl error: ' + (err as Error).message);
    }
  }
}
