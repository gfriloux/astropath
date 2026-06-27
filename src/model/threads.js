.pragma library

// Transforms du modèle de fils. Fonctions pures : mêmes entrées notmuch → même sortie.
// Entrée = JSON déjà parsé de notmuch ; sortie = modèle de domaine d'astropath.

function hasTag(tags, t) {
    return tags.indexOf(t) !== -1;
}

// notmuch search --format=json (résumé de fils) → Thread[].
// Champs notmuch : thread, date_relative, total, authors, subject, tags.
// Le résumé search n'a pas de corps : le snippet est ajouté ailleurs (show).
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

// notmuch count → entier (la sortie est un nombre en texte, pas du JSON).
function parseCount(output) {
    return parseInt(String(output).trim(), 10) || 0;
}

// notmuch search --output=tags → liste de tags (sortie texte, 1 tag par ligne).
// On nettoie : trim de chaque ligne, lignes vides retirées. Ordre notmuch préservé.
function parseTags(output) {
    return String(output || "").split("\n").map(function (l) {
        return l.trim();
    }).filter(function (l) {
        return l.length > 0;
    });
}

// Map tag → couleur, dérivée des définitions de smart folders (requêtes simples « tag:X »).
// Les requêtes composées (espaces) ou sans couleur sont ignorées.
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

// Enrichit des smart folders de leur compteur. Les définitions (label/requête/couleur)
// sont de la CONFIG utilisateur, injectées — jamais codées en dur ici (le modèle reste
// générique et agnostique à la taxonomie perso). definitions = [{key,label,query,color}],
// counts = { <key>: <entier> }.
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
// La sortie show est imbriquée : [ thread, … ] ; thread = [ [msgObj, replies], … ],
// replies ayant la même forme (récursif). On en tire le snippet + en-têtes du fil.

// Premier message du premier fil (parcours en profondeur).
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

// Corps texte/plain d'un message (descend dans les parties multipart).
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

// Réduit un texte à un aperçu d'une ligne (espaces compactés, tronqué).
function snippet(text, maxLen) {
    maxLen = maxLen || 140;
    var s = String(text).replace(/\s+/g, " ").trim();
    if (s.length > maxLen)
        s = s.slice(0, maxLen - 1).trim() + "…";
    return s;
}

// notmuch show 'thread:<id>' → { snippet, subject, from, date } du fil.
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
