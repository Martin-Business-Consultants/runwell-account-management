# Account management for Runwell

Keeps every client in play for the people who look after them. Five things, each a page in
the Accounts sidebar:

1. **Today**: what needs you across your clients, most urgent first, with snoozes.
2. **Clients**: each one's lead and backup, its health this week and when it last heard from us.
3. **Contacts**: every call, email, text and visit logged, quiet clients flagged, requests answered
   within a business day.
4. **Meetings**: an agenda a day ahead and a recap within a day, drafted from the records, on a
   rhythm.
5. **Calls**: paste your notes into your AI app and say "debrief this call": it plans todos on the
   right engagements with owners by expertise, shows you the plan, then records it all
   (`debrief_call`, `record_call`).

**[Read the guide](docs/guide.md)**, also in Runwell under Accounts > Guide.

A plugin for [Runwell](https://github.com/Martin-Business-Consultants/runwellv2), the core of project management. It owns its tables (`account_management_*`), points at core records by id, and
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

Needs Runwell 2.21 or later (its pages use the core's section sidebar). A plugin can use only the gems Runwell bundles.

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

## 0.3: five things, done well

0.3 narrows the plugin to the five above. The access register, weekly updates, scorecards and the
playbook page, client digests, nudges, onboarding checklists and who's who are gone; their tables
stay for now and a later release drops them. Expertise moved to Settings > Account management.
