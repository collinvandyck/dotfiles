# Known CI Failure Patterns

Patterns observed in past investigations. Read AFTER forming initial theories, not before.

## Patterns

- **Port-binding races**: connection refused errors during test setup, especially in cross-region/XDC tests
- **Namespace cache propagation**: tests fail because namespace state hasn't propagated to all clusters
- **WAL lock contention**: tests waiting on `/tmp/cds-wal.lock` — check if a previous test's teardown was slow
- **Cassandra schema pressure**: slow schema creation causing timeouts in early tests

## Ignore list

(Nothing yet — add patterns here that were incorrectly matched or are no longer relevant)
