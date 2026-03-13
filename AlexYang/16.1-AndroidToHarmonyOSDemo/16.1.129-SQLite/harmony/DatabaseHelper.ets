// HarmonyOS ArkTS equivalent of Android SQLiteOpenHelper + DatabaseQueryClass
// Android: SQLiteDatabase/Cursor → HarmonyOS: relationalStore/ResultSet

import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

export interface Student {
  id: number;
  name: string;
  registrationNumber: number;
  phone: string;
  email: string;
}

const DATABASE_NAME: string = 'student-db.db';
const TABLE_STUDENT: string = 'student';
const COLUMN_ID: string = '_id';
const COLUMN_NAME: string = 'name';
const COLUMN_REG: string = 'registration_no';
const COLUMN_PHONE: string = 'phone';
const COLUMN_EMAIL: string = 'email';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DATABASE_NAME,
  securityLevel: relationalStore.SecurityLevel.S1,
};

const CREATE_TABLE_SQL: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_STUDENT} (` +
  `${COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT, ` +
  `${COLUMN_NAME} TEXT NOT NULL, ` +
  `${COLUMN_REG} INTEGER NOT NULL UNIQUE, ` +
  `${COLUMN_PHONE} TEXT, ` +
  `${COLUMN_EMAIL} TEXT)`;

export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null;

  async initialize(context: common.UIAbilityContext): Promise<void> {
    this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.rdbStore.executeSql(CREATE_TABLE_SQL);
  }

  async insertStudent(student: Student): Promise<number> {
    if (!this.rdbStore) return -1;
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'name': student.name,
        'registration_no': student.registrationNumber,
        'phone': student.phone,
        'email': student.email,
      };
      const rowId = await this.rdbStore.insert(TABLE_STUDENT, valueBucket);
      return rowId;
    } catch (err) {
      console.error('insertStudent failed: ' + (err as Error).message);
      return -1;
    }
  }

  async getAllStudents(): Promise<Student[]> {
    if (!this.rdbStore) return [];
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_STUDENT);
      const resultSet = await this.rdbStore.query(predicates);
      const students: Student[] = [];

      while (resultSet.goToNextRow()) {
        const student: Student = {
          id: resultSet.getLong(resultSet.getColumnIndex(COLUMN_ID)),
          name: resultSet.getString(resultSet.getColumnIndex(COLUMN_NAME)),
          registrationNumber: resultSet.getLong(resultSet.getColumnIndex(COLUMN_REG)),
          phone: resultSet.getString(resultSet.getColumnIndex(COLUMN_PHONE)),
          email: resultSet.getString(resultSet.getColumnIndex(COLUMN_EMAIL)),
        };
        students.push(student);
      }
      resultSet.close();
      return students;
    } catch (err) {
      console.error('getAllStudents failed: ' + (err as Error).message);
      return [];
    }
  }

  async getStudentByRegNo(regNo: number): Promise<Student | null> {
    if (!this.rdbStore) return null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_STUDENT);
      predicates.equalTo(COLUMN_REG, regNo);
      const resultSet = await this.rdbStore.query(predicates);

      if (resultSet.goToNextRow()) {
        const student: Student = {
          id: resultSet.getLong(resultSet.getColumnIndex(COLUMN_ID)),
          name: resultSet.getString(resultSet.getColumnIndex(COLUMN_NAME)),
          registrationNumber: resultSet.getLong(resultSet.getColumnIndex(COLUMN_REG)),
          phone: resultSet.getString(resultSet.getColumnIndex(COLUMN_PHONE)),
          email: resultSet.getString(resultSet.getColumnIndex(COLUMN_EMAIL)),
        };
        resultSet.close();
        return student;
      }
      resultSet.close();
      return null;
    } catch (err) {
      console.error('getStudentByRegNo failed: ' + (err as Error).message);
      return null;
    }
  }

  async updateStudent(student: Student): Promise<number> {
    if (!this.rdbStore) return 0;
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'name': student.name,
        'registration_no': student.registrationNumber,
        'phone': student.phone,
        'email': student.email,
      };
      const predicates = new relationalStore.RdbPredicates(TABLE_STUDENT);
      predicates.equalTo(COLUMN_ID, student.id);
      const rows = await this.rdbStore.update(valueBucket, predicates);
      return rows;
    } catch (err) {
      console.error('updateStudent failed: ' + (err as Error).message);
      return 0;
    }
  }

  async deleteStudentByRegNo(regNo: number): Promise<number> {
    if (!this.rdbStore) return 0;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_STUDENT);
      predicates.equalTo(COLUMN_REG, regNo);
      const rows = await this.rdbStore.delete(predicates);
      return rows;
    } catch (err) {
      console.error('deleteStudentByRegNo failed: ' + (err as Error).message);
      return 0;
    }
  }

  async deleteAllStudents(): Promise<boolean> {
    if (!this.rdbStore) return false;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_STUDENT);
      await this.rdbStore.delete(predicates);
      return true;
    } catch (err) {
      console.error('deleteAllStudents failed: ' + (err as Error).message);
      return false;
    }
  }
}
