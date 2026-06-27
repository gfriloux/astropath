.pragma library
.import "../src/model/threads.js" as Model

// Registre unique des cas golden, consommé par tst_golden.qml ET tests/bless.qml.
// Chaque cas : { name, transform } avec fixtures/<name>.json → golden/<name>.json.
var cases = [
    { name: "search-unread", transform: Model.parseSearch },
    {
        name: "saved-searches",
        // La fixture porte definitions + counts (données neutres) ; on adapte vers la
        // signature à deux arguments de savedSearches.
        transform: function (input) {
            return Model.savedSearches(input.definitions, input.counts);
        }
    },
    { name: "show-thread", transform: Model.parseShow },
    {
        name: "discovered-searches",
        // La fixture porte tags + cfg (universels/blocklist/overrides/custom) ; on adapte
        // vers la signature de buildDefinitions.
        transform: function (input) {
            return Model.buildDefinitions(input.tags, input.cfg);
        }
    }
];
