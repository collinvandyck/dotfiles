import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("tts", Path(__file__).parent / "tts.py")
tts = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tts)


def test_strips_heading_lines():
    """Heading lines are removed so the narrator does not read '#'."""
    out = tts.markdown_to_speech("# The WAL Tour\n\nThe write-ahead log is the point.")
    assert out.strip() == "The write-ahead log is the point."


def test_strips_inline_emphasis_and_code_ticks():
    """Emphasis and backticks are stripped; the words survive."""
    out = tts.markdown_to_speech("The *flush* path calls `Sync` and it _matters_.")
    assert out.strip() == "The flush path calls Sync and it matters."


def test_link_becomes_its_text():
    """Markdown links collapse to their visible text."""
    out = tts.markdown_to_speech("See [the bookie writer](http://x) for details.")
    assert out.strip() == "See the bookie writer for details."


def test_paragraphs_are_preserved():
    """Blank-line paragraph breaks survive so chunking has boundaries."""
    out = tts.markdown_to_speech("First idea.\n\nSecond idea.")
    assert out == "First idea.\n\nSecond idea."


def test_snake_case_identifier_becomes_spoken_words():
    """Intra-word underscores become spaces so identifiers read as words, not one run-on token."""
    out = tts.markdown_to_speech("The history_nodes table stores watermarks.")
    assert out.strip() == "The history nodes table stores watermarks."


def test_collapses_multiple_blank_lines():
    """Three or more consecutive newlines collapse to a single paragraph break."""
    out = tts.markdown_to_speech("First.\n\n\n\nSecond.")
    assert out == "First.\n\nSecond."
