# Retrieve pubmed cosmos collection
# Copyright (C) rMark Bio, Inc. - All Rights Reserved, 2015 - 2018.
# Unauthorized copying, use or distribution of this file, via any medium,
# without express written permission is strictly prohibited.
# Proprietary and Confidential.
# Filename:    nlp_pubmed_tfidf/generate_pubmed_corpus.py
# Written by:  Sofiya Mujawar <smujawar@rmarkbio.com>
# Description: Retrieve pubmed cosmos collection and build a graph database

import json
import os
import sys
import logging
from datetime import datetime

#from neo4j_config import neo4j_config
from tools import get_or_create_directory
#from tfidf import TF_IDF
from data_accessors.data_accessors import EternalBearerToken
from data_accessors.data_accessors import API_CLASSES
from data_accessors.data_accessors import get_api_names
from data_accessors.data_accessors import dump_all_ids
from data_accessors.data_accessors import TwitterUsersAPI
from data_accessors.data_accessors import TwitterTweetsAPI
from data_accessors.data_accessors import get_keywords_from_api
from data_accessors.data_accessors import query_api_for_documents
from data_accessors.data_accessors import match_institution_names
from data_accessors.data_accessors import check_api_health
from data_accessors.data_accessors import get_bearer_token
from data_accessors.data_accessors import EternalBearerToken


# special class that auto-refreshes token whenever any of its attributes are accessed
# has a default token TTL of 3500 seconds (giving a 100-second buffer at end of lifetime to refresh itself)
GLOBAL_ETERNAL_TOKEN = EternalBearerToken()

##  @brief               For testing and development of the TF_IDF class, we are using a corpus of ~92,000
##                       CNN articles in a local directory.  This illustrates the use of the class to build
##                       and use a database to compute TF-IDF values of the terms in a free text document.
##  @param build_options All parameters sent from the driver script to control how the TF_IDF
##                       computations are done.
##  @retval None
def corpus_main(build_options):

    ## @var Convert from JSON string to python dictionary
    build_options = json.loads(build_options)

    # Logging
    logger = logging.getLogger('Pubmed Collection Logging')
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

    print("entered main")
### DATASRVC-BASED DOCUMENT RETRIEVAL API EXAMPLES
#
### Example of retrieving documents from PubMed API
## @brief retrieves example IDs from SQL database and then queries API for documents
## @param token - a dictionary token ({'Authorization': 'Bearer [insert string here]'})
##                or an object of the EternalBearerToken class
## @output - 1 if error, 0 if success
##@example
def pubmed_api_example(token = GLOBAL_ETERNAL_TOKEN):

    # this value determines batch size
    n_ids = 5

    # each API is given a name to access using dump_all_ids() and
    # get_keywords_from_api()
    # you can access these from API_CLASSES and get_api_names()
    api_name = 'pubmed'

    # health check
    try:
        print('health check for {api_name}'.format(api_name = api_name))
        results = check_api_health(api_name, token = token)
        print(json.dumps(results, indent = 2))
    except Exception as e:
        print('failed health check for {api_name}'.format(api_name = api_name))
        return 1

    try:
        # IDs need to be retrieved for the API to work
        # dump_all_ids() returns a generator, which must be iterated over
        ids_generator = dump_all_ids(api_name, batch_size = n_ids, disable_warning = True)

        # the easiest way to get a fixed number of IDs is to call next()
        # on the IDs
        ids = next(ids_generator)
    except Exception as e:
        print('ERROR: could not retrieve IDs for {api_name}'.format(
            api_name = api_name
        ))

        # this prints back full traceback if an error occurs
        print(traceback.format_exc())
        return 1
    if len(ids) == 0:
        print('ERROR: no IDs returned for {api_name}'.format(
            api_name = api_name
        ))
        return 1

    try:
        # the output here should be of the form
        # [{doc1}, {doc2}, ...], where {docX} represents the whole document (dict)
        documents = query_api_for_documents(api_name, ids = ids, token = token)
        print(documents)
    except Exception as e:

        # this occurs when there is an issue with the API
        # usually this means it's disconnected or something is wrong with
        # nginx/gunicorn
        print('Could not retrieve documents from API <{api_name}>'.format(
            api_name = api_name
        ))
        print(traceback.format_exc())
        return 1

    try:
        # convert documents to readable format
        print(json.dumps(documents,indent = 2))
    except Exception as e:

        # this occurs when the response returned is not good
        # (e.g., wrong IDs used, bad url, endpoint not working properly)
        print('Could not decode documents from API <{api_name}>'.format(
            api_name = api_name
        ))
        return 1

    return 0
