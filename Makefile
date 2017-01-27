ifndef $(APP)
APP        := graylog-zabbix-alert-monitor
endif

ifndef $(RELEASE)
RELEASE    := $(shell git tag -l --points-at HEAD)
endif

BRANCH     := $(shell git rev-parse --abbrev-ref HEAD | perl -ne 'print lc' | tr /: -)
COMMIT     := $(BRANCH)-$(shell git rev-parse --short HEAD)
REGISTRY   := eu.gcr.io/sysops-1372
REPOSITORY := $(REGISTRY)/$(APP)

all: docker-image
clean: docker-rmi

ci-build: docker-image docker-push write-version docker-rmi
ci-deploy: deis-deploy

docker-image:
	docker build --force-rm -t $(REPOSITORY):$(COMMIT) .
ifneq ($(RELEASE),)
	docker tag $(REPOSITORY):$(COMMIT) $(REPOSITORY):$(RELEASE)
endif

docker-push:
	docker push $(REPOSITORY):$(COMMIT)
ifneq ($(RELEASE),)
	docker push $(REPOSITORY):$(RELEASE)
endif

write-version:
ifneq ($(RELEASE),)
	echo release=$(RELEASE) > ci-vars.txt
else
	echo release=$(COMMIT)  > ci-vars.txt
endif

docker-rmi:
	docker rmi $(REPOSITORY):$(COMMIT)
ifneq ($(RELEASE),)
	docker rmi $(REPOSITORY):$(RELEASE)
endif

deis-deploy:
ifneq ($(RELEASE),)
	deis pull $(REPOSITORY):$(RELEASE) -a $(APP)
else
	deis pull $(REPOSITORY):$(COMMIT) -a $(APP)
endif
