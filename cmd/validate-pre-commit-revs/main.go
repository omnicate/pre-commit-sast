package main

import (
	"fmt"
	"os"
	"regexp"

	"gopkg.in/yaml.v3"
)

const configPath = ".pre-commit-config.yaml"

var shaPattern = regexp.MustCompile("^[0-9a-f]{40}$")

type config struct {
	Repos []repo `yaml:"repos"`
}

type repo struct {
	Repo string `yaml:"repo"`
	Rev  string `yaml:"rev"`
}

func main() {
	content, err := os.ReadFile(configPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s not found: %v\n", configPath, err)
		os.Exit(1)
	}

	var cfg config
	if err := yaml.Unmarshal(content, &cfg); err != nil {
		fmt.Fprintf(os.Stderr, "failed to parse %s: %v\n", configPath, err)
		os.Exit(1)
	}

	var errors []string
	for i, entry := range cfg.Repos {
		if entry.Repo == "" {
			errors = append(
				errors,
				fmt.Sprintf(
					"repos[%d] is missing a valid 'repo' value",
					i+1,
				),
			)
			continue
		}

		if entry.Repo == "local" || entry.Repo == "meta" {
			if entry.Rev != "" {
				errors = append(
					errors,
					fmt.Sprintf(
						"repos[%d] repo %q must not define 'rev'",
						i+1,
						entry.Repo,
					),
				)
			}
			continue
		}

		if !shaPattern.MatchString(entry.Rev) {
			errors = append(
				errors,
				fmt.Sprintf(
					"repos[%d] repo %q must use a full 40-character SHA for 'rev' (got %q)",
					i+1,
					entry.Repo,
					entry.Rev,
				),
			)
		}
	}

	if len(errors) > 0 {
		fmt.Fprintln(
			os.Stderr,
			"Invalid .pre-commit-config.yaml: remote repos must pin 'rev' to a full 40-character git SHA. Only 'local' and 'meta' repos are exempt.",
		)
		for _, err := range errors {
			fmt.Fprintf(os.Stderr, "  - %s\n", err)
		}
		os.Exit(1)
	}
}
