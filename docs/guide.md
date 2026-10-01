# Account management: the guide

Account management keeps every client in play: who looks after each one, when they last heard from
us, what's waiting on whom, how each one is doing, and what needs you today. This guide is for the
people who use it: project managers and account leads, and the owner who sets it up.

The same guide is in Runwell under **Accounts > Guide**.

## Setting it up (an owner, once)

1. **Install it.** Settings > Plugins > Add a plugin > Account management, then switch it on.
2. **Switch it on for your project managers.** Settings > Account management lists your people.
   Press **Switch on** beside each person who looks after clients. Only they get Accounts in their
   menu, a Today list, and warnings on their home page, and only they can lead or back up a client.
3. **Give every client a lead.** On each client's **Account management** tab, choose its lead
   (someone who may manage accounts does this) and a backup. Clients without a lead show up for
   managers until they have one.

## Your first day (each project manager)

1. **Choose your clients.** Accounts > **My clients**: every client, or the ones you choose. The
   clients you lead or back up are always yours.
2. **Open Today.** Accounts opens on **Today**: everything that needs you across your clients, in
   four groups: Overdue, Today, This week, and Keep an eye on. Work from the top.
3. **For each client you lead,** open its Account management tab and:
   - mark **who's who** (the decision-maker, the day-to-day contact, billing, technical, and how
     they'd rather hear from you): agendas, recaps, nudges and digests go to decision-makers and
     day-to-day contacts first;
   - **set a meeting rhythm** (every week, every two weeks, or monthly) so the next meeting is
     always planned;
   - start its **onboarding** checklist if it's new.

## Every day

- **Work Today from the top.** Each item says what it is, which client, and links to where you act
  on it. Not ready to deal with something? **Snooze** it (the bell): tomorrow, in three days, or
  next week. It comes back on its own.
- **Log every contact.** A call, an email, a text, a chat, a visit: press **a** for quick actions,
  then **Contact**, or use **Log a contact** on the client's tab. It takes ten seconds, and it's
  how Runwell knows a client has heard from you. Meetings, call and email notes, requests,
  agreements and digests count on their own; internal notes don't.
- **Answer requests within a business day.** A request from a client is answered when it's
  triaged, or when you log a contact with that client after it came in. One that came in on
  Friday is due by the end of Monday.

## Every meeting

1. **Plan it**, or let the rhythm plan it. Each meeting's agenda is due **a day ahead**.
2. **Draft the agenda from the records**: on the meeting, **Draft agenda** fills in what's open
   from last time, what we owe, what they owe, decisions we need from them, and what's coming
   up. Read it through, add what the records can't know, and **send** it.
3. **After the meeting**, **Start the recap** puts the agenda's points under Discussed with room
   for Decisions. Add each **action item** with an owner and a date (they become commitments),
   then send the recap **within a day**.

## After every call: debrief it

Your notes from a call become work on the right engagements, owned by the right people, in a
minute.

1. **Once:** an owner or manager sets everyone's **expertise** on Accounts > **People** (code,
   design, content, seo, ads…, or your own words). That's how work finds its owner.
2. **After the call,** paste your notes into your AI app (Claude Code with the `runwell` CLI, or any
   app connected to Runwell) and say **"debrief this call with <client>"**. It knows the steps: it
   reads the client's open engagements and their agreed scope, its people, and the team's expertise
   and workload (`debrief_call`).
3. **It shows you the plan first**: each todo with its engagement, owner and due date, the
   commitments (theirs and ours), requests for anything outside the agreed scope, and health.
   Nothing is written yet. Say what to change.
4. **Then it records the call** (`record_call`): the notes as a call note, the contact, and every
   item at once. It all shows on the call's page, linked from the client's tab.

How it picks: each todo goes on the engagement whose agreed scope covers it; an ask nobody agreed to
becomes a request to triage, not a todo. The owner is whoever's expertise fits, then whoever has
less open work; client-facing and coordinating work goes to the client's lead; nobody who's away.

No AI app to hand? The client's tab has **Debrief a call**, with **Copy for AI**: the same brief,
ready to paste with your notes into any AI.

## When you're waiting on the client

Their overdue commitments, agreements they haven't decided on, and access we asked for and don't
have show under **Waiting on them** on the client's tab, and on Today once they're three days old.
Press **Nudge**: Runwell drafts a short, specific email to the right people, you read it and send
it, and it's logged as contact. Replies come to you.

## Every week

- **By the end of Thursday, set each client's health**: on track, at risk, or off track, with a
  line saying why (needed unless it's on track). It's how the owner sees every client at risk in
  one place (Accounts > Clients, riskiest first), and it opens Friday's update.
- **By the end of Friday, send your weekly update.** It starts from a draft of the week: each
  client's health, last contact, meetings, what shipped, commitments kept and missed, what's due,
  what we're waiting on them for, and accounts needing attention. Add the blockers, the risks,
  and how each client feels.
- **The weekly digest (optional, per client).** Switch on **Weekly digest to the client** on the
  client's tab and, each Friday, Runwell drafts a client-facing summary: work finished that's
  shared with them, meetings, what we're waiting on them for, and what's next from us. Nothing
  internal goes in. Read it, send it, and it counts as contact. It saves a lot of "where are we?"
  emails.

## When you're away

Set **Away until** in My clients (or an owner sets it in Settings > Account management). While
you're away, each client you lead goes to its **backup**: their Today and their home warnings.
Clear the date when you're back.

## Onboarding and offboarding

Each client's tab can run a checklist. **Onboarding:** lead chosen, who's who marked, kickoff
held (recap sent), rhythm set, accounts recorded, access granted, reporting set up, welcome
sent. **Offboarding:** commitments settled, work closed, rhythm stopped, digest stopped,
accounts handed back, goodbye call. Steps that the records can prove tick themselves; you tick
the rest, and the checklist shows on Today until it's done.

## The standards (the playbook)

| Standard | What it means |
| --- | --- |
| Agenda a day ahead | Each meeting's agenda goes out at least 24 hours before it starts |
| Recap within a day | Each meeting's recap goes out within 24 hours after it |
| Commitments by their date | Ours are done on or before the date we promised |
| Weekly update by Friday | Each lead's written update, by the end of Friday |
| Answer within a business day | A client's request is answered by the end of the next business day |
| In touch every week | Every client hears from us within its cadence (7 days unless its lead changes it) |
| Health by Thursday | Each client's health is set for the week by the end of Thursday |

Each lead's **scorecard** (Accounts > Team) measures these from what actually happened, over the
last 30 days, and lists the misses so a conversation starts from facts. Only what's settled
counts: an agenda that can still go out on time, or a request not yet due, waits.

## For the owner

- **Accounts > Team**: every lead's scorecard against the playbook, at a glance.
- **Accounts > Clients**: every client you work with, riskiest first, with health, last contact,
  lead and backup, next meeting, and what's waiting on them.
- **Settings > Account management**: who it's on for, and who's away.

## With an AI agent

Everything here is also a tool for a connected AI (Settings > Connected apps). The **Debrief a
client call** workflow above is built in: Runwell tells the AI the steps. Otherwise, ask it to start
with `show_account_today`, log contacts with `log_client_contact`, draft agendas with
`draft_meeting_agenda`, or preview a nudge with `preview_nudge`. Anything that emails a client asks
you to confirm first.
