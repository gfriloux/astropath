.pragma library

// Transforms du modèle de fils. Fonctions pures : mêmes entrées notmuch → même sortie.
// Entrée = JSON déjà parsé de notmuch ; sortie = modèle de domaine d'astropath.

function hasTag(tags, t) {
    return tags.indexOf(t) !== -1;
}

// notmuch search --format=json (résumé de fils) → Thread[].
// Champs notmuch : thread, date_relative, total, authors, subject, tags.
// Le résumé search n'a pas de corps : snippet et vip sont ajoutés ailleurs (show / config).
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
