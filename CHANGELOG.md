# Changelog

All notable changes to astropath are documented here.
Releases follow [Semantic Versioning](https://semver.org/).

## [0.4.0] — 2026-06-20

### Bug Fixes

- **view**: reveal actions below row, cleaner selection, filter state tags ([`00679fb`](https://github.com/gfriloux/astropath/commit/00679fbdfcb60f7e605f602cc70cf286ae7ead54))
- **view**: drop clashing left bar on rail selection ([`8bf90db`](https://github.com/gfriloux/astropath/commit/8bf90dbbfe5868c806898f8b3d62b957afe9d973))
- **ci**: point qmltestrunner at qtdeclarative qml (QtQuick.Window) ([`80e9dbf`](https://github.com/gfriloux/astropath/commit/80e9dbff8c6f14ee7c6ae389478131e423f11cdb))

### Documentation

- add DESIGN invariants ([`c8bc2fd`](https://github.com/gfriloux/astropath/commit/c8bc2fd91ef542c6bd6b36c12ece51fac4ceb336))
- add planning procedure ([`4f81326`](https://github.com/gfriloux/astropath/commit/4f81326bf7975c40f978a5ccb67982b291b1b2fe))
- add CLAUDE guardrails and README ([`5eb10c1`](https://github.com/gfriloux/astropath/commit/5eb10c14fea08f2296ee55fbb3438956af715a3f))
- make astropath account-agnostic, treat reading client as config ([`3d5abfb`](https://github.com/gfriloux/astropath/commit/3d5abfb199fedccb567d1bd8cf61db343292d721))
- **design**: retain cockpit (C) as the UI direction ([`f6134af`](https://github.com/gfriloux/astropath/commit/f6134afd367898487736a58115ca74eb951d163b))
- **design**: generic, config-driven tag taxonomy ([`6d540aa`](https://github.com/gfriloux/astropath/commit/6d540aa333684d2079d893fd8890f410fbbc8feb))
- **plan**: add v0.1.0 data-layer plan ([`f10fc16`](https://github.com/gfriloux/astropath/commit/f10fc161f6e1430c6d1ea70d56049073a0e99c5f))
- document data-layer modules and close v0.1.0 plan ([`c5cdd2b`](https://github.com/gfriloux/astropath/commit/c5cdd2b319ae053095b3dce37f2fedd08718f373))
- **procedure**: require merging the plan branch into main at plan close ([`9586164`](https://github.com/gfriloux/astropath/commit/958616444bfe4c56175428aef9c71d8abe99eda1))
- **plan**: add v0.2.0 cockpit plan ([`eb3e859`](https://github.com/gfriloux/astropath/commit/eb3e859e46b2e722931e21072c24bc956d780e49))
- document plugin architecture and close v0.2.0 ([`1f52fde`](https://github.com/gfriloux/astropath/commit/1f52fde670ab206417ece95550085cb929bf3800))
- **plan**: add v0.3.0 graphical polish plan ([`5926a7f`](https://github.com/gfriloux/astropath/commit/5926a7f7befb288449a2c91291cad91135fcdbb1))
- **plan**: close v0.3.0 ([`0342656`](https://github.com/gfriloux/astropath/commit/034265687adfa8c87879d698fd3b5921d266130e))
- **plan**: add v0.4.0 functional plan ([`42472da`](https://github.com/gfriloux/astropath/commit/42472da40bb578f6a9b76fa4c6a1288ade29ebb1))
- **plan**: drop VIP from v0.4.0 scope ([`7998ef4`](https://github.com/gfriloux/astropath/commit/7998ef4be0f6f9f50dec8cc9b02ac5bd65053327))
- **plan**: close v0.4.0 ([`331a79e`](https://github.com/gfriloux/astropath/commit/331a79e120315d3f53460e71957f605967197d30))
- **plan**: add release tooling plan ([`3f6a1ea`](https://github.com/gfriloux/astropath/commit/3f6a1eaa5c25a0ba1ffe51aaf44a02c14afe6997))

### Features

- **query**: notmuch argv builders + tests ([`4ee3388`](https://github.com/gfriloux/astropath/commit/4ee3388057a6d9bfefba985fcbe330cd576c58f4))
- **model**: search/count/saved-search transforms + tests ([`a23593a`](https://github.com/gfriloux/astropath/commit/a23593a6b0d26336d8178f4c7f2630cb7ed5cbd9))
- **model**: parse notmuch show into snippet ([`e5d2aaa`](https://github.com/gfriloux/astropath/commit/e5d2aaa7cf32d5b4a82f42e0236b408ba76af29b))
- **view**: DMS plugin manifest and bar badge widget ([`c579407`](https://github.com/gfriloux/astropath/commit/c5794075fa3ce6a156d4782e99638de2850b9554))
- **view**: notmuch service with polling, wire real unread count ([`cc0a8b5`](https://github.com/gfriloux/astropath/commit/cc0a8b546b07b0e7d02bf9b4e0b2807b6df494de))
- **view**: cockpit popout skeleton (header, refresh, footer) ([`060ee1c`](https://github.com/gfriloux/astropath/commit/060ee1c59a44c2c412cab854b036f4480db73ded))
- **view**: unread thread list in cockpit ([`ccf3d9f`](https://github.com/gfriloux/astropath/commit/ccf3d9f2e2de51885bff48d29a90029f4a6f4125))
- **view**: saved-search rail with immediate query switch ([`76a8736`](https://github.com/gfriloux/astropath/commit/76a873621bb9f72cdd7b35c938d87d7de1700b6d))
- **view**: live notmuch search bar (debounced) ([`5751390`](https://github.com/gfriloux/astropath/commit/5751390e2cdda4ca5287c3bda49174ee9dc44eec))
- **view**: inline thread actions (mark read/archive/flag/delete) ([`bc1cdac`](https://github.com/gfriloux/astropath/commit/bc1cdac0a9a9c8978ab3b1a7e3e94b420ef39fab))
- **view**: config-driven service and open action ([`6d00fc6`](https://github.com/gfriloux/astropath/commit/6d00fc6a9738a5897c982c6a8cd3b110172fabd2))
- **view**: plugin settings (reader, interval, saved-search editor) ([`a281462`](https://github.com/gfriloux/astropath/commit/a28146265c15919ad38c1d5e3d7821950ffce0f9))
- **view**: relative sync time and footer shortcut chips ([`aa87191`](https://github.com/gfriloux/astropath/commit/aa87191f33e58be21338c184487e5326529ebdf6))
- **view**: keyboard navigation (j/k/enter/e/#) ([`3ade678`](https://github.com/gfriloux/astropath/commit/3ade678e04c5b79de5f8139cacccf6acef620032))
- **nix**: home-manager module installing the DMS plugin ([`3bb1ac1`](https://github.com/gfriloux/astropath/commit/3bb1ac142725bf651b94de8f001ec25e5a1a5b74))
- **view**: sender avatars and monospace meta ([`5d83b02`](https://github.com/gfriloux/astropath/commit/5d83b02338938573ef2abc4ad6c5644b6517c25f))
- **view**: badge pulse and staggered thread appearance ([`4054e84`](https://github.com/gfriloux/astropath/commit/4054e84c7035335760e4f43f2dcbacefa6c28e30))
- **view**: per-search counts in the rail ([`0bcb487`](https://github.com/gfriloux/astropath/commit/0bcb487ab653f0e1d2dbf070e8adb40dae807fd1))
- **view**: colored tag chips from config ([`3c2fc14`](https://github.com/gfriloux/astropath/commit/3c2fc14a9a3b61d5e846bdce382b1e63e3821e5c))
- **view**: lazy snippet for the focused thread ([`cfced9d`](https://github.com/gfriloux/astropath/commit/cfced9dd4fbb7694a0496ddd44b554d01c884d7d))
- **view**: inline retag editor ([`41b7006`](https://github.com/gfriloux/astropath/commit/41b7006ca805ed695fd16cc245c7fa1c7eddd1a8))

### Testing

- golden harness (qmltestrunner + bless) and model goldens ([`b262cf0`](https://github.com/gfriloux/astropath/commit/b262cf0cf12c682f5939fa7d8289d0af285bd782))
- **model**: golden for show ([`5feff60`](https://github.com/gfriloux/astropath/commit/5feff606edba83adc5fdeb2090a7b1e773f2d850))

