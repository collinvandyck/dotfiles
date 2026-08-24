#!/usr/bin/env python3
"""Parse PagerDuty alert messages out of saved slack_read_channel tool results.

The Slack MCP tool dumps oversized channel reads to JSON files. Point this at those files,
tagged by which channel they came from, and it emits a deduplicated alert dataset plus the
aggregations that matter for an on-call handoff.

Usage:
    parse_pd_alerts.py --high high1.json high2.json --low low1.json low2.json [--out data.json]

Either --high or --low may be omitted. Output goes to stdout; --out also writes the raw
records as JSON for follow-up queries.
"""

import argparse
import collections
import json
import re
import sys

# PagerDuty Slack messages look like:
#   :large_green_circle: *<https://temporal.pagerduty.com/incidents/Q2AHM...|[FIRING:1] AlertName s-aw040 cds (prod ...)>*
#   :label: *Incident type:* Base Incident
#   :tornado: *Urgency:* High
ALERT_RE = re.compile(r'incidents/(\w+)\|\[(FIRING|RESOLVED):(\d+)\] (\S+) (\S+)(.*?)>')
URGENCY_RE = re.compile(r'\*Urgency:\* (\w+)')
TS_RE = re.compile(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) [A-Z]{3}\]')

# The colored circle encodes PagerDuty state. This is the whole point of reading these
# messages rather than just counting them: green means someone (or the system) closed it.
STATE = {
    'large_green_circle': 'resolved',
    'large_yellow_circle': 'acknowledged',
    'red_circle': 'triggered',
}


def parse_file(path, channel):
    """Return (alerts, human_messages) from one saved tool-result file."""
    with open(path) as fh:
        payload = json.load(fh)
    body = payload['messages']
    alerts, human = [], []
    # Messages in the concise format are separated by blank lines.
    for msg in (m for m in body.split('\n\n') if m.strip()):
        stamps = TS_RE.findall(msg)
        when = stamps[-1] if stamps else None
        match = ALERT_RE.search(msg)
        if match and msg.startswith('PagerDuty'):
            pd_id, _firing, count, alert, cell, labels = match.groups()
            urgency = URGENCY_RE.search(msg)
            state = next((v for k, v in STATE.items() if k in msg), 'unknown')
            alerts.append({
                'time': when,
                'alert': alert,
                'cell': cell,
                'grouped': int(count),
                'urgency': urgency.group(1) if urgency else 'unknown',
                'state': state,
                'pd_id': pd_id,
                'channel': channel,
                'labels': labels.strip(),
            })
        elif when:
            human.append({'time': when, 'channel': channel, 'text': msg.replace('\n', ' | ')})
    return alerts, human


def dedupe(alerts):
    """One record per PagerDuty incident, carrying its LATEST observed state.

    High-urgency alerts are posted to both channels, so raw counts double-count them.
    Keeping the latest state matters even more: an alert can appear triggered early in the
    window and resolved later, and only the last message tells you whether it is still open.
    """
    latest = {}
    for rec in sorted(alerts, key=lambda r: r['time'] or ''):
        pd_id = rec['pd_id']
        if pd_id in latest and latest[pd_id]['channel'] != rec['channel']:
            rec = dict(rec, channel='both')
        latest[pd_id] = rec
    return sorted(latest.values(), key=lambda r: r['time'] or '')


def is_high(rec):
    return rec['channel'] in ('high', 'both')


def report(records, human):
    out = sys.stdout.write
    highs = sum(1 for r in records if is_high(r))
    out(f"{len(records)} unique alerts across {len({r['cell'] for r in records})} cells "
        f"({highs} in the high-urgency channel)\n")
    if records:
        out(f"window: {records[0]['time']} -> {records[-1]['time']}\n")

    out("\n=== STILL OPEN (latest state not resolved) ===\n")
    open_recs = [r for r in records if r['state'] != 'resolved']
    if not open_recs:
        out("  none\n")
    for r in open_recs:
        out(f"  {r['time']}  {r['state']:13} urg={r['urgency']:5} {r['cell']:9} {r['alert']}\n"
            f"      https://temporal.pagerduty.com/incidents/{r['pd_id']}\n")

    out("\n=== BY CELL ===\n")
    by_cell = collections.Counter(r['cell'] for r in records)
    hi = collections.Counter(r['cell'] for r in records if is_high(r))
    out(f"  {'cell':12}{'total':>6}{'high':>6}{'low':>5}\n")
    for cell, n in by_cell.most_common():
        out(f"  {cell:12}{n:>6}{hi[cell]:>6}{n - hi[cell]:>5}\n")

    out("\n=== CELL x ALERT (cells with 5+ alerts) ===\n")
    grouped = collections.defaultdict(collections.Counter)
    spans = collections.defaultdict(list)
    for r in records:
        grouped[r['cell']][r['alert']] += 1
        spans[(r['cell'], r['alert'])].append(r['time'])
    for cell, n in by_cell.most_common():
        if n < 5:
            continue
        out(f"  -- {cell} ({n} total, {hi[cell]} high)\n")
        for alert, k in grouped[cell].most_common():
            times = sorted(t for t in spans[(cell, alert)] if t)
            window = f"{times[0][5:16]} -> {times[-1][5:16]}" if times else ""
            out(f"       {k:>3}  {alert:<58} {window}\n")

    out("\n=== PER-DAY VOLUME ===\n")
    per_day = collections.Counter(r['time'][:10] for r in records if r['time'])
    per_day_high = collections.Counter(r['time'][:10] for r in records if r['time'] and is_high(r))
    for day in sorted(per_day):
        out(f"  {day}  total {per_day[day]:>4}  high {per_day_high[day]:>4}\n")

    out(f"\n=== HUMAN MESSAGES ({len(human)}) ===\n")
    out("These are the ones worth reading: every alert nobody replied to is unattended.\n")
    for h in sorted(human, key=lambda h: h['time']):
        out(f"  [{h['channel']}] {h['time']} :: {h['text'][:220]}\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--high', nargs='*', default=[], metavar='FILE',
                    help='saved tool results from the high-urgency alert channel')
    ap.add_argument('--low', nargs='*', default=[], metavar='FILE',
                    help='saved tool results from the low-urgency alert channel')
    ap.add_argument('--out', metavar='FILE', help='write deduplicated records here as JSON')
    args = ap.parse_args()

    if not args.high and not args.low:
        ap.error('give at least one --high or --low file')

    alerts, human = [], []
    for path in args.high:
        a, h = parse_file(path, 'high')
        alerts += a
        human += h
    for path in args.low:
        a, h = parse_file(path, 'low')
        alerts += a
        human += h

    records = dedupe(alerts)
    if args.out:
        with open(args.out, 'w') as fh:
            json.dump({'alerts': records, 'human': human}, fh, indent=1)
    report(records, human)


if __name__ == '__main__':
    main()
