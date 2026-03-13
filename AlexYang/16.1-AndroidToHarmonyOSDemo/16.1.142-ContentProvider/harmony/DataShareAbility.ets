// HarmonyOS ArkTS equivalent of Android CountryProvider (ContentProvider)
// Android: ContentProvider extends → HarmonyOS: DataShareExtensionAbility
// This file implements the data provider side (the server)

import { DataShareExtensionAbility } from '@kit.ArkData';
import { dataSharePredicates } from '@kit.ArkData';
import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Mirrors CountryContract columns
const TABLE_NAME: string = 'country';
const COLUMN_ID: string = '_id';
const COLUMN_NAME: string = 'country_name';
const COLUMN_CAPITAL: string = 'country_capital';
const COLUMN_POPULATION: string = 'country_population';
const COLUMN_AREA: string = 'country_area';
const COLUMN_LANG: string = 'country_lang';

// Mirrors CountryDatabase — SQLiteOpenHelper equivalent
const DB_NAME: string = 'country.db';
const DB_VERSION: number = 1;

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

// Mirrors CountryDatabase.onCreate CREATE TABLE + initial INSERTs
const SQL_CREATE_TABLE: string = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
  ${COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${COLUMN_NAME} TEXT NOT NULL,
  ${COLUMN_POPULATION} TEXT NOT NULL,
  ${COLUMN_CAPITAL} TEXT NOT NULL,
  ${COLUMN_AREA} TEXT NOT NULL,
  ${COLUMN_LANG} TEXT NOT NULL
)`;

const SQL_INSERT_INDIA: string = `INSERT INTO ${TABLE_NAME} (${COLUMN_NAME}, ${COLUMN_POPULATION}, ${COLUMN_CAPITAL}, ${COLUMN_AREA}, ${COLUMN_LANG})
  VALUES('India', '1.252 Billion', 'Delhi', '13,287,263 km Square', 'Hindi, English')`;

const SQL_INSERT_KOREA: string = `INSERT INTO ${TABLE_NAME} (${COLUMN_NAME}, ${COLUMN_POPULATION}, ${COLUMN_CAPITAL}, ${COLUMN_AREA}, ${COLUMN_LANG})
  VALUES('South Korea', '50,801,405', 'Seoul', '100,210 km Square', 'Korean')`;

// Android: CountryProvider extends ContentProvider
// HarmonyOS: CountryDataShare extends DataShareExtensionAbility
export default class CountryDataShare extends DataShareExtensionAbility {
  private rdbStore: relationalStore.RdbStore | null = null;

  // Android: ContentProvider.onCreate()
  // HarmonyOS: DataShareExtensionAbility.onCreate()
  async onCreate(want: Want, callback: Function): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
      await this.rdbStore.executeSql(SQL_CREATE_TABLE);

      // Check if data already exists, if not insert seed data
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      const resultSet = await this.rdbStore.query(predicates, [COLUMN_ID]);
      if (resultSet.rowCount === 0) {
        await this.rdbStore.executeSql(SQL_INSERT_INDIA);
        await this.rdbStore.executeSql(SQL_INSERT_KOREA);
      }
      resultSet.close();
    } catch (error) {
      console.error(`CountryDataShare onCreate error: ${JSON.stringify(error)}`);
    }
    callback();
  }

  // Android: ContentProvider.query(uri, projection, selection, selectionArgs, sortOrder)
  // HarmonyOS: query(uri, predicates, columns, callback)
  query(
    uri: string,
    predicates: dataSharePredicates.DataSharePredicates,
    columns: string[],
    callback: Function
  ): void {
    if (!this.rdbStore) {
      callback(new Error('Database not initialized'), null);
      return;
    }

    try {
      // Android: SQLiteQueryBuilder.query → HarmonyOS: rdbStore.query with RdbPredicates
      const rdbPredicates = relationalStore.RdbPredicates.convertFrom(TABLE_NAME, predicates);
      this.rdbStore.query(rdbPredicates, columns).then((resultSet) => {
        callback(null, resultSet);
      }).catch((error: BusinessError) => {
        console.error(`Query error: ${error.message}`);
        callback(error, null);
      });
    } catch (error) {
      callback(error, null);
    }
  }

  // Android: ContentProvider.insert(uri, contentValues) → returns Uri
  // HarmonyOS: insert(uri, valueBucket, callback) → returns rowId
  insert(uri: string, valueBucket: ValuesBucket, callback: Function): void {
    if (!this.rdbStore) {
      callback(new Error('Database not initialized'), -1);
      return;
    }

    try {
      // Android: db.insertOrThrow(TABLE, null, values)
      this.rdbStore.insert(TABLE_NAME, valueBucket).then((rowId: number) => {
        console.info(`Insert successful, rowId: ${rowId}`);
        callback(null, rowId);
      }).catch((error: BusinessError) => {
        console.error(`Insert error: ${error.message}`);
        callback(error, -1);
      });
    } catch (error) {
      callback(error, -1);
    }
  }

  // Android: ContentProvider.update(uri, contentValues, selection, selectionArgs)
  // HarmonyOS: update(uri, predicates, valueBucket, callback)
  update(
    uri: string,
    predicates: dataSharePredicates.DataSharePredicates,
    valueBucket: ValuesBucket,
    callback: Function
  ): void {
    if (!this.rdbStore) {
      callback(new Error('Database not initialized'), 0);
      return;
    }

    try {
      const rdbPredicates = relationalStore.RdbPredicates.convertFrom(TABLE_NAME, predicates);
      this.rdbStore.update(valueBucket, rdbPredicates).then((rows: number) => {
        console.info(`Update successful, affected rows: ${rows}`);
        callback(null, rows);
      }).catch((error: BusinessError) => {
        console.error(`Update error: ${error.message}`);
        callback(error, 0);
      });
    } catch (error) {
      callback(error, 0);
    }
  }

  // Android: ContentProvider.delete(uri, selection, selectionArgs)
  // HarmonyOS: delete(uri, predicates, callback)
  delete(
    uri: string,
    predicates: dataSharePredicates.DataSharePredicates,
    callback: Function
  ): void {
    if (!this.rdbStore) {
      callback(new Error('Database not initialized'), 0);
      return;
    }

    try {
      // Android: db.delete(TABLE, selectionCriteria, selectionArgs)
      const rdbPredicates = relationalStore.RdbPredicates.convertFrom(TABLE_NAME, predicates);
      this.rdbStore.delete(rdbPredicates).then((rows: number) => {
        console.info(`Delete successful, affected rows: ${rows}`);
        callback(null, rows);
      }).catch((error: BusinessError) => {
        console.error(`Delete error: ${error.message}`);
        callback(error, 0);
      });
    } catch (error) {
      callback(error, 0);
    }
  }

  // Android: ContentProvider.getType(uri) → MIME type
  // HarmonyOS: getType(uri, callback) → string
  getType(uri: string, callback: Function): void {
    // Android: UriMatcher to distinguish COUNTRY vs COUNTRY_ID
    if (uri.endsWith('/country')) {
      callback(null, 'vnd.android.cursor.dir/vnd.com.demo.contentprovider.country');
    } else {
      callback(null, 'vnd.android.cursor.item/vnd.com.demo.contentprovider.country');
    }
  }
}
