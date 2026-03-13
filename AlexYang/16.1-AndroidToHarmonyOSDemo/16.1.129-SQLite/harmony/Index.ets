// HarmonyOS ArkTS equivalent of Android SQLite Student CRUD demo
// Android: SQLiteDatabase → HarmonyOS: @ohos.data.relationalStore

import relationalStore from '@ohos.data.relationalStore';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper, Student } from './DatabaseHelper';

@Entry
@Component
struct StudentListPage {
  @State studentList: Student[] = [];
  @State showCreateDialog: boolean = false;
  @State newName: string = '';
  @State newRegNo: string = '';
  @State newPhone: string = '';
  @State newEmail: string = '';
  @State showUpdateDialog: boolean = false;
  @State editIndex: number = -1;
  @State editName: string = '';
  @State editRegNo: string = '';
  @State editPhone: string = '';
  @State editEmail: string = '';

  private dbHelper: DatabaseHelper = new DatabaseHelper();

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initialize(getContext(this));
    await this.refreshList();
  }

  async refreshList(): Promise<void> {
    this.studentList = await this.dbHelper.getAllStudents();
  }

  async addStudent(): Promise<void> {
    if (!this.newName || !this.newRegNo) {
      promptAction.showToast({ message: 'Name and Registration are required' });
      return;
    }
    const student: Student = {
      id: -1,
      name: this.newName,
      registrationNumber: parseInt(this.newRegNo),
      phone: this.newPhone,
      email: this.newEmail,
    };
    const id = await this.dbHelper.insertStudent(student);
    if (id >= 0) {
      this.showCreateDialog = false;
      this.newName = '';
      this.newRegNo = '';
      this.newPhone = '';
      this.newEmail = '';
      await this.refreshList();
    } else {
      promptAction.showToast({ message: 'Insert failed (duplicate registration?)' });
    }
  }

  async updateStudent(): Promise<void> {
    if (this.editIndex < 0) return;
    const original = this.studentList[this.editIndex];
    const student: Student = {
      id: original.id,
      name: this.editName,
      registrationNumber: parseInt(this.editRegNo),
      phone: this.editPhone,
      email: this.editEmail,
    };
    const rows = await this.dbHelper.updateStudent(student);
    if (rows > 0) {
      this.showUpdateDialog = false;
      await this.refreshList();
    } else {
      promptAction.showToast({ message: 'Update failed' });
    }
  }

  async deleteStudent(regNo: number): Promise<void> {
    const rows = await this.dbHelper.deleteStudentByRegNo(regNo);
    if (rows > 0) {
      await this.refreshList();
    }
  }

  async deleteAll(): Promise<void> {
    await this.dbHelper.deleteAllStudents();
    await this.refreshList();
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('Student Database')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button('Delete All')
          .fontSize(14)
          .backgroundColor(Color.Red)
          .fontColor(Color.White)
          .onClick(() => {
            AlertDialog.show({
              title: 'Confirm',
              message: 'Are you sure you want to delete all students?',
              primaryButton: {
                value: 'Yes',
                action: () => {
                  this.deleteAll();
                }
              },
              secondaryButton: {
                value: 'No',
                action: () => {}
              }
            });
          })
      }
      .width('100%')
      .padding(12)

      // Student list or empty message
      if (this.studentList.length === 0) {
        Text('No students found. Tap + to add.')
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ top: 40 })
      } else {
        List() {
          ForEach(this.studentList, (student: Student, index: number) => {
            ListItem() {
              Column() {
                Text(student.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                Text('Reg: ' + student.registrationNumber)
                  .fontSize(14)
                  .fontColor(Color.Gray)
                if (student.phone) {
                  Text('Phone: ' + student.phone)
                    .fontSize(14)
                }
                if (student.email) {
                  Text('Email: ' + student.email)
                    .fontSize(14)
                }
                Row() {
                  Button('Edit')
                    .fontSize(12)
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.editIndex = index as number;
                      this.editName = student.name;
                      this.editRegNo = student.registrationNumber.toString();
                      this.editPhone = student.phone || '';
                      this.editEmail = student.email || '';
                      this.showUpdateDialog = true;
                    })
                  Button('Delete')
                    .fontSize(12)
                    .backgroundColor(Color.Red)
                    .fontColor(Color.White)
                    .onClick(() => {
                      this.deleteStudent(student.registrationNumber);
                    })
                }
                .margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(12)
              .width('100%')
            }
          }, (student: Student) => student.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#EEEEEE' })
      }

      // Floating action button
      Button('+')
        .width(56)
        .height(56)
        .borderRadius(28)
        .fontSize(24)
        .position({ x: '80%', y: '85%' })
        .onClick(() => {
          this.showCreateDialog = true;
        })

      // Create student dialog
      if (this.showCreateDialog) {
        Column() {
          Text('Create Student')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })
          TextInput({ placeholder: 'Name *', text: this.newName })
            .width('100%')
            .margin({ bottom: 8 })
            .onChange((v: string) => { this.newName = v; })
          TextInput({ placeholder: 'Registration No *', text: this.newRegNo })
            .width('100%')
            .margin({ bottom: 8 })
            .type(InputType.Number)
            .onChange((v: string) => { this.newRegNo = v; })
          TextInput({ placeholder: 'Phone', text: this.newPhone })
            .width('100%')
            .margin({ bottom: 8 })
            .onChange((v: string) => { this.newPhone = v; })
          TextInput({ placeholder: 'Email', text: this.newEmail })
            .width('100%')
            .margin({ bottom: 8 })
            .onChange((v: string) => { this.newEmail = v; })
          Row() {
            Button('Cancel')
              .margin({ right: 12 })
              .onClick(() => { this.showCreateDialog = false; })
            Button('Create')
              .onClick(() => { this.addStudent(); })
          }
        }
        .width('80%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 8, color: '#33000000' })
        .position({ x: '10%', y: '20%' })
      }

      // Update student dialog
      if (this.showUpdateDialog) {
        Column() {
          Text('Update Student')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })
          TextInput({ placeholder: 'Name *', text: this.editName })
            .width('100%')
            .margin({ bottom: 8 })
            .onChange((v: string) => { this.editName = v; })
          TextInput({ placeholder: 'Registration No *', text: this.editRegNo })
            .width('100%')
            .margin({ bottom: 8 })
            .type(InputType.Number)
            .onChange((v: string) => { this.editRegNo = v; })
          TextInput({ placeholder: 'Phone', text: this.editPhone })
            .width('100%')
            .margin({ bottom: 8 })
            .onChange((v: string) => { this.editPhone = v; })
          TextInput({ placeholder: 'Email', text: this.editEmail })
            .width('100%')
            .margin({ bottom: 8 })
            .onChange((v: string) => { this.editEmail = v; })
          Row() {
            Button('Cancel')
              .margin({ right: 12 })
              .onClick(() => { this.showUpdateDialog = false; })
            Button('Update')
              .onClick(() => { this.updateStudent(); })
          }
        }
        .width('80%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 8, color: '#33000000' })
        .position({ x: '10%', y: '20%' })
      }
    }
    .width('100%')
    .height('100%')
  }
}
