.pragma library
.import "../src/model/threads.js" as Model

// Single registry of golden cases, consumed by both tst_golden.qml AND tests/bless.qml.
// Each case: { name, transform } with fixtures/<name>.json → golden/<name>.json.
var cases = [
    { name: "search-unread", transform: Model.parseSearch },
    {
        name: "saved-searches",
        // The fixture carries definitions + counts (neutral data); we adapt it to
        // savedSearches' two-argument signature.
        transform: function (input) {
            return Model.savedSearches(input.definitions, input.counts);
        }
    },
    { name: "show-thread", transform: Model.parseShow },
    {
        name: "discovered-searches",
        // The fixture carries tags + cfg (universals/blocklist/overrides/custom); we adapt
        // it to buildDefinitions' signature.
        transform: function (input) {
            return Model.buildDefinitions(input.tags, input.cfg);
        }
    }
];
