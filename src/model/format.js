.pragma library

// Relative time (« il y a N … ») from a timestamp (ms) and a now (ms).
// now is passed as an argument → pure, testable function. Returned strings are UI copy
// and stay in French.
function relativeTime(epochMs, nowMs) {
    if (!epochMs)
        return "";
    var s = Math.max(0, Math.floor((nowMs - epochMs) / 1000));
    if (s < 60)
        return "à l'instant";
    var m = Math.floor(s / 60);
    if (m < 60)
        return "il y a " + m + " min";
    var h = Math.floor(m / 60);
    if (h < 24)
        return "il y a " + h + " h";
    var d = Math.floor(h / 24);
    return "il y a " + d + " j";
}

// Initials (1-2 letters) of the first sender, for the monogram avatar.
function initials(authors) {
    var first = String(authors || "").split(",")[0].trim();
    if (!first)
        return "?";
    var words = first.split(/\s+/);
    if (words.length >= 2)
        return (words[0][0] + words[1][0]).toUpperCase();
    return first.slice(0, 2).toUpperCase();
}

// Parses a retag input « +a -b c » → { add: [...], remove: [...] } (bare token = add).
function parseRetag(str) {
    var add = [];
    var remove = [];
    String(str || "").split(/\s+/).forEach(function (tok) {
        tok = tok.trim();
        if (!tok)
            return;
        if (tok[0] === "-") {
            if (tok.length > 1)
                remove.push(tok.slice(1));
        } else if (tok[0] === "+") {
            if (tok.length > 1)
                add.push(tok.slice(1));
        } else {
            add.push(tok);
        }
    });
    return {
        "add": add,
        "remove": remove
    };
}

// Deterministic color index (name hash mod n) for the avatar tint.
function colorIndex(name, n) {
    if (n <= 0)
        return 0;
    var h = 0;
    var s = String(name || "");
    for (var i = 0; i < s.length; i++)
        h = (h + s.charCodeAt(i)) % n;
    return h;
}
