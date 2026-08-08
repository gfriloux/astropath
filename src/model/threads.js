.pragma library

// Thread model transforms. Pure functions: same notmuch input → same output.
// Input = already-parsed notmuch JSON; output = astropath's domain model.

function hasTag(tags, t) {
    return tags.indexOf(t) !== -1;
}

// notmuch search --format=json (thread summaries) → Thread[].
// notmuch fields: thread, date_relative, total, authors, subject, tags.
// The search summary carries no body: the snippet is added elsewhere (show).
function parseSearch(rows) {
    return rows.map(function (r) {
        var tags = r.tags || [];
        return {
            id: r.thread,
            authors: r.authors,
            subject: r.subject,
            dateRelative: r.date_relative,
            total: r.total,
            tags: tags,
            unread: hasTag(tags, "unread"),
            flagged: hasTag(tags, "flagged")
        };
    });
}

// notmuch count → integer (the output is a number as text, not JSON).
function parseCount(output) {
    return parseInt(String(output).trim(), 10) || 0;
}

// notmuch search --output=tags → tag list (text output, one tag per line).
// We clean up: trim each line, drop empty ones. notmuch's ordering is preserved.
function parseTags(output) {
    return String(output || "").split("\n").map(function (l) {
        return l.trim();
    }).filter(function (l) {
        return l.length > 0;
    });
}

// Map tag → color, derived from the smart folder definitions (plain « tag:X » queries).
// Composed queries (with spaces) and colorless ones are ignored.
function tagColors(definitions) {
    var m = {};
    (definitions || []).forEach(function (d) {
        var q = String(d.query || "");
        if (q.indexOf("tag:") === 0 && q.indexOf(" ") === -1) {
            var tag = q.slice(4);
            if (tag && d.color)
                m[tag] = d.color;
        }
    });
    return m;
}

// Machine/operational tags: STATES, not categories. Excluded from the rail's
// auto-discovery (the universal inbox/flagged/spam are in here because they are already
// pinned with their fixed color). This is not a hardcoded personal taxonomy (see DESIGN,
// inv. 3): just the list of tags that notmuch/the sync set to signal a state. The user can
// hide other tags, or bring these back, through the overrides.
var DEFAULT_TAG_BLOCKLIST = ["unread", "inbox", "flagged", "spam", "attachment", "signed", "encrypted", "replied", "sent", "draft", "passed", "new", "deleted"];

// Catppuccin category palette (DESIGN: hues offered for assignment, excluding the
// universals' fixed colors). A tag's stable color = deterministic hash over the palette.
var CATEGORY_PALETTE = ["#b4befe", "#a6e3a1", "#94e2d5", "#fab387", "#f9e2af", "#cba6f7"];

function colorForTag(tag) {
    var s = String(tag || "");
    var h = 0;
    for (var i = 0; i < s.length; i++)
        h = (h + s.charCodeAt(i)) % CATEGORY_PALETTE.length;
    return CATEGORY_PALETTE[h];
}

// Builds the rail's definition list from the discovered tags and the config.
// Pure ⇒ goldenable. cfg = {
//   universals: definitions pinned at the top (fixed color), passed through as-is;
//   blocklist : tags excluded from auto-discovery (default: DEFAULT_TAG_BLOCKLIST);
//   overrides : [{tag, label?, color?, hidden?}] — amends a discovered tag;
//   custom    : [{key,label,query,color}] — composed searches, appended at the end.
// }
// Output: universals ⊕ discovered(sorted, minus blocklist & hidden) ⊕ custom.
function buildDefinitions(tags, cfg) {
    cfg = cfg || {};
    var universals = cfg.universals || [];
    var blockset = {};
    (cfg.blocklist || DEFAULT_TAG_BLOCKLIST).forEach(function (t) {
        blockset[t] = true;
    });
    var overrides = {};
    (cfg.overrides || []).forEach(function (o) {
        if (o && o.tag)
            overrides[o.tag] = o;
    });

    var discovered = (tags || []).filter(function (t) {
        return !blockset[t] && !(overrides[t] && overrides[t].hidden);
    }).sort().map(function (t) {
        var o = overrides[t] || {};
        return {
            key: t,
            label: o.label || t,
            query: "tag:" + t,
            color: o.color || colorForTag(t)
        };
    });

    var custom = (cfg.custom || []).map(function (c) {
        return {
            key: c.key,
            label: c.label,
            query: c.query,
            color: c.color
        };
    });

    return universals.concat(discovered).concat(custom);
}

// Enriches smart folders with their counter. The definitions (label/query/color) are
// user CONFIG, injected — never hardcoded here (the model stays generic and agnostic to
// the personal taxonomy). definitions = [{key,label,query,color}],
// counts = { <key>: <integer> }.
function savedSearches(definitions, counts) {
    counts = counts || {};
    return (definitions || []).map(function (s) {
        return {
            key: s.key,
            label: s.label,
            query: s.query,
            color: s.color,
            count: counts[s.key] || 0
        };
    });
}

// --- notmuch show ----------------------------------------------------------
// The show output is nested: [ thread, … ]; thread = [ [msgObj, replies], … ], with
// replies having the same shape (recursive). We pull the snippet + thread headers out of it.

// First message of the first thread (depth-first walk).
function firstMessage(showJson) {
    var threads = showJson || [];
    for (var i = 0; i < threads.length; i++) {
        var m = firstInThread(threads[i]);
        if (m)
            return m;
    }
    return null;
}

function firstInThread(thread) {
    for (var i = 0; i < (thread || []).length; i++) {
        var node = thread[i]; // [msgObj, replies]
        var msg = node[0];
        if (msg && msg.id)
            return msg;
        var deeper = firstInThread(node[1]);
        if (deeper)
            return deeper;
    }
    return null;
}

// text/plain body of a message (descends into multipart parts).
function textBody(msg) {
    return collectText((msg && msg.body) || []);
}

function collectText(parts) {
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i];
        var ct = p["content-type"] || "";
        if (ct.indexOf("text/plain") === 0 && typeof p.content === "string")
            return p.content;
        if (Array.isArray(p.content)) {
            var sub = collectText(p.content);
            if (sub)
                return sub;
        }
    }
    return "";
}

// Reduces a text to a one-line preview (whitespace collapsed, truncated).
function snippet(text, maxLen) {
    maxLen = maxLen || 140;
    var s = String(text).replace(/\s+/g, " ").trim();
    if (s.length > maxLen)
        s = s.slice(0, maxLen - 1).trim() + "…";
    return s;
}

// notmuch show 'thread:<id>' → { snippet, subject, from, date } for the thread.
function parseShow(showJson) {
    var msg = firstMessage(showJson);
    if (!msg)
        return { snippet: "", subject: "", from: "", date: "" };
    var h = msg.headers || {};
    return {
        snippet: snippet(textBody(msg)),
        subject: h.Subject || "",
        from: h.From || "",
        date: h.Date || ""
    };
}
