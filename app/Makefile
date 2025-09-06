IMAGE ?= ghcr.io/your-org/web-app
TAG ?= dev
.PHONY: build push run kind-load
build:
	docker build -t $(IMAGE):$(TAG) .
push:
	docker push $(IMAGE):$(TAG)
run:
	docker run --rm -p 8080:8080 -e WEB_MESSAGE="Hello Local" $(IMAGE):$(TAG)
kind-load:
	kind load docker-image $(IMAGE):$(TAG)