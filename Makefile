RENDERER := docker run -it --rm \
	-v $(shell pwd)/resume:/resume \
	-v $(shell pwd)/resume/id.jpg:/app/id.jpg \
	hackmyresume

all: render docs/id.jpg docs/index.html docs/ilya-biin-software-engineer.pdf

image:
	make -C renderer

shell: image
	$(RENDERER) bash

render: image
	$(RENDERER) hackmyresume build /resume/data.json TO /resume/out/resume-stackoverflow.pdf \
		-t node_modules/jsonresume-theme-stackoverflow
	$(RENDERER) hackmyresume build /resume/data.json /resume/html.json TO /resume/out/resume-eloquent.html \
		-t node_modules/jsonresume-theme-eloquent

docs/id.jpg: resume/id.jpg
	cp resume/id.jpg docs/id.jpg

docs/index.html: resume/out/resume-eloquent.html
	cat resume/out/resume-eloquent.html | sed 's|"#download"|"/cv/ilya-biin-software-engineer.pdf" download|' > docs/index.html

docs/ilya-biin-software-engineer.pdf: resume/out/resume-stackoverflow.pdf
	cp resume/out/resume-stackoverflow.pdf docs/ilya-biin-software-engineer.pdf
