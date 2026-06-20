.pragma library

// Temps relatif « il y a N … » à partir d'un timestamp (ms) et d'un now (ms).
// now est passé en argument → fonction pure, testable.
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

// Initiales (1-2 lettres) du premier expéditeur, pour l'avatar monogramme.
function initials(authors) {
    var first = String(authors || "").split(",")[0].trim();
    if (!first)
        return "?";
    var words = first.split(/\s+/);
    if (words.length >= 2)
        return (words[0][0] + words[1][0]).toUpperCase();
    return first.slice(0, 2).toUpperCase();
}

// Parse une saisie de retag « +a -b c » → { add: [...], remove: [...] } (bare = add).
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

// Index de couleur déterministe (hash du nom mod n) pour la teinte de l'avatar.
function colorIndex(name, n) {
    if (n <= 0)
        return 0;
    var h = 0;
    var s = String(name || "");
    for (var i = 0; i < s.length; i++)
        h = (h + s.charCodeAt(i)) % n;
    return h;
}
