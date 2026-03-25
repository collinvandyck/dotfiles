---
  name: do-no-use-test-debug-flaky-test
  description: Debug a flaky integration test
  argument-hint: TEST_NAME PACKAGE
  ---

  If $ARGUMENTS is empty, ask the user for the test name and package path
  before proceeding. Otherwise parse $ARGUMENTS[0] as TEST_NAME and
  $ARGUMENTS[1] as PACKAGE.

  Then run the test 20 times...
