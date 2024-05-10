package cmd

import (
	"bytes"
	"context"
	"fmt"
	"os"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"

	"github.com/stackrox/contributions/acs-export-example/pkg/config"
	"github.com/stackrox/contributions/acs-export-example/pkg/csv"
	"github.com/stackrox/contributions/acs-export-example/pkg/export"
	"github.com/stackrox/contributions/acs-export-example/pkg/filter"
	"github.com/stackrox/contributions/acs-export-example/pkg/table"
)

var cfg = config.ConfigType{}
var stats = &config.Stats{}

var rootCmd = &cobra.Command{
	Use:   "acs-export-example",
	Short: "Use the ACS export APIs",
	Long:  `CLI to browse data pulled from ACS (Advanced Cluster Security) (i.e. StackRox).`,
	Run: func(cmd *cobra.Command, args []string) {
		if err := validateFlags(); err != nil {
			fmt.Printf("%v\n", err)
			os.Exit(1)
		}

		ctx := context.Background()

		exporter, err := export.New(ctx, stats)
		if err != nil {
			panic(errors.Wrap(err, "could not create exporter"))
		}

		query := cfg.QueryFilter

		if cfg.FilterType == "server" {
			query = filter.BuildServerQuery(cfg)
		}

		os.Stderr.WriteString("Fetching deployments\n")
		deployments, err := exporter.GetDeployments(query)
		if err != nil {
			panic(errors.Wrap(err, "could not get deployments"))
		}

		os.Stderr.WriteString("Fetching images\n")
		images, err := exporter.GetImages(query)
		if err != nil {
			panic(errors.Wrap(err, "could not get images"))
		}

		if cfg.FilterType == "client" {
			deployments, images = filter.ClientFilter(deployments, images, cfg, stats)
		}

		// This runs for both client and server filtering because the server
		// doesn't filter out CVEs off of image scans that don't match the CVE filter
		deployments, images = filter.ClientVulnFilter(deployments, images, cfg, stats)

		if cfg.Output == "table" {
			if err = table.RenderTable(deployments, images); err != nil {
				panic(errors.Wrap(err, "Failed to render table"))
			}
		} else if cfg.Output == "csv" {
			if err = csv.RenderCsv(deployments, images); err != nil {
				panic(errors.Wrap(err, "Failed to render table"))
			}
		}

		if cfg.Stats {
			os.Stderr.WriteString(stats.String())
		}
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func contains(a []string, elem string) bool {
	for _, i := range a {
		if i == elem {
			return true
		}
	}

	return false
}

func quoteWrap(a []string) string {
	var buffer bytes.Buffer

	buffer.WriteString("[")
	for i, s := range a {
		buffer.WriteString(fmt.Sprintf("\"%s\"", s))

		if i < len(a)-1 {
			buffer.WriteString(", ")
		}
	}
	buffer.WriteString("]")

	return buffer.String()
}

func validateFlags() error {
	outputOptions := []string{"table", "csv"}
	filterTypeOptions := []string{"client", "server"}
	fixableOptions := []string{"true", "false", ""}

	if !contains(outputOptions, cfg.Output) {
		return errors.Errorf("Invalid value for --output=\"%s\".  Available options: %v", cfg.Output, quoteWrap(outputOptions))
	}

	if !contains(filterTypeOptions, cfg.FilterType) {
		return errors.Errorf("Invalid value for --filter-type=\"%s\".  Available options: %v", cfg.FilterType, quoteWrap(filterTypeOptions))
	}

	if !contains(fixableOptions, cfg.FixableFilter) {
		return errors.Errorf("Invalid value for --fixable=\"%s\".  Available options: %v", cfg.FixableFilter, quoteWrap(fixableOptions))
	}

	if cfg.QueryFilter != "" && cfg.FilterType == "server" {
		return errors.New("Cannot supply a query filter when --filter-type=server")
	}

	return nil
}

func init() {
	rootCmd.PersistentFlags().StringVarP(&cfg.Output, "output", "o", "table", "Output format.  Available options: [table, csv]")
	rootCmd.PersistentFlags().StringVarP(&cfg.NamespaceFilter, "namespace", "n", "", "Namespace client-side filter.")
	rootCmd.PersistentFlags().StringVarP(&cfg.ClusterFilter, "cluster", "c", "", "Cluster client-side filter.")
	rootCmd.PersistentFlags().StringVarP(&cfg.ImageNameFilter, "image", "i", "", "Image name client-side filter.")
	rootCmd.PersistentFlags().StringVarP(&cfg.VulnerabilityFilter, "vuln", "v", "", "Vulnerability client-side filter.")
	rootCmd.PersistentFlags().StringVarP(&cfg.QueryFilter, "query", "q", "", "Pass a query string to the server. Incompatible with --filter-type=server")
	rootCmd.PersistentFlags().StringVarP(&cfg.FixableFilter, "fixable", "f", "", "Filter on whether a cve is fixable.  Available options: [true, false, \"\"].")
	rootCmd.PersistentFlags().StringVarP(&cfg.FilterType, "filter-type", "t", "client", "Where to do the param-based filtering. Available options: [client, server]")
	rootCmd.PersistentFlags().BoolVarP(&cfg.Stats, "stats", "s", false, "Print stats about the export")
}
