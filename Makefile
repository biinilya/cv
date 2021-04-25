RENDERER := docker run -it --rm \
	-v $(shell pwd)/resume:/resume \
	-v $(shell pwd)/resume/id.jpg:/app/id.jpg \
	hackmyresume

GA := $(shell printf '%q' "$$(cat resume/ga.html|tr '\n' ' ')")
ROLES := $(shell find resume -name "data-*.yml" | sed 's|resume/data-||' | sed 's|.yml||')
PATCH_TARGETS := $(patsubst %,resume/cv-%.json,$(ROLES))
RENDER_TARGETS := $(patsubst %,docs/ilya-biin-%.pdf,$(ROLES))
HTML_TARGETS := $(patsubst %,docs/%.html,$(ROLES))
TXT_TARGETS := $(patsubst %,docs/ilya-biin-%.txt,$(ROLES))

JOBS := "ferrum coins gett eti-zrchitect eti-developer"

all: $(PATCH_TARGETS) $(RENDER_TARGETS) $(HTML_TARGETS) $(TXT_TARGETS)

renderer/build.done: renderer/Dockerfile renderer/themes
	docker build --rm -t hackmyresume renderer
	touch renderer/build.done

shell: renderer/build.done
	$(RENDERER) bash

docs/id.jpg: resume/id.jpg
	cp resume/id.jpg docs/id.jpg

resume/cv-%.json: resume/data.yml resume/data-%.yml
	$(eval TMP_YML := $(shell mktemp))
	$(eval TMP_PART := $(shell mktemp))
	$(eval TMP_WORK := $(shell mktemp))
	yq merge -a=append resume/data-$*.yml resume/data.yml > $(TMP_YML)
	for company in $$(yq read $(TMP_YML) experience | grep -v '  ' | cut -f1 -d ':'); do \
		yq read $(TMP_YML) experience.$$company | yq prefix - work[0] > $(TMP_PART); \
		if [ -s $(TMP_WORK) ]; then \
			yq merge --inplace -a=append $(TMP_WORK) $(TMP_PART); \
		else \
			cp $(TMP_PART) $(TMP_WORK); \
		fi \
	done
	yq merge --inplace -a=append $(TMP_WORK) $(TMP_YML);
	yq read -j $(TMP_WORK) > $@
	rm $(TMP_PART) $(TMP_YML) $(TMP_WORK)

docs/ilya-biin-%.pdf: renderer/build.done docs/id.jpg resume/cv-%.json
	$(RENDERER) hackmyresume build /resume/cv-$*.json TO /resume/out/resume-ilya-biin-$*.pdf \
		-t node_modules/jsonresume-theme-stackoverflow
	cp resume/out/resume-ilya-biin-$*.pdf docs/ilya-biin-$*.pdf

docs/ilya-biin-%.txt: renderer/build.done docs/id.jpg resume/cv-%.json
	$(RENDERER) hackmyresume build /resume/cv-$*.json TO /resume/out/resume-ilya-biin-$*.txt
	cp resume/out/resume-ilya-biin-$*.txt docs/ilya-biin-$*.txt

docs/%.html: renderer/build.done docs/id.jpg resume/html.json resume/cv-%.json
	$(RENDERER) hackmyresume build /resume/cv-$*.json /resume/html.json TO /resume/out/resume-ilya-biin-$*.html \
		-t node_modules/jsonresume-theme-stackoverflow
	cat resume/out/resume-ilya-biin-$*.html | \
		sed 's|"#download"|"/ilya-biin-$*.pdf" download|' | \
		sed "s|</head>|$(GA)</head>|" \
		> docs/$*.html
