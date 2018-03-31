#!/bin/bash

echo 'CREATING MIMIC ... '

# this flag allows us to initialize the docker repo without building the data
if [ $BUILD_MIMIC -eq 1 ]
then
echo "running create mimic user"

pg_ctl stop

pg_ctl -D "$PGDATA" \
  -o "-c listen_addresses='' -c checkpoint_timeout=600" \
  -w start

psql <<- EOSQL
  CREATE USER MIMIC WITH PASSWORD '$MIMIC_PASSWORD';
  CREATE DATABASE MIMIC OWNER MIMIC;
  \c mimic;
  CREATE SCHEMA MIMICIII;
  ALTER SCHEMA MIMICIII OWNER TO MIMIC;
  ALTER ROLE MIMIC SET search_path = MIMICIII;
EOSQL

# check for the admissions to set the extension
if [ -e "/mimic_data/ADMISSIONS.csv.gz" ]; then
  COMPRESSED=1
  EXT='.csv.gz'
elif [ -e "/mimic_data/ADMISSIONS.csv" ]; then
  COMPRESSED=0
  EXT='.csv'
else
  echo "Unable to find a MIMIC data file (ADMISSIONS) in /mimic_data"
  echo "Did you map a local directory using 'docker run -v /path/to/mimic/data:/mimic_data' ?"
  exit 1
fi

# check for all the tables, exit if we are missing any
ALLTABLES='admissions callout caregivers chartevents cptevents datetimeevents d_cpt diagnoses_icd d_icd_diagnoses d_icd_procedures d_items d_labitems drgcodes icustays inputevents_cv inputevents_mv labevents microbiologyevents noteevents outputevents patients prescriptions procedureevents_mv procedures_icd services transfers'

for TBL in $ALLTABLES; do
  if [ ! -e "/mimic_data/${TBL^^}$EXT" ];
  then
    echo "Unable to find ${TBL^^}$EXT in /mimic_data"
    exit 1
  fi
  echo "Found all tables in /mimic_data - beginning import from $EXT files."
done

# Use makefile
cd /docker-entrypoint-initdb.d/buildmimic/postgres/
if [ $COMPRESSED -eq 1 ]; then
  make mimic-gz datadir="/mimic_data/"
else
  make mimic datadir="/mimic_data/"
fi

echo "$0: Granting select rights on all public tables to user mimic"
psql --username "$POSTGRES_USER" <<- EOSQL
    \c mimic;
    GRANT SELECT ON ALL TABLES IN SCHEMA MIMICIII TO MIMIC;
EOSQL

fi

echo 'Done!'
