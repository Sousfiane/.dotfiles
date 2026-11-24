pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// current weather from Open-Meteo (no API key). The place comes from Config.weatherLocation (a city name,
// looked up once with Open-Meteo's geocoding), or from the IP address when that is empty.
// A failed fetch is retried after 2 minutes, then less and less often, and as soon as the network is back.
Singleton {
    id: root

    property bool ready: false              // at least one successful fetch

    property int temp: 0                    // °C
    property int feelsLike: 0
    property int high: 0                    // today's max / min
    property int low: 0
    property string desc: ""
    property string area: ""
    property int code: 0                    // WMO weather code
    property bool night: false

    readonly property string icon: iconFor(code, night)

    property bool failed: false             // the last attempt didn't get through
    property real fetchedAt: 0              // ms since epoch of the last good result

    function refresh() {
        if (locatedFor === Config.weatherLocation)
            forecast.refresh();
        else
            locate();
    }

    // refresh when the data is older than `maxAgeMin` (default 10), used when the hub or the lockscreen opens
    function refreshIfStale(maxAgeMin) {
        if (Date.now() - fetchedAt > (maxAgeMin ?? 10) * 60 * 1000)
            refresh();
    }

    Component.onCompleted: refresh()

    // ---------- where ----------

    property real lat: 0
    property real lon: 0
    property string locatedFor: "\u0000"    // the Config.weatherLocation that lat / lon are for (never at first)

    function locate() {
        const place = Config.weatherLocation.trim();
        locator.command = place !== "" ? ["curl", "-sf", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&name=" + encodeURIComponent(place)] : ["curl", "-sf", "--max-time", "10", "https://ipwho.is/"];
        locator.running = false;
        locator.running = true;
    }

    Process {
        id: locator
        property string place: Config.weatherLocation    // what this run was started for

        onStarted: place = Config.weatherLocation

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const hit = d.results?.[0] ?? (d.success ? d : null);       // geocoding, or ipwho.is
                    if (!hit || hit.latitude === undefined)
                        throw "no place";
                    root.lat = hit.latitude;
                    root.lon = hit.longitude;
                    root.area = hit.name ?? hit.city ?? "";
                    root.locatedFor = locator.place;
                    forecast.refresh();
                } catch (e) {
                    root.fail();
                }
            }
        }

        onExited: code => {
            if (code !== 0)
                root.fail();
        }
    }

    // ---------- the weather ----------

    PolledProcess {
        id: forecast
        interval: 30 * 60 * 1000            // every 30 minutes
        command: ["curl", "-sf", "--max-time", "10", `https://api.open-meteo.com/v1/forecast?latitude=${root.lat}&longitude=${root.lon}` + "&current=temperature_2m,apparent_temperature,weather_code,is_day" + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current;
                    root.temp = Math.round(c.temperature_2m);
                    root.feelsLike = Math.round(c.apparent_temperature);
                    root.code = c.weather_code;
                    root.night = c.is_day === 0;
                    root.desc = root.describe(c.weather_code);
                    root.high = Math.round(d.daily.temperature_2m_max[0]);
                    root.low = Math.round(d.daily.temperature_2m_min[0]);

                    root.fetchedAt = forecast.fetchedAt = Date.now();
                    root.ready = true;
                    root.failed = false;
                    retry.delay = retry.first;
                } catch (e) {
                    // keep the last good data
                    root.fail();
                }
            }
        }

        onExited: code => {
            if (code !== 0)
                root.fail();
        }
    }

    // ---------- when it doesn't get through ----------

    function fail() {
        failed = true;
        if (!retry.running)
            retry.start();
    }

    // 2, 4, 8, 16 minutes, then every 30 like the normal refresh
    Timer {
        id: retry
        readonly property int first: 2 * 60 * 1000
        property int delay: first
        interval: delay
        onTriggered: {
            delay = Math.min(delay * 2, 30 * 60 * 1000);
            root.refresh();
        }
    }

    // back online: no need to wait for the next retry
    Connections {
        target: Net
        function onOnlineChanged() {
            if (Net.online && (root.failed || !root.ready)) {
                retry.stop();
                root.refresh();
            }
        }
    }

    // ---------- WMO weather codes ----------

    function describe(c) {
        const names = {
            0: "Clear sky",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",
            45: "Fog",
            48: "Freezing fog",
            51: "Light drizzle",
            53: "Drizzle",
            55: "Heavy drizzle",
            56: "Freezing drizzle",
            57: "Freezing drizzle",
            61: "Light rain",
            63: "Rain",
            65: "Heavy rain",
            66: "Freezing rain",
            67: "Freezing rain",
            71: "Light snow",
            73: "Snow",
            75: "Heavy snow",
            77: "Snow grains",
            80: "Light showers",
            81: "Showers",
            82: "Violent showers",
            85: "Snow showers",
            86: "Heavy snow showers",
            95: "Thunderstorm",
            96: "Thunderstorm with hail",
            99: "Thunderstorm with hail"
        };
        return names[c] ?? "";
    }

    function iconFor(c, isNight) {
        if (c === 0)
            return isNight ? Icons.weatherNight : Icons.weatherSunny;
        if (c === 1 || c === 2)
            return isNight ? Icons.weatherNightPartly : Icons.weatherPartly;
        if (c === 3)
            return Icons.weatherCloudy;
        if (c === 45 || c === 48)
            return Icons.weatherFog;
        if ([56, 57, 66, 67].includes(c))
            return Icons.weatherSleet;
        if (c === 65 || c === 82)
            return Icons.weatherPouring;
        if ([71, 73, 77, 85].includes(c))
            return Icons.weatherSnow;
        if (c === 75 || c === 86)
            return Icons.weatherSnowHeavy;
        if (c >= 95)
            return Icons.weatherThunderRain;
        return Icons.weatherRain;          // drizzle, rain, showers, and anything unknown
    }
}
