package filter

import (
	"bytes"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/stackrox/contributions/acs-export-example/pkg/config"
	storage "github.com/stackrox/rox/generated/storage"
)

func keepVulnBasedOnFixableFilter(vuln *storage.EmbeddedVulnerability, fixableFilter string) bool {
	if fixableFilter == "" {
		return true
	}

	fixable := "true"

	if vuln.GetFixedBy() == "" {
		fixable = "false"
	}

	return fixableFilter == fixable
}

func ClientVulnFilter(deployments []*storage.Deployment, images []*storage.Image, cfg config.ConfigType, stats *config.Stats) (filteredDeployments []*storage.Deployment, filteredImages []*storage.Image) {
	start := time.Now()
	for _, image := range images {
		vulnFound := false
		if image.Scan != nil {
			for _, component := range image.Scan.Components {
				vulnsToKeep := []*storage.EmbeddedVulnerability{}
				for _, vuln := range component.Vulns {
					if strings.Contains(vuln.Cve, cfg.VulnerabilityFilter) && keepVulnBasedOnFixableFilter(vuln, cfg.FixableFilter) {
						vulnFound = true
						vulnsToKeep = append(vulnsToKeep, vuln)
					}
				}
				component.Vulns = vulnsToKeep
			}
		}

		if vulnFound {
			filteredImages = append(filteredImages, image)
		}
	}

	stats.ImageFilterDuration = stats.ImageFilterDuration + (time.Now().Sub(start))
	stats.FilteredImageExportCount = len(filteredImages)

	filteredDeployments = deployments
	return
}

func ClientFilter(deployments []*storage.Deployment, images []*storage.Image, cfg config.ConfigType, stats *config.Stats) (filteredDeployments []*storage.Deployment, filteredImages []*storage.Image) {

	start := time.Now()
	for _, deployment := range deployments {
		if !strings.Contains(deployment.Namespace, cfg.NamespaceFilter) {
			continue
		}

		if !strings.Contains(deployment.ClusterName, cfg.ClusterFilter) {
			continue
		}

		imageFound := false
		for _, container := range deployment.Containers {
			if strings.Contains(container.Image.Name.FullName, cfg.ImageNameFilter) {
				imageFound = true
				continue
			}
		}

		if !imageFound {
			continue
		}

		filteredDeployments = append(filteredDeployments, deployment)
	}

	stats.DeploymentFilterDuration = time.Now().Sub(start)
	stats.FilteredDeploymentExportCount = len(filteredDeployments)
	start = time.Now()

	for _, image := range images {
		if strings.Contains(image.Name.FullName, cfg.ImageNameFilter) {
			filteredImages = append(filteredImages, image)
		}

	}
	stats.ImageFilterDuration = time.Now().Sub(start)
	stats.FilteredImageExportCount = len(filteredImages)
	return
}

var queryMap = map[string]string{}

func BuildServerQuery(cfg config.ConfigType) string {
	var buffer bytes.Buffer

	for k, v := range cfg.QueryStrings() {
		if strings.TrimPrefix(v, "r/") != "" {
			buffer.WriteString(fmt.Sprintf("%s:%s", k, v))
			buffer.WriteString("+")
		}
	}

	ret := buffer.String()

	if len(ret) > 0 {
		os.Stderr.WriteString(fmt.Sprintf("Server query: %s\n", ret[:len(ret)-1]))
		return ret[:len(ret)-1]
	}
	return ""
}
