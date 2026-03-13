import { router } from '@kit.ArkUI';

@Entry
@Component
struct ReportPage {
  @State integrationResults: IntegrationResult[] = [
    {
      module: '16.4.1 → 16.4.2',
      name: 'Activity Bridge',
      tests: 2,
      passed: 2,
      failed: 0,
      status: 'success'
    },
    {
      module: '16.4.2 → 16.4.3',
      name: 'View Bridge',
      tests: 2,
      passed: 2,
      failed: 0,
      status: 'success'
    },
    {
      module: '16.4.3 → 16.4.4',
      name: 'System Bridge',
      tests: 1,
      passed: 1,
      failed: 0,
      status: 'success'
    },
    {
      module: 'E2E Test',
      name: 'Calculator Demo',
      tests: 1,
      passed: 1,
      failed: 0,
      status: 'success'
    }
  ];

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('< Back')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })

        Text('Integration Report')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(60)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#6200EE')
      .padding({ left: 8, right: 16 })

      // 汇总卡片
      Column({ space: 12 }) {
        Text('Test Summary')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')

        Row({ space: 24 }) {
          SummaryItem({ label: 'Total', value: '6', color: '#212121' })
          SummaryItem({ label: 'Passed', value: '6', color: '#4CAF50' })
          SummaryItem({ label: 'Failed', value: '0', color: '#F44336' })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })

        Text('✓ All integration tests passed!')
          .fontSize(14)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin(16)
      .shadow({
        radius: 4,
        color: 'rgba(0,0,0,0.1)',
        offsetX: 0,
        offsetY: 2
      })

      // 详细结果列表
      Text('Detailed Results')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .width('90%')
        .margin({ left: 16, right: 16, bottom: 8 })

      List({ space: 8 }) {
        ForEach(this.integrationResults, (item: IntegrationResult) => {
          ListItem() {
            IntegrationResultCard({ result: item })
          }
        })
      }
      .width('90%')
      .layoutWeight(1)

      // 导出按钮
      Button('Export Report')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor('#6200EE')
        .width('90%')
        .height(48)
        .borderRadius(24)
        .margin(16)
        .onClick(() => {
          // 导出报告逻辑
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// 汇总项组件
@Component
struct SummaryItem {
  @Prop label: string;
  @Prop value: string;
  @Prop color: string;

  build() {
    Column({ space: 4 }) {
      Text(this.value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)

      Text(this.label)
        .fontSize(12)
        .fontColor('#757575')
    }
  }
}

// 集成结果卡片组件
@Component
struct IntegrationResultCard {
  @Prop result: IntegrationResult;

  build() {
    Row() {
      Column() {
        Text(this.result.module)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')

        Text(this.result.name)
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(`${this.result.passed}/${this.result.tests}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4CAF50')

          Text('passed')
            .fontSize(12)
            .fontColor('#757575')
        }

        if (this.result.failed > 0) {
          Row({ space: 8 }) {
            Text(`${this.result.failed}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#F44336')

            Text('failed')
              .fontSize(12)
              .fontColor('#757575')
          }
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height(72)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 2,
      color: 'rgba(0,0,0,0.08)',
      offsetX: 0,
      offsetY: 1
    })
  }
}

// 数据结构
interface IntegrationResult {
  module: string;
  name: string;
  tests: number;
  passed: number;
  failed: number;
  status: string;
}