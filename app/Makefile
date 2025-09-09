IMAGE ?= ghcr.io/your-org/web-app
TAG ?= dev
.PHONY: build push run kind-load smoke docker-smoke
build:
	docker build -t $(IMAGE):$(TAG) .
smoke:
	docker build --target smoke -t $(IMAGE):smoke .
docker-smoke: smoke
	docker run --rm -p 8080:8080 $(IMAGE):smoke /bin/sh -c 'echo smoke image ready'
push:
	docker push $(IMAGE):$(TAG)
run:
	docker run --rm -p 8080:8080 -e WEB_MESSAGE="Hello Local" $(IMAGE):$(TAG)
kind-load:
	kind load docker-image $(IMAGE):$(TAG)