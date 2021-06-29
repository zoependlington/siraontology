#!/bin/bash

mkdir -p mirror

echo "Fetching DOID..."
curl -L http://purl.obolibrary.org/obo/doid.owl > mirror/doid.owl

echo "Fetching EFO..."
curl -L http://www.ebi.ac.uk/efo/efo.owl > mirror/efo.owl

echo "Fetching HPO..."
curl -L http://purl.obolibrary.org/obo/hp.owl > mirror/hp.owl

echo "Fetching MONDO..."
curl -L http://purl.obolibrary.org/obo/mondo.obo > mirror/mondo.obo && ../../bin/robot convert -i mirror/mondo.obo -f owl -o mirror/mondo.owl

echo "Fetching MP..."
curl -L http://purl.obolibrary.org/obo/mp.owl > mirror/mp.owl

echo "Fetching NCIT..."
curl -L http://purl.obolibrary.org/obo/ncit.owl > mirror/ncit.owl

echo "Fetching ORDO..."
curl -L http://www.orpha.net/ontology/ORDO_en_3.1.owl > mirror/ordo.owl

echo "Fetching UBERON..."
curl -L http://purl.obolibrary.org/obo/uberon.owl > mirror/uberon.owl
