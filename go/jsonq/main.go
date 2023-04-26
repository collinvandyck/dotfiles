package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

/*
This program unescapes quoted json
*/

func main() {
	s := bufio.NewScanner(os.Stdin)
	for s.Scan() {
		text := s.Text()
		if len(text) < 2 {
			continue
		}
		if !strings.HasPrefix(text, `"`) || !strings.HasSuffix(text, `"`) {
			continue
		}
		text = text[1 : len(text)-1]
		text = strings.Replace(text, `\"`, `"`, -1)
		text = strings.Replace(text, `\\`, `\`, -1)
		fmt.Println(text)
	}
}
