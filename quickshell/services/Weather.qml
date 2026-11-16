pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// current weather from wttr.in (no API key). The location comes from Config.weatherLocation,
// or from the IP address when that is empty.
Singleton {
    id: root

    property bool ready: false              // at least one successful fetch
    property real fetchedAt: 0              // ms since epoch

    property int temp: 0                    // °C
    property int feelsLike: 0
    property int high: 0                    // today's max / min
    property int low: 0
    property string desc: ""
    property string area: ""
    property int code: 0                    // wttr.in / WWO weather code
    property bool night: false

    readonly property string icon: iconFor(code, night)

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    // refresh when the data is older than `maxAgeMin` (default 10), used when the hub or the lockscreen opens
    function refreshIfStale(maxAgeMin) {
        if (Date.now() - fetchedAt > (maxAgeMin ?? 10) * 60 * 1000)
            refresh();
    }

    function iconFor(c, isNight) {
        if (c === 113)
            return isNight ? Icons.weatherNight : Icons.weatherSunny;
        if (c === 116)
            return isNight ? Icons.weatherNightPartly : Icons.weatherPartly;
        if ([119, 122].includes(c))
            return Icons.weatherCloudy;
        if ([143, 248, 260].includes(c))
            return Icons.weatherFog;
        if ([386, 389].includes(c))
            return Icons.weatherThunderRain;
        if ([200, 392, 395].includes(c))
            return Icons.weatherThunder;
        if ([227, 230, 335, 338, 371].includes(c))
            return Icons.weatherSnowHeavy;
        if ([323, 326, 329, 332, 368].includes(c))
            return Icons.weatherSnow;
        if ([179, 182, 185, 281, 284, 311, 314, 317, 320, 350, 362, 365, 374, 377].includes(c))
            return Icons.weatherSleet;
        if ([299, 302, 305, 308, 356, 359].includes(c))
            return Icons.weatherPouring;
        return Icons.weatherRain;          // 176, 263, 266, 293, 296, 353 and anything unknown
    }

    // "08:01 AM" -> minutes since midnight
    function minutes(t) {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(t ?? "");
        if (!m)
            return -1;
        const h = (+m[1] % 12) + (m[3].toUpperCase() === "PM" ? 12 : 0);
        return h * 60 + +m[2];
    }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/" + encodeURIComponent(Config.weatherLocation) + "?format=j1"]
        running: true                       // once at startup

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0];
                    const today = d.weather[0];
                    root.temp = +c.temp_C;
                    root.feelsLike = +c.FeelsLikeC;
                    root.code = +c.weatherCode;
                    root.desc = c.weatherDesc?.[0]?.value?.trim() ?? "";
                    root.high = +today.maxtempC;
                    root.low = +today.mintempC;
                    root.area = d.nearest_area?.[0]?.areaName?.[0]?.value ?? "";

                    const now = new Date();
                    const n = now.getHours() * 60 + now.getMinutes();
                    const rise = root.minutes(today.astronomy?.[0]?.sunrise);
                    const set = root.minutes(today.astronomy?.[0]?.sunset);
                    root.night = rise >= 0 && set >= 0 && (n < rise || n >= set);

                    root.fetchedAt = Date.now();
                    root.ready = true;
                } catch (e) {
                    // keep the last good data; wttr.in sometimes answers with an error page
                }
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000            // every 30 minutes
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
