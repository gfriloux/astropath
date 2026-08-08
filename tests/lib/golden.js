.pragma library

// Synchronous read of a local JSON file (fixture or golden) through file:// .
function readJson(url) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, false);
    xhr.send(null);
    // file:// often returns status 0 on success.
    if (xhr.status !== 200 && xhr.status !== 0)
        throw new Error("lecture impossible: " + url + " (status " + xhr.status + ")");
    return JSON.parse(xhr.responseText);
}

// Canonical serialization (sorted keys) so comparison ignores key order.
function canonical(v) {
    if (Array.isArray(v))
        return "[" + v.map(canonical).join(",") + "]";
    if (v && typeof v === "object") {
        var keys = Object.keys(v).sort();
        return "{" + keys.map(function (k) {
            return JSON.stringify(k) + ":" + canonical(v[k]);
        }).join(",") + "}";
    }
    return JSON.stringify(v);
}

function equal(a, b) {
    return canonical(a) === canonical(b);
}

function pretty(v) {
    return JSON.stringify(v, null, 2);
}
