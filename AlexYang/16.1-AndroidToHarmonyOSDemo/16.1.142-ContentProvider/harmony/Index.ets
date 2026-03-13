// HarmonyOS ArkTS equivalent of Android ContentProvider demo — Main Page
// Android: ContentResolver.query/insert via ContentProvider
// HarmonyOS: dataShare.createDataShareHelper + query/insert

import { dataShare, dataSharePredicates, ValuesBucket } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

// Mirrors Country.java model
interface Country {
  id: number;
  name: string;
  capital: string;
  population: string;
  area: string;
  lang: string;
}

// Android: content://com.example.balraj.contentproviderapp.provider/country
// HarmonyOS: datashareproxy://com.demo.contentprovider/country
const DATA_SHARE_URI: string = 'datashareproxy://com.demo.contentprovider/country';

// Mirrors CountryContract.CountryColumns
const COLUMN_ID: string = '_id';
const COLUMN_NAME: string = 'country_name';
const COLUMN_CAPITAL: string = 'country_capital';
const COLUMN_POPULATION: string = 'country_population';
const COLUMN_AREA: string = 'country_area';
const COLUMN_LANG: string = 'country_lang';

@Entry
@Component
struct ContentProviderPage {
  @State countries: Country[] = [];
  @State showAddForm: boolean = false;
  @State newName: string = '';
  @State newCapital: string = '';
  @State newPopulation: string = '';
  @State newArea: string = '';
  @State newLang: string = '';
  @State statusText: string = '';

  private context: common.UIAbilityContext | undefined = undefined;
  private dataShareHelper: dataShare.DataShareHelper | undefined = undefined;

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.initDataShareHelper();
  }

  // Android: getContentResolver()
  // HarmonyOS: dataShare.createDataShareHelper(context, uri)
  private async initDataShareHelper(): Promise<void> {
    try {
      this.dataShareHelper = await dataShare.createDataShareHelper(this.context!, DATA_SHARE_URI);
      this.loadCountries();
    } catch (error) {
      this.statusText = `DataShare init error: ${(error as BusinessError).message}`;
      // For demo: load seed data locally if DataShareExtensionAbility is not available
      this.loadSeedData();
    }
  }

  // Seed data mirrors CountryDatabase.onCreate initial inserts
  private loadSeedData(): void {
    this.countries = [
      { id: 1, name: 'India', capital: 'Delhi', population: '1.252 Billion', area: '13,287,263 km Square', lang: 'Hindi, English' },
      { id: 2, name: 'South Korea', capital: 'Seoul', population: '50,801,405', area: '100,210 km Square', lang: 'Korean' }
    ];
  }

  // Android: ContentResolver.query(URI_TABLE, projection, selection, selectionArgs, sortOrder)
  // HarmonyOS: dataShareHelper.query(uri, predicates, columns)
  private async loadCountries(): Promise<void> {
    if (!this.dataShareHelper) {
      return;
    }
    try {
      // Android: new String[] { _ID, COUNTRY_NAME, ... }
      const columns: string[] = [COLUMN_ID, COLUMN_NAME, COLUMN_CAPITAL, COLUMN_POPULATION, COLUMN_AREA, COLUMN_LANG];

      // Android: ContentResolver.query(uri, projection, null, null, null)
      // HarmonyOS: dataShareHelper.query(uri, predicates, columns)
      const predicates = new dataSharePredicates.DataSharePredicates();
      const resultSet = await this.dataShareHelper.query(DATA_SHARE_URI, predicates, columns);

      const result: Country[] = [];
      // Android: cursor.moveToNext() → HarmonyOS: resultSet.goToNextRow()
      while (resultSet.goToNextRow()) {
        // Android: cursor.getInt(cursor.getColumnIndex("_id")) → resultSet.getLong
        // Android: cursor.getString(...) → resultSet.getString
        const country: Country = {
          id: resultSet.getLong(resultSet.getColumnIndex(COLUMN_ID)),
          name: resultSet.getString(resultSet.getColumnIndex(COLUMN_NAME)),
          capital: resultSet.getString(resultSet.getColumnIndex(COLUMN_CAPITAL)),
          population: resultSet.getString(resultSet.getColumnIndex(COLUMN_POPULATION)),
          area: resultSet.getString(resultSet.getColumnIndex(COLUMN_AREA)),
          lang: resultSet.getString(resultSet.getColumnIndex(COLUMN_LANG))
        };
        result.push(country);
      }
      resultSet.close();
      this.countries = result;
    } catch (error) {
      this.statusText = `Query error: ${(error as BusinessError).message}`;
      this.loadSeedData();
    }
  }

  // Android: ContentResolver.insert(URI_TABLE, contentValues) from AddActivity
  // HarmonyOS: dataShareHelper.insert(uri, valueBucket)
  private async addCountry(): Promise<void> {
    if (this.newName.length === 0) {
      promptAction.showToast({ message: 'Please ensure you have entered some valid data.' });
      return;
    }

    // Android: ContentValues → HarmonyOS: ValuesBucket
    const valueBucket: ValuesBucket = {
      'country_name': this.newName,
      'country_capital': this.newCapital,
      'country_population': this.newPopulation,
      'country_area': this.newArea,
      'country_lang': this.newLang
    };

    if (this.dataShareHelper) {
      try {
        await this.dataShareHelper.insert(DATA_SHARE_URI, valueBucket);
        this.statusText = 'Record inserted';
        await this.loadCountries();
      } catch (error) {
        this.statusText = `Insert error: ${(error as BusinessError).message}`;
        // Fallback: add locally for demo
        this.addCountryLocally();
      }
    } else {
      this.addCountryLocally();
    }

    this.clearForm();
    this.showAddForm = false;
  }

  private addCountryLocally(): void {
    const newId = this.countries.length > 0
      ? Math.max(...this.countries.map(c => c.id)) + 1
      : 1;
    this.countries = [...this.countries, {
      id: newId,
      name: this.newName,
      capital: this.newCapital,
      population: this.newPopulation,
      area: this.newArea,
      lang: this.newLang
    }];
  }

  // Android: ContentResolver.delete(uri, selection, selectionArgs)
  // HarmonyOS: dataShareHelper.delete(uri, predicates)
  private async deleteCountry(country: Country): Promise<void> {
    if (this.dataShareHelper) {
      try {
        const predicates = new dataSharePredicates.DataSharePredicates();
        predicates.equalTo(COLUMN_ID, country.id);
        await this.dataShareHelper.delete(DATA_SHARE_URI, predicates);
        await this.loadCountries();
      } catch (error) {
        this.statusText = `Delete error: ${(error as BusinessError).message}`;
        this.countries = this.countries.filter(c => c.id !== country.id);
      }
    } else {
      this.countries = this.countries.filter(c => c.id !== country.id);
    }
  }

  private clearForm(): void {
    this.newName = '';
    this.newCapital = '';
    this.newPopulation = '';
    this.newArea = '';
    this.newLang = '';
  }

  build() {
    Column() {
      // Title bar with Add button — mirrors onOptionsItemSelected(R.id.add)
      Row() {
        Text('Countries')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Button('+ Add')
          .onClick(() => {
            this.showAddForm = !this.showAddForm;
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 16, right: 16 })

      if (this.statusText.length > 0) {
        Text(this.statusText)
          .fontSize(12)
          .fontColor('#FF6600')
          .padding({ left: 16, right: 16 })
      }

      // Add form — mirrors AddActivity / add_edit.xml
      if (this.showAddForm) {
        Column() {
          TextInput({ placeholder: 'Country Name' })
            .onChange((value: string) => { this.newName = value; })
            .margin({ bottom: 8 })

          TextInput({ placeholder: 'Capital' })
            .onChange((value: string) => { this.newCapital = value; })
            .margin({ bottom: 8 })

          TextInput({ placeholder: 'Population' })
            .onChange((value: string) => { this.newPopulation = value; })
            .margin({ bottom: 8 })

          TextInput({ placeholder: 'Area' })
            .onChange((value: string) => { this.newArea = value; })
            .margin({ bottom: 8 })

          TextInput({ placeholder: 'Language' })
            .onChange((value: string) => { this.newLang = value; })
            .margin({ bottom: 8 })

          // Android: saveButton onClick → ContentResolver.insert
          Button('Save')
            .width('100%')
            .onClick(() => this.addCountry())
        }
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ left: 16, right: 16, bottom: 8 })
      }

      // Country list — mirrors CountryListFragment with CountryCustomAdapter
      List({ space: 4 }) {
        ForEach(this.countries, (country: Country) => {
          ListItem() {
            // Mirrors custom_country.xml layout
            Column() {
              Text(country.name)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
              Text(`Capital: ${country.capital}`)
                .fontSize(14)
                .fontColor('#555555')
                .margin({ top: 4 })
              Text(`Population: ${country.population}`)
                .fontSize(14)
                .fontColor('#555555')
              Text(`Area: ${country.area}`)
                .fontSize(14)
                .fontColor('#555555')
              Text(`Language: ${country.lang}`)
                .fontSize(14)
                .fontColor('#555555')
            }
            .width('100%')
            .padding(12)
            .alignItems(HorizontalAlign.Start)
          }
          .swipeAction({
            end: this.deleteButton(country)
          })
        }, (country: Country) => country.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#EEEEEE' })
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  deleteButton(country: Country) {
    Button('Delete')
      .backgroundColor(Color.Red)
      .fontColor(Color.White)
      .onClick(() => this.deleteCountry(country))
  }
}
