// HarmonyOS ArkTS equivalent of Android HttpURLConnection weather demo
// Android: HttpURLConnection + AsyncTask → HarmonyOS: @ohos.net.http + async/await

import http from '@ohos.net.http';

interface WeatherDay {
  weather: Array<{ main: string }>;
  temp: { max: number; min: number };
}

interface ForecastResponse {
  list: WeatherDay[];
}

@Entry
@Component
struct HttpNetworkPage {
  @State weatherJson: string = '';
  @State parsedWeather: string[] = [];
  @State isLoading: boolean = false;

  private readonly API_URL: string =
    'http://api.openweathermap.org/data/2.5/forecast/daily?q=94043&mode=json&units=metric&cnt=7&appid=2de143494c0b295cca9337e1e96b00e0';

  async fetchWeatherData(): Promise<void> {
    this.isLoading = true;
    this.weatherJson = '';
    this.parsedWeather = [];

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(this.API_URL, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
        },
        connectTimeout: 10000,
        readTimeout: 10000,
      });

      if (response.responseCode === http.ResponseCode.OK) {
        const result = response.result as string;
        this.weatherJson = result;
        this.parseWeatherJson(result);
      } else {
        this.weatherJson = 'HTTP Error: ' + response.responseCode;
      }
    } catch (err) {
      this.weatherJson = 'Request failed: ' + (err as Error).message;
    } finally {
      httpRequest.destroy();
      this.isLoading = false;
    }
  }

  private parseWeatherJson(jsonStr: string): void {
    try {
      const forecast: ForecastResponse = JSON.parse(jsonStr) as ForecastResponse;
      const results: string[] = [];
      const list = forecast.list;

      for (let i = 0; i < list.length; i++) {
        const dayForecast = list[i];
        const description = dayForecast.weather[0].main;
        const high = Math.round(dayForecast.temp.max);
        const low = Math.round(dayForecast.temp.min);
        results.push(`day ${i}, ${description} - ${high}/${low}`);
      }

      this.parsedWeather = results;
    } catch (err) {
      console.error('JSON parse error: ' + (err as Error).message);
    }
  }

  build() {
    Column() {
      Text('Weather Forecast Demo')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Button(this.isLoading ? 'Fetching...' : 'Fetch Weather Data')
        .enabled(!this.isLoading)
        .onClick(() => {
          this.fetchWeatherData();
        })

      if (this.parsedWeather.length > 0) {
        Text('Parsed Forecast:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 8 })

        ForEach(this.parsedWeather, (item: string) => {
          Text(item)
            .fontSize(14)
            .margin({ bottom: 4 })
        })
      }

      if (this.weatherJson) {
        Text('Raw JSON Response:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 8 })

        Scroll() {
          Text(this.weatherJson)
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }
}
