package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"
	"unicode"
)

var (
	out io.Writer = os.Stdout
)

var (
	truncate = flag.Bool("t", false, "truncate output")
	cols     = flag.Int("cols", 0, "truncate to cols")
	tidy     = flag.Bool("tidy", true, "skip empty key value pairs")
)

func main() {
	flag.Parse()
	if *truncate {
		cmd := exec.Command("stty", "-g")
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		err := cmd.Run()
		if err != nil {
			fmt.Fprintf(os.Stderr, "stty: %v\n", err)
			os.Exit(1)
		}
		os.Exit(0)
	}

	err := run()
	if err != nil {
		fmt.Printf("parse: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		line := scanner.Text()
		handle(line)
	}
	return nil
}

func handle(line string) {
	pairs := parse(line)
	handlePairs(pairs)
}

func handlePairs(pairs []pair) {
	preprocessPairs(pairs)
	printPairs(pairs)
}

func preprocessPairs(pairs []pair) {
	for i, p := range pairs {
		switch p.key {
		case "t":
			const layout = "2006-01-02T15:04:05-0700"
			stamp, err := time.Parse(layout, p.val)
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				continue
			}
			dur := time.Since(stamp)
			dur = dur.Truncate(time.Second)
			sign := "-"
			if time.Now().Before(stamp) {
				sign = "+"
			}
			pairs[i].val = fmt.Sprintf("%s%s", sign, dur)
		}
	}
}

func printPairs(pairs []pair) {
	for _, pair := range pairs {
		printPair(pair)
	}
	fmt.Println()
}

func printPair(pair pair) {
	if *tidy {
		if pair.key != "" && strings.TrimSpace(pair.val) == "" {
			return
		}
	}
	printer := getPairPrinter(pair)
	printer.print(out, pair)
}

type pair struct {
	key string
	val string
}

func parse(line string) []pair {
	scanner := newScanner(line)
	tokens := scanner.scan()
	parser := newParser(tokens)
	pairs := parser.parse()
	return pairs
}

type parser struct {
	tokens []token
	pairs  []pair
	pos    int
}

func newParser(tokens []token) *parser {
	return &parser{tokens: tokens}
}

func (p *parser) parse() (res []pair) {
	for !p.atEnd() {
		pair := p.pair()
		res = append(res, pair)
	}
	return res
}

func (p *parser) pair() pair {
	if p.match(other) {
		key := p.previous()
		if p.match(equals) {
			if !p.atEnd() {
				value := p.advance()
				return pair{key: key.val, val: value.val}
			}
			p.rewind()
		}
		p.rewind()
	}
	return p.any()
}

func (p *parser) any() pair {
	token := p.advance()
	return pair{val: token.val}
}

func (p *parser) rewind() {
	p.pos--
}

func (p *parser) match(typs ...tokenType) bool {
	for i, typ := range typs {
		if !p.check(typ) {
			p.pos -= i
			return false
		}
		p.advance()
	}
	return true
}

func (p *parser) check(typ tokenType) bool {
	if p.atEnd() {
		return false
	}
	return p.current().typ == typ
}

func (p *parser) atEnd() bool {
	if p.pos >= len(p.tokens) {
		return true
	}
	if p.current().typ == eof {
		return true
	}
	return false
}

func (p *parser) previous() token {
	return p.tokens[p.pos-1]
}

func (p *parser) current() token {
	return p.tokens[p.pos]
}

func (p *parser) advance() token {
	res := p.current()
	p.pos++
	return res
}

type token struct {
	val string
	typ tokenType
}

type tokenType string

const (
	eof    = tokenType("eof")
	space  = tokenType("space")
	equals = tokenType("equals")
	other  = tokenType("other")
)

type scanner struct {
	input  []rune
	tokens []token
	start  int
	pos    int
}

func newScanner(input string) *scanner {
	return &scanner{
		input: []rune(input),
	}
}

func (s *scanner) scan() []token {
	for !s.atEnd() {
		s.start = s.pos
		r := s.advance()
		switch {
		case isSpace(r):
			s.consume(isSpace)
			s.addValue(space)
		case isEquals(r):
			s.addValue(equals)
		case isQuote(r):
			s.consumeQuotes()
			s.addValue(other)
		case isOther(r):
			s.consume(isOther)
			s.addValue(other)
		default:
			panic(fmt.Errorf("unexpected rune: %v", r))
		}
	}
	s.addToken(token{typ: eof})
	return s.tokens
}

func (s *scanner) addValue(typ tokenType) {
	s.addToken(token{val: string(s.input[s.start:s.pos]), typ: typ})
}

func (s *scanner) addToken(token token) {
	s.tokens = append(s.tokens, token)
}

// the previous rune was ". scan until you find a matching ".
// do not return if \" is encountered.
func (s *scanner) consumeQuotes() {
	wasSlash := false
	for !s.atEnd() {
		r := s.advance()
		switch {
		case r == '"' && !wasSlash:
			return
		case r == '\\':
			wasSlash = true
			continue
		}
		wasSlash = false
	}
}

func (s *scanner) consume(pred runePredicate) {
	for !s.atEnd() {
		if pred(s.current()) {
			s.advance()
			continue
		}
		break
	}
}

func (s *scanner) match(pred func(rune) bool) bool {
	if !pred(s.current()) {
		return false
	}
	s.advance()
	return true
}

func (s *scanner) advance() rune {
	r := s.current()
	s.pos++
	return r
}

func (s *scanner) peek() rune {
	return s.input[s.pos+1]
}

func (s *scanner) current() rune {
	return s.input[s.pos]
}

func (s *scanner) atEnd() bool {
	return s.pos >= len(s.input)
}

type runePredicate func(rune) bool

func and(fns ...runePredicate) runePredicate {
	return func(r rune) bool {
		for _, fn := range fns {
			if !fn(r) {
				return false
			}
		}
		return true
	}
}

func not(fn runePredicate) runePredicate {
	return func(r rune) bool {
		return !fn(r)
	}
}

func is(compare rune) runePredicate {
	return func(r rune) bool {
		return r == compare
	}
}

func isEquals(r rune) bool {
	return r == '='
}

func isSpace(r rune) bool {
	return unicode.IsSpace(r)
}

func isOther(r rune) bool {
	return !isSpace(r) && !isQuote(r) && !isEquals(r)
}

func isQuote(r rune) bool {
	return r == '"'
}
