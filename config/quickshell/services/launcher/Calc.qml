pragma Singleton
import Quickshell

// The launcher's calculator ("=", or plain math typed among the apps): only numbers, operators and the
// names below are allowed, so nothing but a calculation can ever run.
Singleton {
    // the names a calculation may use; anything else and it isn't one
    readonly property var names: ({
            sqrt: "Math.sqrt",
            cbrt: "Math.cbrt",
            abs: "Math.abs",
            round: "Math.round",
            floor: "Math.floor",
            ceil: "Math.ceil",
            sin: "Math.sin",
            cos: "Math.cos",
            tan: "Math.tan",
            asin: "Math.asin",
            acos: "Math.acos",
            atan: "Math.atan",
            ln: "Math.log",
            log: "Math.log10",
            exp: "Math.exp",
            min: "Math.min",
            max: "Math.max",
            pi: "Math.PI",
            e: "Math.E"
        })

    // the value of a calculation, or null when it isn't one
    function evaluate(text) {
        let s = text.toLowerCase().replace(/\s+/g, "").replace(/×/g, "*").replace(/÷/g, "/").replace(/π/g, "pi").replace(/\^/g, "**");
        if (s === "")
            return null;
        // "3,5" is a decimal comma, unless a function is used (then a comma separates its arguments)
        if (!/[a-z]/.test(s))
            s = s.replace(/,/g, ".");
        if (!/^[0-9a-z.+\-*\/%(),]+$/.test(s))
            return null;
        let unknown = false;
        s = s.replace(/[a-z]+/g, w => names[w] ?? (unknown = true, ""));
        if (unknown)
            return null;
        try {
            const v = Function('"use strict"; return (' + s + ");")();
            return typeof v === "number" && isFinite(v) ? v : null;
        } catch (e) {
            return null;
        }
    }

    // 0.1 + 0.2 shows 0.3: twelve significant digits, trailing zeros dropped
    function format(v) {
        return Number.isInteger(v) ? String(v) : String(parseFloat(v.toPrecision(12)));
    }

    // only digits and operators, with an operator: worth a result row above the apps
    function looksLikeMath(q) {
        return /^[\d\s.,+\-*\/%^()×÷]+$/.test(q) && /\d/.test(q) && /[+\-*\/%^×÷]/.test(q) && evaluate(q) !== null;
    }
}
