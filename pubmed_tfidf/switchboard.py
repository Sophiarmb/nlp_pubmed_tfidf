## @package nlp_tfidf
# This module defines the options with which run_tfidf.py can be run.
#
# Copyright (C) rMark Bio, Inc. - All Rights Reserved, 2015 - 2018.
# Unauthorized copying, use or distribution of this file, via any medium,
# without express written permission is strictly prohibited.
# Proprietary and Confidential.
#
# Filename:    tfidf/switchboard.py
# Written by:  Sofiya Mujawar <smujawar@rmarkbio.com>
# Description: This runs an example use of TF-IDF model building.



import sys
import argparse
import json
#from run_pubmed_tfidf import tfidf_main
from generate_pubmed_corpus import corpus_main

## These are string arguments that are always used
# format is name:help_text
STRING_ARGS = {
    'log_path'                          : 'Filename for the logger',
    'corpus_dir'                        : 'Directory of the local corpus files',
    'corpus_name'                       : 'Name and unique string identifier of a corpus',
    'corpus_document_limit'             : 'Limit the number of documents processed',
    'n_epochs_file_processing'          : 'Number of epochs for multiprocessing document processing',
    'n_processes_file_processing'       : 'Number of processes for multiprocessing document processing',
    'document_frequency_batch_size'     : 'Number of term nodes to query for document frequency calculations at once',
    'n_epochs_document_frequency'       : 'Number of epochs for multiprocessing document frequency calculations',
    'n_processes_document_frequency'    : 'Number of processes for multiprocessing document frequency calculations',
    'n_document_ids'                    : 'Number of document ids to retrieve from cosmos collection',
}

## These are boolean arguments that default to false
#BOOLEAN_ARGS = {
#    'retrieve_pubmed_corpus'            : 'Retrieve pubmed corpus from cosmos collection',
#}

## Parse arguments from the bash driver script or terminal command.
#  @param args Terminal arguments for running the keyword identification.
#  @retval None
def main(args):
    parser = argparse.ArgumentParser(description='run pipeline for adding data to Neo4j')

    #string arguments, required
    for arg, help_text in STRING_ARGS.items():
        parser.add_argument('--' + arg, type = str, help = help_text, required = True)

    #for arg, help_text in BOOLEAN_ARGS.items():
    #    parser.add_argument('--' + arg, action = 'store_true', required = False)
    #parse and print out arguments
    args = parser.parse_args()
    build_options = json.dumps(vars(args), indent = 4)
    corpus_main(build_options)

## Execution starts here
if __name__ == '__main__':
    main(sys.argv[1:])  #because argv[0] is always the filename followed by positional arguments


