RENDERER := docker run -it --rm \
	-v $(shell pwd)/resume:/resume \
	-v $(shell pwd)/resume/id.jpg:/app/id.jpg \
	hackmyresume

GA := $(shell printf '%q' "$$(cat resume/ga.html|tr '\n' ' ')")

all: docs/index.html docs/ilya-biin-software-engineer.pdf

renderer/build.done: renderer/Dockerfile renderer/themes
	docker build --rm -t hackmyresume renderer
	touch renderer/build.done

shell: image
	$(RENDERER) bash

docs/id.jpg: resume/id.jpg
	cp resume/id.jpg docs/id.jpg

docs/index.html: renderer/build.done docs/id.jpg resume/data.json resume/html.json
	$(RENDERER) hackmyresume build /resume/data.json /resume/html.json TO /resume/out/resume-eloquent.html \
		-t node_modules/jsonresume-theme-eloquent
	cat resume/out/resume-eloquent.html | \
		sed 's|"#download"|"/cv/ilya-biin-software-engineer.pdf" download|' | \
		sed "s|</head>|$(GA)</head>|" \
		> docs/index.html

docs/ilya-biin-software-engineer.pdf: renderer/build.done resume/id.jpg resume/data.json
	$(RENDERER) hackmyresume build /resume/data.json TO /resume/out/resume-stackoverflow.pdf \
		-t node_modules/jsonresume-theme-stackoverflow
	cp resume/out/resume-stackoverflow.pdf docs/ilya-biin-software-engineer.pdf
