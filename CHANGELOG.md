# Changelog

All notable changes to astropath are documented here.
Releases follow [Semantic Versioning](https://semver.org/).

## [0.9.0] — 2026-10-18

### Bug Fixes

- **view**: never drop a search when one is already in flight ([`0348ec7`](https://github.com/gfriloux/astropath/commit/0348ec786f033d295f6ba9d87af87598efacc76e))
- **view**: queue tag mutations instead of dropping all but the first ([`798243e`](https://github.com/gfriloux/astropath/commit/798243e41f1d5753fd0976d992603b4b361911c2))
- **view**: stop the counts sequence latching for the session ([`a6789a3`](https://github.com/gfriloux/astropath/commit/a6789a3b8a8f83ad2c5f67088123cce72571a369))
- **view**: keep a failed tag mutation's error status readable ([`6a5ea45`](https://github.com/gfriloux/astropath/commit/6a5ea4520690efda42e765713bb39eebf1cd0f90))

### Documentation

- adopt the superpowers document tree and ignore agent scratch ([`3c179ca`](https://github.com/gfriloux/astropath/commit/3c179ca4cdcddb29aa841142b44d21fa3e116d33))
- reduce PROCEDURE_PLANS.md to this project's specifics ([`19e7e46`](https://github.com/gfriloux/astropath/commit/19e7e46a9881b94ae0581dc55a17da3b11be2702))
- point CLAUDE.md and README.md at the superpowers norm ([`19553ab`](https://github.com/gfriloux/astropath/commit/19553abf9f19f98a813b2e5d9b1a79af00ce0310))
- apply the branch review fixes to CLAUDE.md, README.md and PROCEDURE_PLANS.md ([`ded76dd`](https://github.com/gfriloux/astropath/commit/ded76dd93d0c76300bf73cfbd752a8ca86750270))
- record the superpowers norm migration validation ([`47b4c5a`](https://github.com/gfriloux/astropath/commit/47b4c5a31202412cdb07464eb33f2c515e58353f))
- restore the two rules dropped from PROCEDURE_PLANS.md ([`73af93f`](https://github.com/gfriloux/astropath/commit/73af93f5b4f32f63094527435b4c36d955d9eb3f))
- design and plan for the contracts pass ([`ced5f37`](https://github.com/gfriloux/astropath/commit/ced5f3737c507285df3d009d58d2f3d27e2e912e))
- record the contracts pass manual validation ([`bc559c1`](https://github.com/gfriloux/astropath/commit/bc559c10fd3de7557273d49c8efea150da77e24c))

### Features

- **view**: show an attachment indicator on thread rows ([`8150fbc`](https://github.com/gfriloux/astropath/commit/8150fbc31537143da036849874eb66040a820fa0))
- **nix**: declare the DMS floor and gate activation on notmuch ([`a0fc36f`](https://github.com/gfriloux/astropath/commit/a0fc36f1611c15237ac00fcda1d8f137efcfed3b))

### Refactoring

- **model**: generalise the snippet queue into a coalescing flight machine ([`deecf5f`](https://github.com/gfriloux/astropath/commit/deecf5f7184f5950185a255c25c6d8aceb4134e1))

### Testing

- **nix**: check plugin.json against DMS's published plugin schema ([`8c4b983`](https://github.com/gfriloux/astropath/commit/8c4b9833943a0f3d941979f4d58bff7596c99f02))
## [0.8.0] — 2026-10-17

### Bug Fixes

- **model**: keep saved-search keys unique so counts cannot collide ([`c379571`](https://github.com/gfriloux/astropath/commit/c379571f96b05d5878fb37cfc5b94180144520f2))
- **view**: decide the search status from the exit code only ([`ac201ea`](https://github.com/gfriloux/astropath/commit/ac201ea3d80647c25bc84c935bd47aae18653665))
- **view**: serialise lazy snippet fetches so results cannot be misattributed ([`912a799`](https://github.com/gfriloux/astropath/commit/912a799ac7c89a1eebd521eb034ef8a357203776))
- **model**: close the three races found by the v0.8.0 branch review ([`1cb8827`](https://github.com/gfriloux/astropath/commit/1cb882730978345f5bbf51146239e0829aab3a0e))

### Documentation

- translate project documentation to English ([`338eb33`](https://github.com/gfriloux/astropath/commit/338eb33a4df0c628425aa7628e92cd5c009a84e4))
- record the v0.8.0 manual validation ([`05ca1e8`](https://github.com/gfriloux/astropath/commit/05ca1e82bbc567fce8d7943f7e7af34fc9e6b7fe))
- changelog v0.8.0 ([`1171f1d`](https://github.com/gfriloux/astropath/commit/1171f1d6363c07529f2be7339620851dcfbaf3dd))

### Refactoring

- **model**: extract the category override algebra into a pure module ([`295f803`](https://github.com/gfriloux/astropath/commit/295f803fd3d020e27b56ed068cf820cab34b8fae))
## [0.7.1] — 2026-07-19

### Bug Fixes

- **view**: rendre le rail des catégories défilable ([`875e0bf`](https://github.com/gfriloux/astropath/commit/875e0bf5b901cf199d2582397ce51df91f9fd3c2))

### Documentation

- changelog v0.7.1 ([`e8e87e6`](https://github.com/gfriloux/astropath/commit/e8e87e6aa191072d5e9de1d483dd47999c88f642))
## [0.7.0] — 2026-06-27

### Documentation

- **plan**: cadrer v0.6.0 (catégories auto-découvertes, opt-out) ([`8d26b42`](https://github.com/gfriloux/astropath/commit/8d26b4292fad3a564eda1f3a6cf224fc591592c8))
- changelog v0.7.0 ([`4aa8e40`](https://github.com/gfriloux/astropath/commit/4aa8e40fca97c256aa17c62fe427306dbcb9384e))

### Features

- **query**: découverte des tags notmuch ([`3ec6d85`](https://github.com/gfriloux/astropath/commit/3ec6d85bdb0829906b95dbd341a2fb17653cd7e2))
- **model**: catégories auto-dérivées des tags ([`3ca1127`](https://github.com/gfriloux/astropath/commit/3ca11278395300302af27c5ff11b389d7eb577e4))
- **view**: peupler le rail depuis les tags ([`a5b66ae`](https://github.com/gfriloux/astropath/commit/a5b66aeec42c74d02119d3c56dc96163b137df5e))
- **view**: réglages d'amendement des catégories ([`eb0bc64`](https://github.com/gfriloux/astropath/commit/eb0bc640b56e40f093e971629ba4ed4bc8dfe29a))
## [0.6.0] — 2026-06-27

### Documentation

- aligner la sélection du rail sur l'impl (fond tinté, pas de bord) ([`5fc5972`](https://github.com/gfriloux/astropath/commit/5fc597218c99c1a9ca04bb8f81fd447b2129591d))

### Features

- **dev**: instance DMS isolée pour tester le worktree ([`dae0401`](https://github.com/gfriloux/astropath/commit/dae0401243c9a6f797ef975e9b5704371aece405))
## [0.5.0] — 2026-06-21

### Documentation

- plan v0.5.0 (polish visuel du cockpit) ([`8c22320`](https://github.com/gfriloux/astropath/commit/8c2232017c6926c9f7543c510daccfa7530cb345))
- bilan v0.5.0 (polish visuel implémenté, ci verte) ([`c8af1b6`](https://github.com/gfriloux/astropath/commit/c8af1b6afbc5f5aa290354c645ffcc8e39ed8c9a))
- corriger la convention d'email des commits (guillaume@friloux.me) ([`8c6847f`](https://github.com/gfriloux/astropath/commit/8c6847f0d1a6d36a94449f4980177b82b79f7c30))
- clôturer le bilan v0.5.0 (validé visuellement, ajustements post-relecture) ([`e7ae417`](https://github.com/gfriloux/astropath/commit/e7ae4179f1539eabfd21d9cc7ff33d01dde8c1b0))

### Features

- **view**: hiérarchiser émetteur/sujet/snippet dans ThreadRow ([`38aa868`](https://github.com/gfriloux/astropath/commit/38aa8684367e9c8aaf3b3e8e92baaeb4f5deb4c6))
- **view**: séparateurs en dégradé entre les fils ([`8c90e00`](https://github.com/gfriloux/astropath/commit/8c90e0095b3334082149f017d7e809c2af58171c))
- **view**: bord d'accent mauve et transitions hover/sélection ([`a13a1d3`](https://github.com/gfriloux/astropath/commit/a13a1d310debf4af3cf4e48d762d798225623b43))
- **view**: révélation animée de la barre d'actions ([`24a4403`](https://github.com/gfriloux/astropath/commit/24a4403a740f9561e7cb724e2b302e2d42aeec89))
- **view**: ripple et infobulles sur les boutons d'action ([`128556a`](https://github.com/gfriloux/astropath/commit/128556a15c236ccb67c62e05dd1f4e17e7dbaf7a))
- **view**: renforcer la hiérarchie émetteur/sujet/snippet ([`1cf59fa`](https://github.com/gfriloux/astropath/commit/1cf59fa844b9620d75f693c0a89e29c1f4abdc3f))
- **view**: retirer le bord mauve du fil actif ([`c925499`](https://github.com/gfriloux/astropath/commit/c9254993bc9d649a3e439843977f0302e7d0f9a4))
- **view**: agrandir le popup cockpit (680x680) pour la lisibilité ([`9a83036`](https://github.com/gfriloux/astropath/commit/9a83036e3568bac071a5ac7b21c6747a88ed648a))
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
- document release tooling and close release plan ([`2af534c`](https://github.com/gfriloux/astropath/commit/2af534cc74fc6952bc87728cb9a01610b04cee5a))

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

