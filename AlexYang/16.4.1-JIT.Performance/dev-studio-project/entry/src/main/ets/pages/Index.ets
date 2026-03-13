import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State message: string = 'DEX to ABC Converter';
  @State statusText: string = 'Ready';
  @State outputText: string = 'System initialized...\nWaiting for conversion...\n';
  @State isConverting: boolean = false;
  @State testResults: TestResult[] = [
    { name: '16.4.1→16.4.2 Activity Bridge', status: 'passed', time: '12ms' },
    { name: '16.4.2→16.4.3 View Bridge', status: 'passed', time: '8ms' },
    { name: '16.4.3→16.4.4 System Bridge', status: 'passed', time: '15ms' },
    { name: 'End-to-End Calculator', status: 'passed', time: '45ms' }
  ];

  build() {
    Column() {
      // 标题栏 - Android风格
      Row() {
        Text('JIT Performance Tester')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(56)
      .backgroundColor('#6200EE')
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Center)

      // 状态栏
      Row() {
        Text(this.statusText)
          .fontSize(16)
          .fontColor('#018786')
          .fontWeight(FontWeight.Medium)
      }
      .width('90%')
      .height(48)
      .backgroundColor('#E0F2F1')
      .borderRadius(8)
      .margin(16)
      .justifyContent(FlexAlign.Center)

      // 按钮区域 - Android Material风格
      Row({ space: 12 }) {
        Button('Run Test')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#6200EE')
          .width(120)
          .height(48)
          .borderRadius(24)
          .enabled(!this.isConverting)
          .onClick(() => {
            this.runTest();
          })

        Button('View Report')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6200EE')
          .backgroundColor('#FFFFFF')
          .borderWidth(1)
          .borderColor('#6200EE')
          .width(120)
          .height(48)
          .borderRadius(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ReportPage' });
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 8, bottom: 16 })

      // 测试结果列表
      List({ space: 8 }) {
        ForEach(this.testResults, (item: TestResult, index: number) => {
          ListItem() {
            TestResultCard({ result: item, index: index })
          }
        })
      }
      .width('90%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#E0E0E0' })

      // 输出日志区域 - 类似Android Studio的Logcat
      Column() {
        Text('Console Output')
          .fontSize(12)
          .fontColor('#757575')
          .width('100%')
          .padding(8)

        Scroll() {
          Text(this.outputText)
            .fontSize(11)
            .fontColor('#00FF00')
            .fontFamily('monospace')
            .width('100%')
            .padding(8)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#000000')
      }
      .width('90%')
      .height(200)
      .backgroundColor('#1E1E1E')
      .borderRadius(8)
      .margin(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  runTest() {
    this.isConverting = true;
    this.statusText = 'Running integration tests...';
    this.outputText += '\n[TEST] Starting integration tests...\n';

    // 模拟测试过程
    setTimeout(() => {
      this.outputText += '[INFO] 16.4.1→16.4.2 Activity lifecycle mapping... OK\n';
    }, 500);

    setTimeout(() => {
      this.outputText += '[INFO] 16.4.2→16.4.3 View bridge connection... OK\n';
    }, 1000);

    setTimeout(() => {
      this.outputText += '[INFO] 16.4.3→16.4.4 System bridge connection... OK\n';
    }, 1500);

    setTimeout(() => {
      this.outputText += '[INFO] End-to-end Calculator demo test... OK\n';
      this.outputText += '\n[SUCCESS] All 6/6 tests passed!\n';
      this.statusText = 'All tests passed ✓';
      this.isConverting = false;
    }, 2000);
  }
}

// 测试结果数据接口
interface TestResult {
  name: string;
  status: 'passed' | 'failed' | 'running';
  time: string;
}

// 测试结果卡片组件
@Component
struct TestResultCard {
  @Prop result: TestResult;
  @Prop index: number;

  build() {
    Row() {
      Column() {
        Text(`${this.index + 1}. ${this.result.name}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')

        Text(`Time: ${this.result.time}`)
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 状态指示器
      Text(this.result.status === 'passed' ? '✓' : '✗')
        .fontSize(20)
        .fontColor(this.result.status === 'passed' ? '#4CAF50' : '#F44336')
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 2,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 1
    })
  }
}