# Ontology of Adverse Events (OAE) Makefile
# Jie Zheng
#
# This Makefile is used to build artifacts for the Ontology of Adverse Events
#

### Configuration
#
# prologue:
# <http://clarkgrubb.com/makefile-style-guide#toc2>

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

### Definitions

SHELL := /bin/bash
OBO   := http://purl.obolibrary.org/obo
OAE    := $(OBO)/OAE_
TODAY := $(shell date +%Y-%m-%d)

### Directories
#
# This is a temporary place to put things.
build:
	mkdir -p $@


### ROBOT
#
# We use the latest official release version of ROBOT
build/robot.jar: | build
	curl -L -o $@ "https://github.com/ontodev/robot/releases/latest/download/robot.jar"

ROBOT := java -jar build/robot.jar


### Build
#
# Here we create a standalone OWL file appropriate for release.
# This involves merging, reasoning, annotating,
# and removing any remaining import declarations.

build/oae_merged.owl: src/oae_edit.owl | build/robot.jar build
	$(ROBOT) merge \
	--input $< \
	annotate \
	--ontology-iri "$(OBO)/oae/oae_merged.owl" \
	--version-iri "$(OBO)/oae/releases/$(TODAY)/oae_merged.owl" \
	--annotation owl:versionInfo "$(TODAY)" \
	--output build/oae_merged.tmp.owl
	sed '/<owl:imports/d' build/oae_merged.tmp.owl > $@
	rm build/oae_merged.tmp.owl

oae.owl: build/oae_merged.owl
	$(ROBOT) reason \
	--input $< \
	--reasoner ELK \
	annotate \
	--ontology-iri "$(OBO)/oae.owl" \
	--version-iri "$(OBO)/oae/releases/$(TODAY)/oae.owl" \
	--annotation owl:versionInfo "$(TODAY)" \
	--output $@

oae-base.owl: oae.owl
	$(ROBOT) remove --input oae.owl \
	--base-iri '$(OAE)' \
	--axioms external \
	--preserve-structure false \
	--trim false \
	annotate \
	--ontology-iri "$(OBO)/oae-base.owl" \
	--version-iri "$(OBO)/oae/releases/$(TODAY)/oae-base.owl" \
	--output $@ 

robot_report.tsv: oae-base.owl
	$(ROBOT) report \
	--input $< \
        --fail-on none \
	--output $@

### 
#
# Full build
.PHONY: all
all: oae.owl oae-base.owl robot_report.tsv

# Remove generated files
.PHONY: clean
clean:
	rm -rf build



