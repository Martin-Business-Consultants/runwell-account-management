# Account management for Runwell

Keeps every client in play for the project managers it's switched on for: a Today list across
their clients, every contact logged and quiet clients flagged, requests answered within a business
day, meetings on a rhythm with agendas and recaps drafted from the records, nudges for what clients
owe us, weekly health, who's who at each client, onboarding and offboarding checklists, backup
leads, an optional weekly digest for clients, the access register, weekly updates and a scorecard.

**After every call**, paste your notes into your AI app and say "debrief this call": it plans todos
on the right engagements with owners by expertise (Accounts > People), shows you the plan, then
records the call and everything that came out of it (`debrief_call`, `record_call`).

**[Read the guide](docs/guide.md)**, also in Runwell under Accounts > Guide.

A plugin for [Runwell](https://github.com/Martin-Business-Consultants/runwellv2), the core of an
agency's project management. It owns its tables (`account_management_*`), points at core records by id, and
extends Runwell only through its plugin hooks, so removing it leaves Runwell as it was.

## Install

In Runwell, **Settings > Plugins > Add a plugin**: press Install on Account management, or enter
`Martin-Business-Consultants/runwell-account-management`. Runwell downloads the latest release onto the server, restarts and creates the
plugin's tables. It starts off: switch it on in Settings > Plugins.

Then, in **Settings > Account management**, switch it on for the people who look after clients
(your project managers). Each of them chooses the clients they work with (all, or a group) in
**Accounts > My clients**. People it isn't on for don't see it.

From the command line on the server: `bin/rails "plugins:install[Martin-Business-Consultants/runwell-account-management]"`, then restart
Runwell.

Needs Runwell 2.1.3 or later. A plugin can use only the gems Runwell bundles.

## Updating

Settings > Plugins shows an Update button on the plugin when a newer release is out (it checks
nightly, or with Check for updates). The plugin updates only when someone presses it; if the new
release won't load, the previous one comes back.

## Developing

Clone this repository beside a Runwell checkout and link it in, from Runwell's directory:

```sh
bin/rails "plugins:link[../runwell-account-management]"
bin/rails db:migrate
bin/dev
```

## Releasing

Bump `VERSION` in `lib/account_management/version.rb`, commit, then tag and publish a GitHub release:

```sh
git tag v0.2.0 && git push origin main v0.2.0
gh release create v0.2.0 --generate-notes
```

Installs see it in Settings > Plugins.

## License

[FSL-1.1-MIT](LICENSE.md), like Runwell.
