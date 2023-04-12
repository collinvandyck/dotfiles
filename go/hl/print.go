package main

import (
	"fmt"
	"io"

	"github.com/fatih/color"
)

type pairPrinter interface {
	print(writer io.Writer, pair pair)
}

type stringPrinter interface {
	print(writer io.Writer, str string)
}

var keyPrinters = map[string]stringPrinter{
	"t":         newColorPrinter(color.New(color.FgHiBlue)),
	"lvl":       newColorPrinter(color.New(color.FgGreen)),
	"msg":       newColorPrinter(color.New(color.FgHiCyan)),
	"op_method": newColorPrinter(color.New(color.FgGreen)),
}

var valPrinters = map[string]stringPrinter{
	"<nil>": newColorPrinter(color.New(color.FgGreen)),
}

func getKeyPrinter(key string) stringPrinter {
	if p, ok := keyPrinters[key]; ok {
		return p
	}
	return colorPrinter{}
}

func getValPrinter(val string) stringPrinter {
	if p, ok := valPrinters[val]; ok {
		return p
	}
	return colorPrinter{}
}

func getPairPrinter(pair pair) pairPrinter {
	keyp := getKeyPrinter(pair.key)
	res := kvPrinter{key: keyp, val: keyp}
	if p, ok := valPrinters[pair.val]; ok {
		res.val = p
	}
	return res
}

type kvPrinter struct {
	key stringPrinter
	val stringPrinter
}

func (p kvPrinter) print(writer io.Writer, pair pair) {
	if pair.key != "" {
		p.key.print(writer, pair.key)
		fmt.Fprint(writer, "=")
	}
	p.val.print(writer, pair.val)
}

type colorPrinter struct {
	color *color.Color
}

func newColorPrinter(color *color.Color) colorPrinter {
	return colorPrinter{
		color: color,
	}
}

func (p colorPrinter) print(writer io.Writer, str string) {
	if p.color != nil {
		p.color.Fprint(writer, str)
		return
	}
	fmt.Fprint(writer, str)
}
