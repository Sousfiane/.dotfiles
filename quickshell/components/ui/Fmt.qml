pragma Singleton
import Quickshell

// small text helpers shared by the panels
Singleton {
    // "1 update", "3 updates"; `many` for irregular plurals
    function plural(n, one, many) {
        return n + " " + (n === 1 ? one : (many ?? one + "s"));
    }
}
