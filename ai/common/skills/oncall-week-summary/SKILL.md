---
name: oncall-week-summary
description: Use when starting or handing off a CDS on-call shift, or when asked to summarize the last week of alerts and incidents — "I'm going on call", "what happened last week", "catch me up on alerts", "summarize #alerts-eng-cds", "which cells are problematic". Covers pulling the alert channels and #incidents out of Slack, breaking alerts down by cell, triaging incidents, and publishing the result to Notion.
---

# On-Call Week Summary

Build a birds-eye view of the last N days of CDS alerts and incidents for someone who has not been following along. The reader wants three things: what is on fire, which cells are problematic, and what has been quietly rotting.

## Sources

| Source | Channel ID | What you get |
|---|---|---|
| `#alerts-eng-cds-high` | `C06S9HENUR0` | High-urgency PagerDuty pages plus the on-call discussion threads |
| `#alerts-eng-cds-low` | `C06S2U669M4` | Warning-tier alerts. 3-4x the volume. Where neglect hides |
| `#incidents` | `C031LARN2RY` | incident.io declarations with severity, status, cells, and a summary |

Incident channels are named `inc-<n>-<date>-<slug>`; their IDs come from the `#incidents` post.

## Pulling the alert channels

Compute the window bound first (`date -u -v-7d +%s`), then page with `slack_read_channel`, `response_format: "concise"`, `limit: 100`.

**Pagination runs forward, not backward.** With `oldest` set, the first page is the *oldest* 100 messages in the range even though they are displayed newest-first. Do not conclude the channel went quiet because the top of page one is three days old — keep following the cursor until `pagination_info` says there are no more.

**Oversized results are a feature.** These reads blow past the token limit and get saved to a file under `tool-results/`, costing you nothing in context. Collect the paths and parse them. The cursor for the next page lives *inside* the file, not in the error message:

```sh
python3 -c "import json; print(json.load(open('<path>'))['pagination_info'])"
```

Occasionally a page comes back small enough to land inline. Note it, because the parser cannot see it — either transcribe those records or say in the writeup that the counts exclude them.

## Parsing

Run [parse_pd_alerts.py](parse_pd_alerts.py) over the saved files. It emits the still-open queue, per-cell and cell-x-alert breakdowns with time spans, per-day volume, and every human message.

```sh
parse_pd_alerts.py --high h1.txt --low l1.txt l2.txt l3.txt --out data.json
```

Two things it handles that are easy to get wrong by hand:

- **Deduplicate by PagerDuty incident ID.** High-urgency alerts post to both channels, so raw message counts inflate ~4%.
- **Keep the *latest* state per incident ID, not the first.** The colored circle is the state: green resolved, yellow acknowledged-and-still-firing, red triggered-and-unacknowledged. An alert seen red early in the window may be green later. Only the last message tells you whether it is still open, and **the still-open list is the most valuable output of the whole exercise** — it is the literal backlog being handed over.

Also note that `[FIRING:138]` is one alert carrying 138 grouped instances. Counting alerts measures paging load, which is the right metric for on-call burden. Say so in the writeup so nobody reads the numbers as event counts.

## Incidents

`#incidents` posts carry severity, type, status, cells, impact-start, and often a written summary — enough to triage without opening anything. Then read the channel for each CDS-relevant one; that is where the actual mechanism and the unanswered questions live. Follow the `#team-eng-cds` threads the incident channels link to.

Categorize each as **on fire / needs attention / monitoring / resolved**. These are orthogonal to incident.io status: plenty of incidents sit in `Investigating` months after mitigation. "Needs attention" usually means *mitigated but the mechanism was never found*, or *prevention follow-ups are blocked*.

Deprioritize non-CDS incidents but still list them, with one line on why they are not yours. The reader needs to recognize them, not chase them.

## The analysis passes that pay off

Run these against the parsed data. Each one produced a real finding:

- **Alerts with zero human replies.** Cross-reference cell names in the human messages against the per-cell counts. A cell with 30 high-urgency pages and no discussion is an alerting-hygiene problem, not a healthy cell.
- **Time spans per cell-x-alert.** A signal confined to one 6-hour burst is a different story from the same count spread over seven days. The parser prints both endpoints.
- **Repeating clock times.** Look for alerts landing in the same 5-minute window on consecutive days — that is something scheduled, and it is usually the cheapest fix available.
- **Same alert on N cells with identical counts.** Even distribution means a systemic cause, not N independent problems.
- **Single-signal cells.** One alert family accounting for most of a cell's volume points straight at a subsystem.
- **Infra-plane rows.** `newton` and friends are not cells. A failing capacity workflow there means humans are silently doing its job.

## Publishing

Follow the `notion` skill for page mechanics. Structure that worked:

1. A red callout naming the one live thing and the decision the reader owns.
2. **Start here** — five numbered items, most urgent first.
3. Inline **Incidents** database, with a four-bucket summary underneath.
4. Inline **Cell Watchlist** database, plus a top-ten table and a per-day volume table for scanning.
5. A table of every still-open PagerDuty alert, unacknowledged rows in `red_bg`.
6. **Patterns worth naming** — numbered subsections, one mechanism each.
7. Alerting hygiene: what changed, and which debates are unsettled.
8. **Questions with no answer in any channel**, attributed by name and timestamp. These are the cheapest contributions available to an incoming on-call.
9. A collapsed provenance block.

Create the incidents database first, then the cell database with a `RELATION` to it, then `replace_content` on the page with `<database url="..." inline="true">` tags positioned where you want them.

Suggested schemas:

- **Incidents:** Incident (title), Triage (select), CDS relevance (select), Severity, Status, Cells, Impact started (date), Slack (url), Jira, What happened, Where it stands.
- **Cell Watchlist:** Cell (title), Status (select), Cloud (select), Alerts / High-urgency / Low-urgency (number), Dominant signals, What is going on, Still open in PD, Related incidents (relation), Next step.

Give every cell a row, including the one-alert tail. It costs little and it is what makes the table trustworthy.

## Provenance

The reader will audit this. Separate what you counted from what you concluded:

- Attribute every claim about cause to the person who said it, by name and date.
- Mark your own triage verdicts as yours, in the provenance block.
- Flag inferred fields explicitly. Cloud-from-cell-prefix (`s-aw*` → AWS, `s-gc*` → GCP) is a guess, not a lookup.
- State the exact window, the dedup rule, and the grouped-instance caveat.
- Note incident-numbering mismatches: the Slack channel and incident.io use one number, the linked Jira issue another. Record both.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Assuming pagination goes backward | You silently drop the most recent days — the ones that matter most |
| Counting raw messages | ~4% inflation, and the per-cell ranking shifts |
| Keeping first-seen alert state | The still-open queue is wrong, which is the one thing the reader acts on |
| Treating incident.io `Investigating` as unresolved | Half the list looks live when it is mitigated-but-unexplained |
| Ranking cells by volume alone | The loudest cell was a decommissioned one; the dangerous one had 3 alerts |
| Omitting the long-tail cells | Reader cannot tell whether the table is complete |
| Blending observed facts with your read | Collin audits provenance and will find it |
