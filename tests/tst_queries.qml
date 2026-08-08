import QtQuick
import QtTest
import "../src/query/queries.js" as Q

TestCase {
    name: "queries"

    function eq(actual, expected) {
        compare(JSON.stringify(actual), JSON.stringify(expected));
    }

    function test_search() {
        eq(Q.search("tag:alpha"), ["search", "--format=json", "tag:alpha"]);
    }

    // A query with spaces stays as ONE argv element (no shell splitting).
    function test_searchUnread() {
        eq(Q.searchUnread(), ["search", "--format=json", "tag:inbox and tag:unread"]);
    }

    function test_count() {
        eq(Q.count("tag:inbox"), ["count", "tag:inbox"]);
        eq(Q.count("tag:inbox", "threads"), ["count", "--output=threads", "tag:inbox"]);
    }

    function test_showThread() {
        eq(Q.showThread("abc123"), ["show", "--format=json", "thread:abc123"]);
    }

    function test_tags() {
        eq(Q.tags(), ["search", "--output=tags", "*"]);
    }

    function test_tagThread_add() {
        eq(Q.tagThread("abc", { add: ["flagged"] }),
           ["tag", "+flagged", "--", "thread:abc"]);
    }

    function test_tagThread_remove() {
        eq(Q.tagThread("abc", { remove: ["unread"] }),
           ["tag", "-unread", "--", "thread:abc"]);
    }

    function test_tagThread_both() {
        eq(Q.tagThread("abc", { add: ["spam"], remove: ["inbox", "unread"] }),
           ["tag", "+spam", "-inbox", "-unread", "--", "thread:abc"]);
    }
}
