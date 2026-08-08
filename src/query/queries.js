.pragma library

// Argument (argv) construction for notmuch commands. Pure, testable functions.
// We return an argument array — never a shell line: the query (which may contain
// spaces) stays as ONE element, so there is no splitting and no shell injection.

// Unread threads in the inbox (see DESIGN.md: tag-only).
var UNREAD_QUERY = "tag:inbox and tag:unread";

// notmuch search 'query' → thread summaries as JSON.
function search(query) {
    return ["search", "--format=json", query];
}

function searchUnread() {
    return search(UNREAD_QUERY);
}

// notmuch search --output=tags '*' → every tag in the database (text, one per line).
// Used to discover the taxonomy (the rail's categories derive from it). No --format=json:
// the tags output is already a list of raw lines.
function tags() {
    return ["search", "--output=tags", "*"];
}

// notmuch count 'query' → integer. Optional output: "messages" (notmuch default) or "threads".
function count(query, output) {
    var args = ["count"];
    if (output)
        args.push("--output=" + output);
    args.push(query);
    return args;
}

// notmuch show 'thread:<id>' → thread tree as JSON (headers + body, for the snippet).
function showThread(threadId) {
    return ["show", "--format=json", "thread:" + threadId];
}

// notmuch tag +a -b -- 'thread:<id>' → tag mutation on a thread.
// ops = { add: [tags], remove: [tags] }. The "--" separates the ops from the query.
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
