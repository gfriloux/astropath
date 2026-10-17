import QtQuick
import QtTest
import "../src/model/overrides.js" as Ov

TestCase {
    name: "overrides"

    function test_overrideFor() {
        var ovs = [{
                "tag": "boulot",
                "color": "#cba6f7"
            }, {
                "tag": "perso"
            }];
        compare(Ov.overrideFor(ovs, "boulot").color, "#cba6f7");
        compare(Ov.overrideFor(ovs, "absent"), null);
        compare(Ov.overrideFor([], "boulot"), null);
    }

    function test_patchOverride_addsEntry() {
        var a = Ov.patchOverride([], "boulot", {
            "label": "Taf"
        });
        compare(a.length, 1);
        compare(a[0].tag, "boulot");
        compare(a[0].label, "Taf");
    }

    function test_patchOverride_mergesKeepingOtherFields() {
        var a = Ov.patchOverride([{
                "tag": "boulot",
                "label": "Taf"
            }], "boulot", {
            "color": "#a6e3a1"
        });
        compare(a[0].label, "Taf");
        compare(a[0].color, "#a6e3a1");
    }

    function test_patchOverride_clearingLabelDropsTheField() {
        var a = Ov.patchOverride([{
                "tag": "boulot",
                "label": "Taf",
                "color": "#a6e3a1"
            }], "boulot", {
            "label": ""
        });
        verify(a[0].label === undefined);
        compare(a[0].color, "#a6e3a1");
    }

    function test_patchOverride_pruneToBareRemovesEntry() {
        var a = Ov.patchOverride([{
                "tag": "boulot",
                "label": "Taf"
            }], "boulot", {
            "label": ""
        });
        compare(a.length, 0);
    }

    function test_patchOverride_hideThenUnhide() {
        var hidden = Ov.patchOverride([], "boulot", {
            "hidden": true
        });
        compare(hidden[0].hidden, true);
        compare(Ov.patchOverride(hidden, "boulot", {
            "hidden": false
        }).length, 0);
    }

    // The QML component hands over its own `overrides` array by reference: patching must
    // never write through it.
    function test_patchOverride_doesNotMutateInput() {
        var input = [{
                "tag": "boulot",
                "label": "Taf"
            }];
        Ov.patchOverride(input, "boulot", {
            "label": ""
        });
        compare(input.length, 1);
        compare(input[0].label, "Taf");
    }

    function test_deriveKey() {
        compare(Ov.deriveKey("Boulot"), "boulot");
        compare(Ov.deriveKey("  Urgent   client "), "-urgent-client-");
        compare(Ov.deriveKey("À trier"), "à-trier");
    }
}
