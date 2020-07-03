#!/usr/bin/env bash

if [ $# -lt 5 ]; then
  echo "usage: $0 <project-id> <dataset-name> <table-name> <vcf-file>"
  exit 1
fi

PROJECT_ID=$1
DATASET_NAME=$2
TABLE=$3
VCF_FILE=$4
#MANIFEST_SCHEMA=$5



TMP_SORTED="/tmp/manifest_ingest_sorted.csv"
TMP_SUB="/tmp/manifest_ingest_sub.csv"
TMP_PROC="/tmp/manifest_ingest_processed.csv"
TMP="/tmp/manifest_ingest.csv"

sed 's/^.*;GC_SCORE=\([0-9.]*\);.*$/\1/g' small.vcf

sed 's/,X,/,23X,/g; s/,Y,/,24Y,/g; s/,MT,/,25MT,/g' $MANIFEST_FILE > $TMP_SUB
sort -t , -k 23n,23 -k24n,24 $TMP_SUB > $TMP_SORTED
# checking for != "build37Flag" skips the header row (we don't want that numbered)
awk -F ',' 'NF==29 && ($29!="ILLUMINA_FLAGGED" && $29!="INDEL_NOT_MATCHED" && $29!="INDEL_CONFLICT" && $29!="build37Flag") { flag=$29; if ($29=="PASS") flag=""; print id++","$2","$9","$23","$24","$25","$26","$27","flag }' $TMP_SORTED > $TMP_PROC
sed 's/,23X,/,X,/g; s/,24Y,/,Y,/g; s/,25MT,/,MT,/g' $TMP_PROC > $TMP
echo "created file for ingest $TMP"

# schema and TSV header need to be the same order

# create a dataset

# create a site info table and load
bq mk --project_id=$PROJECT_ID $DATASET_NAME
bq --location=US mk --project_id=$PROJECT_ID $DATASET_NAME.$TABLE $MANIFEST_SCHEMA
bq load --location=US --project_id=$PROJECT_ID --source_format=CSV $DATASET_NAME.$TABLE $TMP $MANIFEST_SCHEMA

echo "ingested manifest data into table $TABLE"
bq show --format=prettyjson --project_id=$PROJECT_ID $DATASET_NAME.$TABLE
