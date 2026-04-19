#!/usr/bin/env python3
import os
import subprocess
import unittest

PIPEFMT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pipefmt")


def run(stdin, *args):
    r = subprocess.run(
        [PIPEFMT, *args],
        input=stdin,
        capture_output=True,
        text=True,
        check=True,
    )
    return r.stdout


class TestPipefmt(unittest.TestCase):
    def test_basic_pipe_break(self):
        self.assertEqual(
            run("foo | bar | baz"),
            "foo \\\n  | bar \\\n  | baz\n",
        )

    def test_preserves_pipes_in_single_quotes(self):
        self.assertEqual(
            run("jq '.a | .b'"),
            "jq '.a | .b'\n",
        )

    def test_preserves_pipes_in_double_quotes(self):
        self.assertEqual(
            run('awk "{print $1 | \\"sort\\"}"'),
            'awk "{print $1 | \\"sort\\"}"\n',
        )

    def test_width_fits_no_break(self):
        self.assertEqual(
            run("foo | bar", "-w", "80"),
            "foo | bar\n",
        )

    def test_width_too_long_breaks_pipes(self):
        self.assertEqual(
            run("foo | bar | baz", "-w", "5"),
            "foo \\\n  | bar \\\n  | baz\n",
        )

    def test_width_breaks_long_command_at_flags(self):
        self.assertEqual(
            run("cmd -a value1 -b value2 -c value3", "-w", "20"),
            "cmd -a value1 \\\n  -b value2 \\\n  -c value3\n",
        )

    def test_width_packs_flags_greedily(self):
        self.assertEqual(
            run("cmd -a v1 -b v2 -c v3", "-w", "30"),
            "cmd -a v1 -b v2 -c v3\n",
        )

    def test_no_flags_long_line_unchanged(self):
        self.assertEqual(
            run("aaaa bbbb cccc", "-w", "5"),
            "aaaa bbbb cccc\n",
        )

    def test_empty_input(self):
        self.assertEqual(run(""), "")

    def test_no_pipes_passthrough(self):
        self.assertEqual(run("echo hello"), "echo hello\n")

    def test_joins_existing_continuations(self):
        self.assertEqual(
            run("a \\\n  | b \\\n  | c"),
            "a \\\n  | b \\\n  | c\n",
        )

    def test_idempotent_no_width(self):
        src = "cmd -a v1 | grep x | jq '.a | .b'"
        once = run(src)
        twice = run(once)
        self.assertEqual(once, twice)

    def test_idempotent_with_width(self):
        src = "cmd -a value1 -b value2 -c value3 | grep x"
        once = run(src, "-w", "20")
        twice = run(once, "-w", "20")
        self.assertEqual(once, twice)

    def test_full_pipeline_at_width_30(self):
        src = (
            "tdbg -n host w show -wid AAA -rid BBB --decode "
            "| grep eventId "
            "| jq -s -c '[.[][].eventId | tonumber] | {min:min}'"
        )
        expected = (
            "tdbg -n host w show -wid AAA \\\n"
            "  -rid BBB --decode \\\n"
            "  | grep eventId \\\n"
            "  | jq -s \\\n"
            "    -c '[.[][].eventId | tonumber] | {min:min}'\n"
        )
        self.assertEqual(run(src, "-w", "30"), expected)


if __name__ == "__main__":
    unittest.main()
