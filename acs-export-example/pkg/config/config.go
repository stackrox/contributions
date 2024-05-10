package config

import (
	"bytes"
	"fmt"
	"time"
)

type ConfigType struct {
	Output              string
	ClusterFilter       string
	ImageNameFilter     string
	NamespaceFilter     string
	QueryFilter         string
	VulnerabilityFilter string
	FixableFilter       string
	FilterType          string
	Stats               bool
}

func (cfg *ConfigType) QueryStrings() map[string]string {
	ret := map[string]string{}
	ret["CLUSTER"] = "r/" + cfg.ClusterFilter
	ret["IMAGE"] = "r/" + cfg.ImageNameFilter
	ret["NAMESPACE"] = cfg.NamespaceFilter
	ret["CVE"] = "r/" + cfg.VulnerabilityFilter
	ret["FIXABLE"] = cfg.FixableFilter
	return ret
}

type Stats struct {
	ConnectDuration               time.Duration
	DeploymentExportDuration      time.Duration
	ImageExportDuration           time.Duration
	DeploymentFilterDuration      time.Duration
	ImageFilterDuration           time.Duration
	DeploymentExportCount         int
	ImageExportCount              int
	FilteredDeploymentExportCount int
	FilteredImageExportCount      int
}

func (s *Stats) String() string {
	var buffer bytes.Buffer

	buffer.WriteString("Durations:\n")
	buffer.WriteString(fmt.Sprintf("  Connect: %v\n", s.ConnectDuration))
	buffer.WriteString(fmt.Sprintf("  Deployment Export: %v   \n", s.DeploymentExportDuration))
	buffer.WriteString(fmt.Sprintf("  Image Export: %v        \n", s.ImageExportDuration))
	if s.DeploymentFilterDuration > 0 {
		buffer.WriteString(fmt.Sprintf("  Deployment Filtering: %v\n", s.DeploymentFilterDuration))
	}
	buffer.WriteString(fmt.Sprintf("  Image Filtering: %v     \n", s.ImageFilterDuration))
	buffer.WriteString("\nCounts:\n")
	buffer.WriteString(fmt.Sprintf("  Deployments: %v         \n", s.DeploymentExportCount))
	buffer.WriteString(fmt.Sprintf("  Images: %v              \n", s.ImageExportCount))
	if s.DeploymentFilterDuration > 0 {
		buffer.WriteString(fmt.Sprintf("  Filtered Deployments: %v\n", s.FilteredDeploymentExportCount))
	}
	buffer.WriteString(fmt.Sprintf("  Filtered Images: %v     \n", s.FilteredImageExportCount))

	return buffer.String()
}
