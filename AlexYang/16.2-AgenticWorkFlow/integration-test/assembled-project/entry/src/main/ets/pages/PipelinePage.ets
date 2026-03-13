/**
 * PipelinePage - Visual representation of the APK adaptation pipeline
 * Shows how Calculator.apk flows through each bridge layer
 */
import { router } from '@kit.ArkUI';

interface PipelineNode {
  layer: string;
  project: string;
  input: string;
  output: string;
  tech: string;
  color: string;
}

@Entry
@Component
struct PipelinePage {
  @State nodes: PipelineNode[] = [
    {
      layer: 'Android APK',
      project: '16.1',
      input: 'Calculator.apk',
      output: 'classes.dex (DEX bytecode)',
      tech: 'Java → DEX',
      color: '#4CAF50'
    },
    {
      layer: 'JIT Converter',
      project: '16.4.1',
      input: 'classes.dex',
      output: 'ABC bytecode (ArkCompiler)',
      tech: 'DEX Parser → IR → ABC Generator',
      color: '#FF9800'
    },
    {
      layer: 'Activity Bridge',
      project: '16.4.2',
      input: 'Activity lifecycle calls',
      output: 'UIAbility lifecycle',
      tech: 'AppCompatActivity → UIAbility mapping',
      color: '#2196F3'
    },
    {
      layer: 'View Bridge',
      project: '16.4.3',
      input: 'Android View/Widget APIs',
      output: 'ArkUI Components',
      tech: 'Button→Button, TextView→Text, Layout→Column/Row',
      color: '#9C27B0'
    },
    {
      layer: 'System Bridge',
      project: '16.4.4',
      input: 'Android system APIs + 3rd party libs',
      output: 'HarmonyOS native APIs',
      tech: 'Rhino→ExprEval, Toast→showToast, Log→hilog',
      color: '#F44336'
    },
    {
      layer: 'HarmonyOS Emulator',
      project: 'DevEco',
      input: 'Assembled HarmonyOS App',
      output: 'Calculator running on screen',
      tech: 'HarmonyOS 6.0.1 Emulator',
      color: '#009688'
    }
  ];

  build() {
    Column() {
      Row() {
        Text('◀')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .onClick(() => router.back())
          .padding({ left: 16 })
        Text('Adaptation Pipeline')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(' ')
          .padding({ right: 16 })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#1565C0')

      // Pipeline diagram
      Scroll() {
        Column() {
          ForEach(this.nodes, (node: PipelineNode, idx: number) => {
            // Node card
            Column() {
              // Header
              Row() {
                Text(node.project)
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .backgroundColor(node.color)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(10)
                Text(node.layer)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121')
                  .margin({ left: 8 })
              }
              .width('100%')

              // Input/Output
              Row() {
                Column() {
                  Text('IN')
                    .fontSize(9)
                    .fontColor('#9E9E9E')
                  Text(node.input)
                    .fontSize(11)
                    .fontColor('#616161')
                    .maxLines(2)
                }
                .layoutWeight(1)
                .padding(4)

                Text('→')
                  .fontSize(18)
                  .fontColor(node.color)

                Column() {
                  Text('OUT')
                    .fontSize(9)
                    .fontColor('#9E9E9E')
                  Text(node.output)
                    .fontSize(11)
                    .fontColor('#616161')
                    .maxLines(2)
                }
                .layoutWeight(1)
                .padding(4)
              }
              .width('100%')
              .margin({ top: 4 })

              // Tech detail
              Text(node.tech)
                .fontSize(10)
                .fontColor('#9E9E9E')
                .fontFamily('monospace')
                .margin({ top: 4 })
                .width('100%')
            }
            .width('90%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor(node.color)
            .margin({ top: 8 })
            .shadow({ radius: 2, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 1 })

            // Arrow between nodes
            if (idx < this.nodes.length - 1) {
              Text('▼')
                .fontSize(20)
                .fontColor(node.color)
                .margin({ top: 4 })
            }
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
