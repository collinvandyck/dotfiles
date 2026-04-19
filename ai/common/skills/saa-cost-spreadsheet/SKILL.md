---
name: saa-cost-spreadsheet
description: create or update the google sheet that calculates when we want to send SAAs to tiere storage
disable-model-invocation: true
---

# Overview

The goal is to create and iterate on the google sheet that calculates when we want to send SAAs to tiered storage.
The concern is that for some combination of variables it might be better to keep SAAs on the hot tier (datastax astra)

To interact with google sheets you should use the `gws` cli, which has already been installed and configured and is on the path.
The name of the spreadsheet should be "SAA TS Cost Analysis".
If the spreadsheet does not exist, we'll need to create it.

If you have not done so already, first explore the tiered storage code. Understand how the jobs are created, how they
are uploaded, and how the same region replica/standby (SRRs) try to avoid re-uploading to object storage in the same 
region. Understand how the TS executor leverages strategies for (workflows,activities) to isolate archetype specific
behavior. Understand how retention is calculated before the TS task is created and how that retention is used in the
executor and the strategies. Understand how the retention drives the DB deletion as well as the TS deletion. Understand
how the tiered storage aggregator batches MS and HE from multiple executions together in object storage.

# Details

There are known variables that will need to be part of the spreadsheet:

- NS retention (by default for now, 24h, but this will be variable in the future via DC)
- Size of CHASM tree for SAAs before they go to TS executor (this will be known, but it hasn't merged yet)
- Cost of Astra per GBh ($0.042/GBh)
- Cost of AWS S3 (you will probably need to search for this. we can exclude GCP for now)

The sheet should rely on formulas to calculate the cutoff point where the cost of Astra given the variables is actually
lower than the cost of sending to TS.

A previous sketch which was abandoned produced this google sheet
https://docs.google.com/spreadsheets/d/1wMeTiRVc-oVr3mtnU780rwEl_mPCf8hsVbTafvcvaIA/edit?gid=203495336#gid=203495336
You can use this to get a better understanding of what we're doing but do not use it to strongly inform the current 
task of creating our new spreadsheet.

# Context

$ARGUMENTS

