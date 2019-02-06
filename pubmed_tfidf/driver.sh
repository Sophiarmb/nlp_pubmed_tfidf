#!/bin/bash
#
## @package driver
# This driver script controls the execution of and example TF-IDF model
#
# Copyright (C) rMark Bio, Inc. - All Rights Reserved, 2015 - 2018.
# Unauthorized copying, use or distribution of this file, via any medium,
# without express written permission is strictly prohibited.
# Proprietary and Confidential.
#
# Filename:    nlp_tfidf/tfidf/driver.sh
# Written by:  Jason Nett <jnett@rmarkbio.com>


# Set this to the python path of the virtual env
export PYTHONEXE=/usr/bin/python
export PYTHONPATH=$PYTHONPATH:/home/rmarkbio/project/neo4j_interface

#for data accessors
export PYTHONPATH=$PYTHONPATH:/home/rmarkbio/project/azure_database_tools
export PYTHONPATH=$PYTHONPATH:/home/rmarkbio/project/data_accessors

# Project Home
export ABVHOME=$(pwd)

# Set logging location
export LOGHOME='/home/rmarkbio/logs/'  # For use in a Docker container, always puts logs here

# Local corpus directory
export CORPUS_DIR='data/pubmed/'

# Corpus name: This uniquely identifies a corpus, which is represented by
# a node in a Neo4j database.
export CORPUS_NAME='pubmed'

# Set a limit on the number of corpus files to process.  Use `-1` for no limit (i.e. the full corpus)
export CORPUS_DOCUMENT_LIMIT=1000

# Set limit to cosmos collection request ???
export N_DOCUMENT_IDS=5

# Multiprocessing parameters: Set the number of epochs and the number of parallel
# processes to split the file processing work into.
export N_EPOCH_FILE_PROCESSING=10
export N_PROCESSES_FILE_PROCESSING=4

# There can be ~10^5 terms to compute the document frequency for, so we
# need to split this up.  The `DOCUMENT_FREQUENCY_BATCH_SIZE` is the number of term nodes
# to retrieve at once.  The `N_EPOCH_DOCUMENT_FREQUENCY` and `N_PROCESSES_DOCUMENT_FREQUENCY`
# parameters determine how that particular batch will be multiprocessed.
# I am also using these for parallel computation of TF-IDF values.
export DOCUMENT_FREQUENCY_BATCH_SIZE=40
export N_EPOCH_DOCUMENT_FREQUENCY=1           # keep this 1
export N_PROCESSES_DOCUMENT_FREQUENCY=4      # Rule of thumb: this is 1/100 of DOCUMENT_FREQUENCY_BATCH_SIZE

# Specify what to do here. Retrive pubmed cosmos collection and then compute tf idf
# Flags specified here must match those in switchboard.py.
#declare corpus_options=(
#retrieve_pubmed_corpus
#compute_tfidf
#)

# Build the list of flags for which part of the database to build.
#export corpus_options=''
#for option in ${corpus_options[@]}; do
#    echo $option
#    corpus_options+=--$option' '
#done
#echo '------------------------------------'

res1=$(date +%s)

$PYTHONEXE pubmed_tfidf/switchboard.py\
    --log_path=$LOGHOME\
    --corpus_dir=$CORPUS_DIR\
    --corpus_name=$CORPUS_NAME\
    --corpus_document_limit=$CORPUS_DOCUMENT_LIMIT\
    --n_epochs_file_processing=$N_EPOCH_FILE_PROCESSING\
    --n_processes_file_processing=$N_PROCESSES_FILE_PROCESSING\
    --document_frequency_batch_size=$DOCUMENT_FREQUENCY_BATCH_SIZE\
    --n_epochs_document_frequency=$N_EPOCH_DOCUMENT_FREQUENCY\
    --n_processes_document_frequency=$N_PROCESSES_DOCUMENT_FREQUENCY\
    --n_document_ids=$N_DOCUMENT_IDS\

res2=$(date +%s)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

printf "\nDONE. Total processing time: %d:%02d:%02d:%02d\n" $dd $dh $dm $ds


