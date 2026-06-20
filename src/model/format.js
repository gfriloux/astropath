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
