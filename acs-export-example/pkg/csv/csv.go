package csv

import (
	"encoding/csv"
	"fmt"
	"os"

	storage "github.com/stackrox/rox/generated/storage"
)

func RenderCsv(deployments []*storage.Deployment, images []*storage.Image) error {
	imageMap := map[string]*storage.Image{}

	for _, image := range images {
		imageMap[image.Name.FullName] = image
	}

	writer := csv.NewWriter(os.Stdout)
	defer writer.Flush()

	headers := []string{"CVE", "Severity", "CVSS", "Status", "Component", "Fixed In", "Image", "Deployment", "Namespace", "Cluster"}
	writer.Write(headers)

	for _, d := range deployments {
		for _, container := range d.Containers {
			imageName := container.Image.Name.FullName

			image, found := imageMap[imageName]
			if !found || image.Scan == nil {
				continue
			}

			for _, component := range image.Scan.Components {
				for _, vuln := range component.Vulns {
					score := ""
					if vuln.CvssV3 != nil {
						score = fmt.Sprintf("v3: %.2f", vuln.CvssV3.Score)
					} else if vuln.CvssV2 != nil {
						score = fmt.Sprintf("v2: %.2f", vuln.CvssV2.Score)
					}

					status := ""
					if vuln.GetFixedBy() != "" {
						status = "fixable"
					}

					row := []string{vuln.Cve, vuln.Severity.String(), score, status, component.Name, vuln.GetFixedBy(), imageName, d.Name, d.Namespace, d.ClusterName}
					writer.Write(row)
				}
			}
		}
	}

	return nil
}
