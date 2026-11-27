import QtQuick

// Remembers lookups (a window class or title -> its desktop entry or game). Capped: keys include window
// titles, and a window that keeps changing its title (a game showing its FPS) would grow it forever.
// Past `limit` entries it starts over, which only costs looking things up again.
//
// Lookups run inside bindings (the dock's windows by app), so the state is one object changed in place:
// writing a property here would notify the binding that is reading it, a binding loop.
QtObject {
    property int limit: 256

    readonly property var state: ({
            map: {},
            size: 0
        })

    function has(key) {
        return key in state.map;
    }

    function get(key) {
        return state.map[key];
    }

    // stores and returns `value`
    function put(key, value) {
        if (!(key in state.map)) {
            if (state.size >= limit)
                clear();
            state.size++;
        }
        return state.map[key] = value;
    }

    function clear() {
        state.map = {};
        state.size = 0;
    }
}
