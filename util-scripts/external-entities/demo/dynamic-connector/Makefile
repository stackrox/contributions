ifeq ($(TAG),)
TAG=$(shell git describe --tags --abbrev=10 --dirty)
endif

.PHONY:
build:
	docker build -t dynamic-connector .
	docker tag dynamic-connector quay.io/$(REPOSITORY)/dynamic-connector:$(TAG)
	docker push quay.io/$(REPOSITORY)/dynamic-connector:$(TAG)
