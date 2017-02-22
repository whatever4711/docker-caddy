# vim: set ts=8 sw=8 ai noet:
include builder/CADDY_VERSION
date=$(shell date +%Y%m%dT%H%M)
hash=$(shell git rev-parse --short HEAD)
DREPO=whatever4711/caddy
DOCKERFILE_GENERIC="Dockerfile.generic"
BASE_IMAGE="armhf/alpine:3.5"
ARCH=armhf
TAG1=${ARCH}-${CADDY_VERSION}-cache

.PHONY: all
all: runtime

.PHONY: clean
clean: stop
	@rm -f runtime/caddy || :
	@docker rm -f caddybuild || :
	@docker rmi -f caddybuild || :
	@docker rmi -f caddyfile || :
	@docker rmi -f ${DREPO} || :

.PHONY: stop
stop:
	@docker rm -f caddy || :
	@docker rm -f caddyfile || :

runtime/caddy:
	@sed -e "s|<IMAGE>|${BASE_IMAGE}|g" -e "s|<ARCH>|${ARCH}|g" "builder/${DOCKERFILE_GENERIC}" > builder/Dockerfile
	@docker build -t caddybuild builder/
	@docker rm -f caddybuild || :
	@docker run --name caddybuild caddybuild /home/developer/compile.sh
	@docker cp caddybuild:/home/developer/bin/caddy runtime/

.PHONY: runtime
runtime: runtime/caddy
	@sed -e "s|<IMAGE>|${BASE_IMAGE}|g" -e "s|<ARCH>|${ARCH}|g" "runtime/${DOCKERFILE_GENERIC}" > runtime/Dockerfile
	@docker build \
		-t ${DREPO} \
		runtime/
	@docker images | grep caddy

.PHONY: test
test: stop
	@touch test/env.bash
	@docker build --rm -t caddyfile -f fixtures/Dockerfile.config fixtures/
	@docker create --name caddyfile caddyfile true
	@docker run -d \
		--name caddy \
		--volumes-from caddyfile \
		--read-only \
		-p 80:2020 \
		--cap-drop all \
		${DREPO} -conf /etc/caddy/caddyfile
	sleep 5
	bats test/*.bats


.PHONY: push
push:
	docker tag ${DREPO} ${DREPO}:${TAG1}
	#@docker login -u ${user} -p ${pass}
	docker push ${DREPO}:${TAG1}
	#docker push ${DREPO}:latest
	#@docker logout
