# ----------------------------------------
# Standard Constants
# ----------------------------------------
# these can be overwritten on the command line

OBO=http://www.ebi.ac.uk
ONT=sira
BASE=$(OBO)/$(ONT)
SRC=$(ONT)-edit.owl
BUILDDIR=build
RELEASEDIR=../..
ROBOT= ../../bin/robot
OWLTOOLS= ../../bin/owltools
USECAT= --use-catalog
SPARQLDIR = ../sparql
UPPER = ./imports/upper_class.owl
EFOPREFIX = "EFO: http://www.ebi.ac.uk/efo/EFO_"
SIRAPREFIX = "SIRA: http://www.ebi.ac.uk/sira/SIRA_"
ORDOPREFIX = "Orphanet: http://www.orpha.net/ORDO/Orphanet_"
MONDOPREFIX = "MONDO: http://purl.obolibrary.org/obo/MONDO_"
UBERONPREFIX = "UBERON: http://purl.obolibrary.org/obo/UBERON_"
HPPREFIX = "HP: http://purl.obolibrary.org/obo/HP_"
CLPREFIX = "CL: http://purl.obolibrary.org/obo/CL_"
BFOPREFIX = "BFO: http://purl.obolibrary.org/obo/BFO_"
DOIDPREFIX = "DOID: http://purl.obolibrary.org/obo/DOID_"
MPPREFIX = "MP: http://purl.obolibrary.org/obo/MP_"
NCITPREFIX = "NCIT: http://purl.obolibrary.org/obo/NCIT_"
MIRRORDIR=./mirror

# ----------------------------------------
# Top-level targets
# ----------------------------------------

all: all_imports all_components release qc
qc: sparql_test all_reports
gh_actions: qc $(BUILDDIR)/$(ONT).owl

# ----------------------------------------
# Mirror
# ----------------------------------------

# Currently obtained using the get_mirrors script
# (mondo, hancestro and uberon)

# ----------------------------------------
# Imports
# ----------------------------------------

IMPORTS = doid efo hp mondo mp ncit uberon
IMPORTS_OWL = $(patsubst %, imports/%_import.owl,$(IMPORTS)) $(patsubst %, imports/%_terms.txt,$(IMPORTS))

# Make this target to regenerate ALL
all_imports: $(IMPORTS_OWL)

imports/%_bot.owl: mirror/%.owl imports/%_terms.txt
	$(ROBOT) extract -i $< -T imports/$*_terms.txt --method BOT -O $(BASE)/$@ -o $@

# Use ROBOT, driven entirely by terms lists NOT from source ontology
imports/%_import.owl: imports/%_bot.owl imports/%_terms.txt $(SRC)
	$(ROBOT) filter -i $< --term-file imports/$*_terms.txt --select "annotations ontology anonymous self" --trim true --signature true -O $(BASE)/$@ -o $@
.PRECIOUS: imports/%_import.owl

imports/%_terms.txt: iri_dependencies/%_terms.txt iri_dependencies/efo-relations.txt
	cat $^ | sort | uniq > $@


# ----------------------------------------
# Components
# ----------------------------------------

COMPONENTS=subclasses
COMPONENT_FILES=$(patsubst %, components/%.owl, $(COMPONENTS))

components/subclasses.owl: ../templates/subclasses.csv
	$(ROBOT) template --template $< --prefix $(SIRAPREFIX) --prefix $(MONDOPREFIX)  --prefix $(EFOPREFIX) --prefix $(ORDOPREFIX) --prefix $(UBERONPREFIX) --prefix $(HPPREFIX) --prefix $(DOIDPREFIX) --prefix $(MPPREFIX) --prefix $(NCITPREFIX) --ontology-iri "http://www.ebi.ac.uk/sira/components/subclasses.owl" -o $@

all_components: $(COMPONENT_FILES)

# ----------------------------------------
# Release
# ----------------------------------------
# copy from staging area (this directory) to top-level
release: $(BUILDDIR)/$(ONT).owl $(BUILDDIR)/$(ONT).obo $(BUILDDIR)/$(ONT).json $(BUILDDIR)/$(ONT)-base.owl
	cp $^ $(RELEASEDIR)
	
$(BUILDDIR)/$(ONT).owl: $(SRC)
	$(ROBOT) merge -i $< \
	reason -s true -m false -r hermit \
	annotate -a owl:versionInfo `cat version.txt` -a rdfs:comment `date +%Y-%m-%d` -O $(BASE)/$(ONT).owl -V  $(BASE)/releases/v`cat version.txt`/$(ONT).owl -o $@

$(BUILDDIR)/$(ONT).obo: $(BUILDDIR)/$(ONT).owl
	$(ROBOT) annotate -i $< --ontology-iri http://www.ebi.ac.uk/sira/sira.owl --version-iri http://www.ebi.ac.uk/sira/releases/v`cat version.txt`/sira.owl \
	query --update ../sparql/inject-subset-declaration.sparql \
	convert --check false -f obo -o $@
	
$(BUILDDIR)/$(ONT).json: $(BUILDDIR)/$(ONT).owl
	$(ROBOT) annotate -i $< --ontology-iri http://www.ebi.ac.uk/sira/sira.owl --version-iri http://www.ebi.ac.uk/sira/releases/v`cat version.txt`/sira.owl \
	query --update ../sparql/inject-subset-declaration.sparql \
	convert -f json -o $@

$(BUILDDIR)/$(ONT)-base.owl: build/sira.owl
	$(ROBOT) remove --input build/sira.owl \
		--base-iri 'http://www.ebi.ac.uk/sira/SIRA_' \
		--axioms external \
		--preserve-structure false \
		--trim false \
		annotate -a owl:versionInfo `cat version.txt` -a rdfs:comment `date +%Y-%m-%d` -O $(BASE)/$(ONT)-base.owl -V  $(BASE)/releases/v`cat version.txt`/$(ONT)-base.owl --output $@

# ----------------------------------------
# Sparql queries: Q/C
# ----------------------------------------

# these live in the ../sparql directory, and have suffix -violation.sparql
# adding the name here will make the violation check live
VCHECKS = duplicate-label  nolabels multiple-label no-webulous-uris no-urigen-uris no-dangling id-length deprecated obsolete-replaced-whitespace

# run all violation checks
VQUERIES = $(foreach V,$(VCHECKS),$(SPARQLDIR)/$V-violation.sparql)
sparql_test: $(BUILDDIR)/$(ONT).owl
	$(ROBOT) verify -i $< --queries $(VQUERIES) -O reports/

# ----------------------------------------
# Sparql queries: Reports
# ----------------------------------------

REPORTS = basic-report class-count-by-prefix edges xrefs obsoletes synonyms
REPORT_ARGS = $(foreach V,$(REPORTS),-s $(SPARQLDIR)/$V.sparql reports/$V.tsv)
all_reports: $(BUILDDIR)/$(ONT).owl
	$(ROBOT) query -f tsv -i $< $(REPORT_ARGS)
	
DIFF_REPORTS=sira.owl
DIFF_REPORTS_FILES=$(patsubst %, qc/diff_%_latest_release.txt, $(DIFF_REPORTS))
ENTITY_DIFF_FILES=$(patsubst %, qc/diff_%_entities.txt, $(DIFF_REPORTS))
	
	
qc/current_%_entities.txt: $(BUILDDIR)/%
	$(ROBOT) query --input $< --select $(SPARQLDIR)/all_classes.sparql $@.tmp &&\
	cat $@.tmp  | sort | uniq > $@ &&\
	rm $@.tmp
.PRECIOUS: qc/current_%_entities.txt

#REV=1fe0d2e92b0283978668a4391c57326d4f25dc80
REV=master
tmp/$(ONT)-master.owl:
	git show $(REV):src/ontology/$(SRC) > $@
	robot --catalog catalog-v001.xml merge -i $@ -o $@.owl && mv $@.owl $@

tmp/$(ONT)-master-reasoned.owl:
	git show $(REV):src/ontology/$(SRC) > $@
	robot --catalog catalog-v001.xml merge -i $@ reason -o $@.owl && mv $@.owl $@

tmp/$(ONT)-branch.owl:
	robot --catalog catalog-v001.xml merge -i $(SRC) -o $@.owl && mv $@.owl $@

tmp/$(ONT)-branch-reasoned.owl:
	robot --catalog catalog-v001.xml merge -i $(SRC) reason -o $@.owl && mv $@.owl $@


reports/robot_diff.md: tmp/$(ONT)-master.owl tmp/$(ONT)-branch.owl
	robot --catalog catalog-v001.xml diff --left $< --right tmp/$(ONT)-branch.owl --labels true -f markdown -o $@
reports/robot_diff.txt: tmp/$(ONT)-master.owl tmp/$(ONT)-branch.owl
	robot --catalog catalog-v001.xml diff --left $< --right tmp/$(ONT)-branch.owl --labels true -o $@
reports/robot_reasoned_diff.md: tmp/$(ONT)-master-reasoned.owl tmp/$(ONT)-branch-reasoned.owl
	robot --catalog catalog-v001.xml diff --left $< --right tmp/$(ONT)-branch-reasoned.owl --labels true -f markdown -o $@
reports/robot_reasoned_diff.txt: tmp/$(ONT)-master-reasoned.owl tmp/$(ONT)-branch-reasoned.owl
	robot --catalog catalog-v001.xml diff --left $< --right tmp/$(ONT)-branch-reasoned.owl --labels true -o $@


.PHONY: feature_diff
feature_diff:
	make IMP=false PAT=false reports/robot_diff.txt -B
	make IMP=false PAT=false reports/robot_reasoned_diff.txt -B

.PHONY: feature_diff_md
feature_diff_md:
	make IMP=false PAT=false reports/robot_diff.md -B
	make IMP=false PAT=false reports/robot_reasoned_diff.md -B

# ----------------------------------------
# Adhoc queries
# ----------------------------------------

build/fbbt-self-xref.txt: $(SRC)
	$(ROBOT) query --input $< --query $(SPARQLDIR)/remove-self-xrefs.sparql $@

remove-fbbt-self-xref: $(SRC)
	$(ROBOT) query --input $< --update $(SPARQLDIR)/remove-fbbt-xrefs.ru convert -f ofn --output $(SRC)
	
remove-defs-no-genus: $(SRC)
	$(ROBOT) query --input $< --update $(SPARQLDIR)/defs-without-genus-no-isabout-to-subclass.ru --output $(SRC).ofn && mv $(SRC).ofn $(SRC)

reports/report-%.tsv: $(SRC)
	$(ROBOT) query --input $< --select $(SPARQLDIR)/$*.sparql $@
	
trait_reports: reports/report-defs-without-genus.tsv reports/report-measurement-is-about.tsv reports/report-defs-without-genus-no-isabout.tsv


