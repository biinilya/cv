RENDERER := docker run -it --rm \
	-v $(shell pwd)/resume:/resume \
	-v $(shell pwd)/resume/id.jpg:/app/id.jpg \
	hackmyresume

GA := $(shell printf '%q' "$$(cat resume/ga.html|tr '\n' ' ')")
ROLES := $(shell find resume -name "data-*.yml" | sed 's|resume/data-||' | sed 's|.yml||')
PATCH_TARGETS := $(patsubst %,resume/cv-%.json,$(ROLES))
RENDER_TARGTES := $(patsubst %,docs/ilya-biin-%.pdf,$(ROLES))
HTML_TARGTES := $(patsubst %,docs/%.html,$(ROLES))

all: $(PATCH_TARGETS) $(RENDER_TARGTES) $(HTML_TARGTES)

renderer/build.done: renderer/Dockerfile renderer/themes
	docker build --rm -t hackmyresume renderer
	touch renderer/build.done

shell: renderer/build.done
	$(RENDERER) bash

docs/id.jpg: resume/id.jpg
	cp resume/id.jpg docs/id.jpg

resume/cv-%.json: resume/data.yml resume/data-%.yml
	yq merge --append resume/data.yml resume/data-$*.yml | \
		python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' > $@

docs/ilya-biin-%.pdf: renderer/build.done docs/id.jpg resume/cv-%.json
	$(RENDERER) hackmyresume build /resume/cv-$*.json TO /resume/out/resume-ilya-biin-$*.pdf \
		-t node_modules/jsonresume-theme-stackoverflow
	cp resume/out/resume-ilya-biin-$*.pdf docs/ilya-biin-$*.pdf

docs/%.html: renderer/build.done docs/id.jpg resume/html.json resume/cv-%.json
	$(RENDERER) hackmyresume build /resume/cv-$*.json /resume/html.json TO /resume/out/resume-ilya-biin-$*.html \
		-t node_modules/jsonresume-theme-eloquent
	cat /resume/out/resume-ilya-biin-$*.html | \
		sed 's|"#download"|"/cv/ilya-biin-$*.pdf" download|' | \
		sed "s|</head>|$(GA)</head>|" \
		> docs/ilya-biin-$*.html
