## @package nlp_tfidf
#
# Copyright (C) rMark Bio, Inc. - All Rights Reserved, 2015 - 2018.
# Unauthorized copying, use or distribution of this file, via any medium,
# without express written permission is strictly prohibited.
# Proprietary and Confidential.
# Filename:    tfidf/run_tfidf.py
# Written by:  Sofiya Mujawar <smujawar@rmarkbio.com>
# Description: Build an example TF-IDF model for testing and development of
#              our TF-IDF modeling software.



import json
import os
import sys
import logging
from datetime import datetime

from neo4j_config import neo4j_config
from tools import get_or_create_directory
from tfidf import TF_IDF

## Gather a list of filenames of the entire corpus.
#  @brief                  Assuming that a corpus of documents is saved to a local directory
#                          and each of those documents is its own text file, pass the relative
#                          path to the directory of that corpus and get a list of all file names
#                          in that directory.  It is assumed that each of those file names
#                          corresponds to a document text file that is part of the corpus to
#                          be processed into the graph database we're building.
# @param corpus_path       The relative path to the directory of the corpus.
# @param limit             Limit the number of files to this integer--used for testing and development.
# @retval corpus_filenames A list of strings that are the file names.
def local_corpus_filenames(
    corpus_path,
    limit = None,
):

    # Prepare a list of file names
    corpus_filenames = []
    i = 0
    for entry in os.scandir(corpus_path):
        if not entry.name.startswith('.') and entry.is_file():
            if limit is not None:
                if i >= limit:
                    break
            corpus_filenames.append(os.path.join(corpus_path, entry.name))
            i += 1
    return corpus_filenames

## Begin use of the `TF_IDF` class.
#  @brief               For testing and development of the TF_IDF class, we are using a corpus of ~92,000
#                       CNN articles in a local directory.  This illustrates the use of the class to build
#                       and use a database to compute TF-IDF values of the terms in a free text document.
#  @param build_options All parameters sent from the driver script to control how the TF_IDF
#                       computations are done.
#  @retval None
def tfidf_main(build_options):

    ## @var Convert from JSON string to python dictionary
    build_options = json.loads(build_options)

    # Logging
    logger = logging.getLogger('TF-IDF Logging')
    logger.setLevel(logging.DEBUG)   # determine the level of severity to pass to handlers
    log_directory = str(build_options['log_path'])
    now           = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_path      = get_or_create_directory(log_directory, now)
    log_filename  = 'central.log'

    # This handler will cover the primary logging file.
    file_handler = logging.FileHandler(log_path + '/' + log_filename)
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', '%Y-%m-%d %H:%M:%S')
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)

    # This handler will cover printing to the console
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_formatter = logging.Formatter('%(asctime)s - %(message)s', '%Y-%m-%d %H:%M:%S')
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    # Instantiate the `TF_IDF` class
    tf_idf = TF_IDF(
        logger                         = logger,
        log_path                       = log_path,
        neo4j_config                   = neo4j_config,
        corpus_name                    = build_options['corpus_name'],
        corpus_path                    = build_options['corpus_dir'],
        corpus_filenames_retriever     = local_corpus_filenames,
        n_epochs_file_processing       = build_options['n_epochs_file_processing'],
        n_processes_file_processing    = build_options['n_processes_file_processing'],
        n_epochs_document_frequency    = build_options['n_epochs_document_frequency'],
        n_processes_document_frequency = build_options['n_processes_document_frequency'],

    )

#    # [DELETE THE ENTIRE GRAPH]
#    tf_idf.delete_graph(batch_size = 10000)
#
#    # Implement uniqueness constraints as specified by the Neo4j schema in `neoj_config.py`,
#    # which was passed during instantiation.
#    tf_idf.create_neo4j_constraints()
#
#    # Create the corpus node
#    logger.info('Creating/Merging corpus node %s' % (build_options['corpus_name'],))
#    tf_idf.create_corpus_node(
#        name        = build_options['corpus_name'],
#        description = 'This is a test corpus of CNN articles for development purposes',
#    )
#
#    # Iterate over the files of a local corpus to build the:
#    # (1) corpus node
#    # (2) document nodes and their relationship to the corpus
#    # (3) term nodes and their term frequency relationships to document nodes.
#    logger.info('Processing corpus documents to build term and document nodes')
#    document_limit = int(build_options['corpus_document_limit'])
#    if document_limit <= 0:
#        document_limit = None
#
#    tf_idf.iterate_local_files(
#        file_limit = document_limit,
#    )
#
#    # Now I need to iterate through the terms to compute the document frequencies.
#    # Since we saved term and document nodes to a graph, we do not need to actually
#    # search the document text; we need to only count the number of relationships
#    # the term node has to documents
#    tf_idf.compute_raw_document_frequencies(
#        batch_size = int(build_options['document_frequency_batch_size']),
#    )
#
#    # Now that the raw "term frequencies" and "document frequencies" have been computed,
#    # compute the TF-IDF values for all terms in the corpus.
#    tf_idf.compute_TF_IDF(
#        corpus_name = build_options['corpus_name'],
#        batch_size  = int(build_options['document_frequency_batch_size']),
#    )

#    # --------------------------------------------------------------------------
#    # Run new text against the database build around a corpus and return results.
#
#    with open("data/new_cnn_text_4.txt", 'r', encoding = 'utf8') as f:
#        text = f.read()
#        TF_x_IDF = tf_idf.process_text(
#            text            = text,
#            corpus          = 'cnn',
#            add_to_database = False,
#        )
#
#        for v in TF_x_IDF:
#            print('%-15s %s' % (str(v[0]), str(v[1])) )

    return
