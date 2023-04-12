package main

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestParser(t *testing.T) {
	for _, tc := range []struct {
		input string
		pairs []pair
	}{
		{
			input: "",
			pairs: nil,
		},
		{
			input: "foo",
			pairs: []pair{
				{val: "foo"},
			},
		},
		{
			input: "foo bar",
			pairs: []pair{
				{val: "foo"},
				{val: " "},
				{val: "bar"},
			},
		},
		{
			input: "t=123 foo",
			pairs: []pair{
				{key: "t", val: "123"},
				{val: " "},
				{val: "foo"},
			},
		},
		{
			input: `msg="Hi Collin" foo`,
			pairs: []pair{
				{key: "msg", val: `"Hi Collin"`},
				{val: " "},
				{val: "foo"},
			},
		},
		{
			input: `msg="Hi \"Collin\"!!" foo`,
			pairs: []pair{
				{key: "msg", val: `"Hi \"Collin\"!!"`},
				{val: " "},
				{val: "foo"},
			},
		},
	} {
		t.Run(tc.input, func(t *testing.T) {
			pairs := parse(tc.input)
			require.EqualValues(t, tc.pairs, pairs)
		})
	}
}

func TestScannerOne(t *testing.T) {
	for _, tc := range []struct {
		input string
		res   []token
	}{} {
		t.Run(tc.input, func(t *testing.T) {
			scanner := newScanner(tc.input)
			res := scanner.scan()
			require.EqualValues(t, tc.res, res)
		})
	}
}

func TestScanner(t *testing.T) {
	for _, tc := range []struct {
		input string
		res   []token
	}{
		{
			input: "",
			res: []token{
				{typ: eof},
			},
		},
		{
			input: "foo",
			res: []token{
				{typ: other, val: "foo"},
				{typ: eof},
			},
		},
		{
			input: "foo bar",
			res: []token{
				{typ: other, val: "foo"},
				{typ: space, val: " "},
				{typ: other, val: "bar"},
				{typ: eof},
			},
		},
		{
			input: `foo "bar baz" fuzz`,
			res: []token{
				{typ: other, val: "foo"},
				{typ: space, val: " "},
				{typ: other, val: `"bar baz"`},
				{typ: space, val: " "},
				{typ: other, val: "fuzz"},
				{typ: eof},
			},
		},
		{
			input: `msg="hi \"collin\""`,
			res: []token{
				{typ: other, val: "msg"},
				{typ: equals, val: "="},
				{typ: other, val: `"hi \"collin\""`},
				{typ: eof},
			},
		},
	} {
		t.Run(tc.input, func(t *testing.T) {
			scanner := newScanner(tc.input)
			res := scanner.scan()
			require.EqualValues(t, tc.res, res)
		})
	}
}
