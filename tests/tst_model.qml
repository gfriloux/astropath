import QtQuick
import QtTest
import "../src/model/threads.js" as Model
import "../src/model/format.js" as Format

TestCase {
    name: "model"

    function test_parseCount() {
        compare(Model.parseCount("6\n"), 6);
        compare(Model.parseCount("0"), 0);
        compare(Model.parseCount(""), 0);
        compare(Model.parseCount("  42 "), 42);
    }

    function test_relativeTime() {
        var now = 1000000000000;
        compare(Format.relativeTime(0, now), "");
        compare(Format.relativeTime(now - 30 * 1000, now), "à l'instant");
        compare(Format.relativeTime(now - 5 * 60 * 1000, now), "il y a 5 min");
        compare(Format.relativeTime(now - 3 * 3600 * 1000, now), "il y a 3 h");
        compare(Format.relativeTime(now - 2 * 86400 * 1000, now), "il y a 2 j");
    }

    function test_initials() {
        compare(Format.initials("Alice Martin, Bob Durand"), "AM");
        compare(Format.initials("Charlie"), "CH");
        compare(Format.initials("Boutique en ligne"), "BE");
        compare(Format.initials(""), "?");
    }

    function test_tagColors() {
        var m = Model.tagColors([{
                "query": "tag:alpha",
                "color": "#b4befe"
            }, {
                "query": "tag:x and tag:y",
                "color": "#ffffff"
            }, {
                "query": "tag:spam",
                "color": ""
            }]);
        compare(m["alpha"], "#b4befe");
        verify(m["x"] === undefined); // requête composée ignorée
        verify(m["spam"] === undefined); // sans couleur ignorée
    }

    function test_colorIndex() {
        // Déterministe et borné.
        compare(Format.colorIndex("alice", 6), Format.colorIndex("alice", 6));
        verify(Format.colorIndex("bob", 6) >= 0 && Format.colorIndex("bob", 6) < 6);
        compare(Format.colorIndex("x", 0), 0);
    }
}
