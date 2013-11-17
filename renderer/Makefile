all: build.done

build.done: Dockerfile themes
	docker build --rm -t hackmyresume .
	touch build.done
