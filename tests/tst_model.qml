import QtQuick
import QtTest
import "../src/model/threads.js" as Model

TestCase {
    name: "model"

    function test_parseCount() {
        compare(Model.parseCount("6\n"), 6);
        compare(Model.parseCount("0"), 0);
        compare(Model.parseCount(""), 0);
        compare(Model.parseCount("  42 "), 42);
    }
}
