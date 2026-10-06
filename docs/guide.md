# Account management: the guide

Account management keeps every client in play. It does five things, each a page in the Accounts
sidebar:

1. **Today**: what needs you across your clients, most urgent first.
2. **Clients**: who leads each one, how it's doing this week, and when it last heard from us.
   Riskiest first.
3. **Contacts**: every call, email, text and visit, so a client never goes quiet unnoticed.
4. **Meetings**: an agenda a day ahead, a recap within a day after, and action items that become
   commitments.
5. **Calls**: your notes from a call, debriefed by AI into work on the right engagements, owned by
   the right people.

The same guide is in Runwell under **Accounts > Guide**.

## Setting it up (an owner, once)

1. **Install it.** Settings > Plugins > Add a plugin > Account management, then switch it on.
2. **Switch it on for the people who look after clients.** Settings > Account management lists
   your people: press **Switch on** beside each. Only they get Accounts in their menu, a Today list
   and warnings on their home page, and only they can lead or back up a client.
3. **Say what each person does.** On the same page, give everyone on the team a few words (code,
   design, content, seo, ads…). That's how work from a call finds its owner.
4. **Give every client a lead and a backup** on its **Account management** tab. Clients without a
   lead show up for managers until they have one.

Each person then chooses their clients in **Accounts > My clients**: every client, or a group. The
ones they lead or back up are always theirs.

## Every day

- **Work Today from the top**: Overdue, Today, This week, then Keep an eye on. Each item links to
  where you act on it. Not ready? **Snooze** it (the bell): it comes back on its own.
- **Log every contact.** Press **a** for quick actions, then **Contact**, or use **Log a contact**
  on the client's tab. Meetings, call and email notes, requests and agreements count on their own;
  internal notes don't. A client is quiet after 7 days without us, unless its lead sets another
  cadence.
- **Answer requests within a business day.** A request is answered when it's triaged, or when you
  log a contact with that client after it came in. One that came in on Friday is due by the end of
  Monday.
- **By the end of Thursday, set each client's health**: on track, at risk or off track, with a line
  saying why (needed unless it's on track).

## Every meeting

1. **Plan it**, or set a rhythm (every week, every two weeks, monthly) on the client's tab so the
   next one is always planned.
2. **Draft the agenda from the records**: what's open from last time, what each side owes,
   decisions we need from them, and what's coming up. Add what the records can't know and send it
   **a day ahead**.
3. **After it, start the recap from the agenda**, fill in the decisions, add each action item with
   an owner and a date (they become commitments), and send it **within a day**.

## After every call: debrief it

1. Paste your notes into your AI app (Claude Code with the `runwell` CLI, or any app connected to
   Runwell) and say **"debrief this call with <client>"**. It reads the client's open engagements
   and their agreed scope, its people, and the team's expertise and workload (`debrief_call`).
2. **It shows you the plan first**: each todo with its engagement, owner and due date, the
   commitments, requests for anything outside the agreed scope, and health. Say what to change.
3. **Then it records the call** (`record_call`): the notes, the contact and every item at once,
   listed under **Calls**.

Each todo goes on the engagement whose agreed scope covers it; an ask nobody agreed to becomes a
request to triage. The owner is whoever's expertise fits, then whoever has less open work;
client-facing work goes to the lead; nobody who's away. No AI app to hand? The client's tab has
**Debrief a call** with **Copy for AI**.

## When you're away

Set **Away until** in My clients (or an owner sets it in Settings > Account management). While
you're away, each client you lead goes to its backup: their Today and their home warnings.

## With an AI agent

Everything here is also a tool for a connected AI (Settings > Connected apps), and the debrief
workflow is built in. Start with `show_account_today`, log contacts with `log_client_contact`, and
draft agendas with `draft_meeting_agenda`. Anything that emails a client asks you to confirm first.
