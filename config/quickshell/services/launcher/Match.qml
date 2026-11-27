pragma Singleton
import Quickshell

// How well the launcher's query matches an app or one of its actions: the higher the score, the higher
// the row; 0 is no match.
Singleton {
    // how well `word` matches `text`, 0..100: whole > start > start of a word > anywhere > (fuzzy) in order
    function match(text, word, fuzzy) {
        const t = (text ?? "").toLowerCase();
        if (t === "")
            return 0;
        if (t === word)
            return 100;
        if (t.startsWith(word))
            return 90;
        const at = t.indexOf(word);
        if (at > 0 && /[^a-z0-9]/.test(t[at - 1]))
            return 80;
        if (at > 0)
            return 70;
        return fuzzy ? subsequence(t, word) : 0;
    }

    // "lbo" in "libreoffice": every letter in order, scored by how close together they are (10..40)
    function subsequence(t, word) {
        let i = 0, first = -1, last = -1;
        for (const ch of word) {
            i = t.indexOf(ch, i);
            if (i < 0)
                return 0;
            if (first < 0)
                first = i;
            last = i++;
        }
        const spread = last - first + 1 - word.length;      // letters skipped in between
        return Math.max(10, 40 - 3 * spread);
    }

    // the name counts most; what kind of app it is and its keywords next; its description last.
    // Every word of the query must match somewhere; the weakest one sets the score
    function app(a, words) {
        const keywords = [].concat(a.keywords ?? []);
        let total = Infinity;
        for (const w of words) {
            const s = Math.max(match(a.name, w, true) * 10, match(a.genericName, w, false) * 6, Math.max(0, ...keywords.map(k => match(k, w, false))) * 6, match(a.comment, w, false) * 3);
            if (s === 0)
                return 0;
            total = Math.min(total, s);
        }
        return total;
    }

    // an action shows when the query names it ("private"), alone or with its app ("zen private").
    // Below the apps: typing "zen" lists Zen first, its actions only when asked for
    function action(a, act, words) {
        let named = false;
        let total = Infinity;
        for (const w of words) {
            const onAction = match(act.name, w, false);
            const onApp = match(a.name, w, false);
            if (onAction === 0 && onApp === 0)
                return 0;
            named = named || onAction > 0;
            total = Math.min(total, Math.max(onAction, onApp) * 5);
        }
        return named ? total : 0;
    }
}
