package export

import (
	"context"
	"io"
	"time"

	"github.com/pkg/errors"
	"google.golang.org/grpc"

	v1 "github.com/stackrox/rox/generated/api/v1"
	storage "github.com/stackrox/rox/generated/storage"
	"github.com/stackrox/rox/roxctl/common"
	"github.com/stackrox/rox/roxctl/common/auth"
	roxctlIO "github.com/stackrox/rox/roxctl/common/io"
	"github.com/stackrox/rox/roxctl/common/logger"
	"github.com/stackrox/rox/roxctl/common/printer"

	"github.com/stackrox/contributions/acs-export-example/pkg/config"
)

type Exporter struct {
	ctx   context.Context
	conn  *grpc.ClientConn
	stats *config.Stats
}

func New(ctx context.Context, stats *config.Stats) (Exporter, error) {
	defaultIO := roxctlIO.DefaultIO()
	start := time.Now()
	conn, err := common.GetGRPCConnection(auth.TokenAuth(), logger.NewLogger(defaultIO, printer.DefaultColorPrinter()))
	if err != nil {
		return Exporter{}, errors.Wrap(err, "could not establish gRPC connection to central")
	}

	stats.ConnectDuration = time.Now().Sub(start)

	return Exporter{
		ctx:   ctx,
		conn:  conn,
		stats: stats,
	}, nil
}

func (ex *Exporter) GetImages(query string) ([]*storage.Image, error) {
	svc := v1.NewImageServiceClient(ex.conn)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	start := time.Now()
	client, err := svc.ExportImages(ctx, &v1.ExportImageRequest{Query: query})
	if err != nil {
		return nil, errors.Wrap(err, "could not initialize stream client")
	}

	images := []*storage.Image{}
	for {
		image, err := client.Recv()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return nil, errors.Wrap(err, "stream broken by unexpected error")
		}

		images = append(images, image.Image)
	}

	ex.stats.ImageExportDuration = time.Now().Sub(start)
	ex.stats.ImageExportCount = len(images)

	return images, nil
}

func (ex *Exporter) GetDeployments(query string) ([]*storage.Deployment, error) {
	svc := v1.NewDeploymentServiceClient(ex.conn)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	start := time.Now()
	client, err := svc.ExportDeployments(ctx, &v1.ExportDeploymentRequest{Query: query})
	if err != nil {
		return nil, errors.Wrap(err, "could not initialize stream client")
	}

	deployments := []*storage.Deployment{}
	for {
		deployment, err := client.Recv()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return nil, errors.Wrap(err, "stream broken by unexpected error")
		}

		deployments = append(deployments, deployment.Deployment)
	}

	ex.stats.DeploymentExportDuration = time.Now().Sub(start)
	ex.stats.DeploymentExportCount = len(deployments)

	return deployments, nil
}
