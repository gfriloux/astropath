.pragma library

// Settings algebra for the rail's categories. Pure functions: plain data in, NEW plain
// data out — never mutate an argument (QML hands its own arrays over by reference).
// What threads.js is to notmuch output, this module is to the user's amendments:
// the QML component keeps only the PluginSettings I/O.

// The amendment entry for a tag, or null. overrides = [{tag, label?, color?, hidden?}].
function overrideFor(overrides, tag) {
    var a = overrides || [];
    for (var i = 0; i < a.length; i++)
        if (a[i].tag === tag)
            return a[i];
    return null;
}

// Merges an amendment onto a tag. Empty fields are cleaned up; an entry reduced to
// { tag } (no amendment left) is dropped so it does not clutter the config.
function patchOverride(overrides, tag, patch) {
    var a = (overrides || []).slice();
    var idx = -1;
    for (var i = 0; i < a.length; i++)
        if (a[i].tag === tag) {
            idx = i;
            break;
        }
    var merged = Object.assign({}, idx >= 0 ? a[idx] : {
        tag: tag
    }, patch);
    if (!merged.label)
        delete merged.label;
    if (!merged.color)
        delete merged.color;
    if (!merged.hidden)
        delete merged.hidden;
    var bare = Object.keys(merged).length === 1; // only { tag } is left
    if (idx >= 0) {
        if (bare)
            a.splice(idx, 1);
        else
            a[idx] = merged;
    } else if (!bare) {
        a.push(merged);
    }
    return a;
}

// Internal identity of a composed search, derived from the typed label. The label itself
// is what the user sees; this is only the counters' lookup key.
function deriveKey(label) {
    return String(label || "").toLowerCase().replace(/\s+/g, "-");
}

// Same, made unique against the keys already in play (discovered tags + existing composed
// searches). Two definitions sharing a key would share one counter slot, so one of them
// would display the other's count. The typed label is never touched: only this internal
// key gets the -2/-3 suffix.
function uniqueKey(label, takenKeys) {
    return uniquify(deriveKey(label), takenKeys);
}

// The suffix rule itself, on an already-derived key. Shared with buildDefinitions, which
// applies it as a last line of defence on keys it did not mint.
function uniquify(base, takenKeys) {
    var taken = takenKeys || [];
    var candidate = base;
    var n = 2;
    while (taken.indexOf(candidate) !== -1) {
        candidate = base + "-" + n;
        n++;
    }
    return candidate;
}
