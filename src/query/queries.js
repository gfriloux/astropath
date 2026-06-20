.pragma library

// Construction des arguments (argv) des commandes notmuch. Fonctions pures, testables.
// On retourne un tableau d'arguments — jamais une ligne shell : la requête (qui peut
// contenir des espaces) reste UN seul élément, pas de découpage ni d'injection shell.

// Fils non-lus de la boîte de réception (cf. DESIGN.md : tag-only).
var UNREAD_QUERY = "tag:inbox and tag:unread";

// notmuch search 'query' → résumé de fils en JSON.
function search(query) {
    return ["search", "--format=json", query];
}

function searchUnread() {
    return search(UNREAD_QUERY);
}

// notmuch count 'query' → entier. output optionnel : "messages" (défaut notmuch) ou "threads".
function count(query, output) {
    var args = ["count"];
    if (output)
        args.push("--output=" + output);
    args.push(query);
    return args;
}

// notmuch show 'thread:<id>' → arbre du fil en JSON (en-têtes + corps, pour le snippet).
function showThread(threadId) {
    return ["show", "--format=json", "thread:" + threadId];
}

// notmuch tag +a -b -- 'thread:<id>' → mutation de tags d'un fil.
// ops = { add: [tags], remove: [tags] }. Le "--" sépare les ops de la requête.
function tagThread(threadId, ops) {
    ops = ops || {};
    var args = ["tag"];
    (ops.add || []).forEach(function (t) {
        args.push("+" + t);
    });
    (ops.remove || []).forEach(function (t) {
        args.push("-" + t);
    });
    args.push("--");
    args.push("thread:" + threadId);
    return args;
}
