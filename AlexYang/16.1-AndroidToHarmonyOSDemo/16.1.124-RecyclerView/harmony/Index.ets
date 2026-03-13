// HarmonyOS ArkTS equivalent of Android RecyclerView demo
// Android: RecyclerView + Adapter + ViewHolder + LinearLayoutManager
// HarmonyOS: List + ForEach with @Builder item rendering

@Entry
@Component
struct RecyclerViewPage {
  @State items: string[] = [
    'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry',
    'Fig', 'Grape', 'Honeydew', 'Kiwi', 'Lemon'
  ]

  @Builder
  ItemView(item: string) {
    Text(item)
      .fontSize(18)
      .width('100%')
      .padding({ left: 32, top: 24, right: 32, bottom: 24 })
  }

  build() {
    Column() {
      List() {
        ForEach(this.items, (item: string, index: number) => {
          ListItem() {
            this.ItemView(item)
          }
        }, (item: string, index: number) => index.toString())
      }
      .width('100%')
      .height('100%')
      .divider({
        strokeWidth: 1,
        color: '#EEEEEE',
        startMargin: 32,
        endMargin: 32
      })
    }
    .width('100%')
    .height('100%')
  }
}
