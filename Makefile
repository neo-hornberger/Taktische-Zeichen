# Alle Jinja2 Templates im Ordner symbols finden
ifeq ($(strip $(SOURCES)),)
SOURCES = $(shell find symbols/ -name *.j2)
endif
#TEMPLATES = $(shell find symbols/ -name *.j2t)

# symbols/ prefix entfernen für die Ausgabedateien
TARGET_PATHS = $(SOURCES:symbols/%=%)

# Zieldateien für SVG und PNG Ausgabe festlegen
SVG_TARGETS = $(TARGET_PATHS:.j2=.svg)
PNG_TARGETS = $(TARGET_PATHS:.j2=.png)

SVG_FILES = $(addprefix build/default/svg/,$(SVG_TARGETS))
SVG_PRINT_FILES = $(addprefix build/print/svg/,$(SVG_TARGETS))
PNG_1024_FILES = $(addprefix build/default/png/1024/,$(PNG_TARGETS))
PNG_512_FILES = $(addprefix build/default/png/512/,$(PNG_TARGETS))
PNG_256_FILES = $(addprefix build/default/png/256/,$(PNG_TARGETS))
PNG_PRINT_1024_FILES = $(addprefix build/print/png/1024/,$(PNG_TARGETS))
PNG_PRINT_512_FILES = $(addprefix build/print/png/512/,$(PNG_TARGETS))
PNG_PRINT_256_FILES = $(addprefix build/print/png/256/,$(PNG_TARGETS))
STICKERS = $(addprefix build/sticker/,$(PNG_TARGETS))

# Erstellt alle SVG Ausgabedateien
.PHONY: svg print
svg: $(SVG_FILES)
print: $(SVG_PRINT_FILES)

define SVG_CMD
	mkdir -p $(@D)
	j2 --customize j2cli_customization.py $< themes/$(1).json -o $@
endef

build/default/svg/%.svg: symbols/%.j2 
#$(TEMPLATES)
	$(call SVG_CMD,default)

build/print/svg/%.svg: symbols/%.j2 
#$(TEMPLATES)
	$(call SVG_CMD,print)

# Erstellt alle PNG Ausgabedateien
.PHONY: png png_print
png: $(PNG_1024_FILES) $(PNG_512_FILES) $(PNG_256_FILES)
png_print: $(PNG_PRINT_1024_FILES) $(PNG_PRINT_512_FILES) $(PNG_PRINT_256_FILES)

define PNG_CMD
	mkdir -p $(@D)
	unshare --user inkscape -w $(1) -h $(1) $^ -o $@ > /dev/null
	optipng $@
endef

build/default/png/1024/%.png: build/default/svg/%.svg
	$(call PNG_CMD,1024)
	
build/print/png/1024/%.png: build/print/svg/%.svg
	$(call PNG_CMD,1024)

build/default/png/512/%.png: build/default/svg/%.svg
	$(call PNG_CMD,512)

build/print/png/512/%.png: build/print/svg/%.svg
	$(call PNG_CMD,512)

build/default/png/256/%.png: build/default/svg/%.svg
	$(call PNG_CMD,256)
	
build/print/png/256/%.png: build/print/svg/%.svg
	$(call PNG_CMD,256)

.PHONY: stickers
stickers: $(STICKERS)

build/sticker/%.png: build/default/png/512/%.png
	mkdir -p $(@D)
	convert $^ -bordercolor none -background white -alpha background -channel A -blur 20 -level 0,0%% $@

.PHONY: metadata metadata_print
metadata: build/default/metadata.json
metadata_print: build/print/metadata.json

define METADATA_CMD
	@python3 generate_metadata_file.py $^ > $@
endef

build/default/metadata.json: $(SVG_FILES)
	$(METADATA_CMD)

build/print/metadata.json: $(SVG_PRINT_FILES)
	$(METADATA_CMD)

.PHONY: all clean
all: svg print png png_print stickers metadata metadata_print
clean:
	rm -rf build
	rm Taktische-Zeichen.zip

.PHONY: release ci web
release: all
	cd build && zip -r ../Taktische-Zeichen.zip ./*
ci: all
	cd build && zip -r ../release.zip ./*
web: all
	mkdir -p ./web/build
	cp -r ./build/ ./web/
	find build/ -name *.svg > ./web/symbols.lst
