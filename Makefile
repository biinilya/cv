RENDERER := docker run -it --rm \
	-v $(shell pwd)/resume:/resume \
	-v $(shell pwd)/resume/id.jpg:/app/id.jpg \
	hackmyresume

GA := $(shell printf '%q' "$$(cat resume/ga.html|tr '\n' ' ')")
ROLES := $(shell find resume -name "data-*.json" | sed 's|resume/data-||' | sed 's|.json||')
PATCH_TARGETS := $(patsubst %,resume/cv-%.json,$(ROLES))
RENDER_TARGTES := $(patsubst %,docs/ilya-biin-%.pdf,$(ROLES))
NOID_TARGETS := $(patsubst %,docs/ilya-biin-%-noid.pdf,$(ROLES))

define render_pdf
    $(RENDERER) hackmyresume build /resume/cv-$(1).json TO /resume/out/resume-ilya-biin-$(1).pdf \
		-t node_modules/jsonresume-theme-stackoverflow
	cp resume/out/resume-ilya-biin-$(1).pdf docs/ilya-biin-$(1).pdf
endef

define render_pdf_noid
    $(RENDERER) hackmyresume build /resume/cv-$(1).json /resume/noid.json TO /resume/out/resume-ilya-biin-$(1)-noid.pdf \
		-t node_modules/jsonresume-theme-stackoverflow
	cp resume/out/resume-ilya-biin-$(1)-noid.pdf docs/ilya-biin-$(1)-noid.pdf
endef

all: docs/index.html $(PATCH_TARGETS) $(RENDER_TARGTES) $(NOID_TARGETS)

renderer/build.done: renderer/Dockerfile renderer/themes
	docker build --rm -t hackmyresume renderer
	touch renderer/build.done

shell: renderer/build.done
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

resume/cv-%.json: resume/data.json resume/data-%.json
	jsonpatch resume/data.json resume/data-$*.json | python -m json.tool > $@

docs/ilya-biin-%.pdf: resume/data.json resume/cv-%.json
	$(call render_pdf,$*)

docs/ilya-biin-%-noid.pdf: resume/data.json resume/noid.json resume/cv-%.json
	$(call render_pdf_noid,$*)
