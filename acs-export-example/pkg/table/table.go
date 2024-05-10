package table

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/lipgloss/table"
	"github.com/pkg/errors"
	"golang.org/x/term"

	storage "github.com/stackrox/rox/generated/storage"
)

func RenderTable(deployments []*storage.Deployment, images []*storage.Image) error {
	imageMap := map[string]*storage.Image{}

	for _, image := range images {
		imageMap[image.Name.FullName] = image
	}

	width, _, err := term.GetSize(0)
	if err != nil {
		panic(errors.Wrap(err, "could not get terminal size"))
	}

	t := table.New().
		Border(lipgloss.NormalBorder()).
		BorderStyle(lipgloss.NewStyle().Foreground(lipgloss.Color("#84A59D"))).
		Width(width).
		StyleFunc(func(row, col int) lipgloss.Style {
			switch {
			case row == 0:
				return lipgloss.NewStyle().Bold(true)
			case row%2 == 0:
				return lipgloss.NewStyle().Foreground(lipgloss.Color("#EA9285"))
			default:
				return lipgloss.NewStyle().Foreground(lipgloss.Color("#F5CAC3"))
			}
		}).
		Headers("CVE", "CVSS", "Cluster", "Namespace", "Image", "Component", "Fixable")

	for _, d := range deployments {
		for _, container := range d.Containers {
			imageName := container.Image.Name.FullName

			if strings.Contains(imageName, "openshift-release-dev") {
				continue
			}

			image, found := imageMap[imageName]
			if !found || image.Scan == nil {
				continue
			}

			if len(imageName) > 60 {
				imageName = imageName[:57] + "..."
			}

			for _, component := range image.Scan.Components {
				for _, vuln := range component.Vulns {
					fixable := ""
					if vuln.GetFixedBy() != "" {
						fixable = "fixable"
					}

					t.Row(vuln.Cve, fmt.Sprint(vuln.Cvss), d.ClusterName, d.Namespace, imageName, component.Name, fixable)
				}
			}
		}
	}

	fmt.Println(t)
	return nil
}
