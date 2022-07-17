"""Module that enlists functions to query gbif backend
"""

import pandas as pd
import numpy as np
import pygbif
# from pygbif import occurences as occ
from gbif import utils


class Occurence():

    def __init__(self):
        pass
    
    def get_occurrences(self,eventDate, country, offset = 0, test=False):
        """function to get the occurrences from gbif. max rows in one call is 300; we use a loop
        args:
            eventDate (str): day to get the data for
            country (str): 2 digit ISO country code
            offset (int): offset parameter to loop through occurrences in gbif
        """
        utils.logger.info("Getting Occurence Data for Date:%s and Country: %s" %(eventDate,country))
        cols_list = ['key','datasetKey','publishingCountry', 'protocol','lastCrawled','lastParsed',
                    'crawlId','basisOfRecord','occurrenceStatus','taxonKey','kingdomKey','phylumKey',
                    'classKey','orderKey','familyKey', 'genusKey','speciesKey','acceptedTaxonKey',
                    'scientificName','acceptedScientificName', 'kingdom', 'phylum', 'order','family',
                    'genus', 'species', 'genericName','specificEpithet', 'taxonRank', 'taxonomicStatus',
                    'iucnRedListCategory','decimalLongitude', 'decimalLatitude', 'coordinateUncertaintyInMeters',
                    'year','month', 'day', 'eventDate', 'issues','modified', 'lastInterpreted', 'recordedBy',
                    'identifiedBy', 'class', 'countryCode', 'country', 'dateIdentified', 'datasetName']
        batch_size = 300 #max rows outputted by pygbif client
        output_rows = batch_size
        out_df = pd.DataFrame()
        if test == False:
            while output_rows >= batch_size:
                temp_df = pd.DataFrame(pygbif.occurrences.search(eventDate=eventDate, country=country,
                                                offset=offset, hasCoordinate=True)['results'])
                offset += batch_size
                output_rows = temp_df.shape[0]
                out_df = pd.concat([out_df,temp_df])
                utils.logger.debug("Received Data from GBIF backend: %d" %(len(temp_df.index)))
        elif test == True:
            out_df = pd.DataFrame(pygbif.occurrences.search(eventDate=eventDate, country=country,
                                                offset=offset, hasCoordinate=True)['results'])

        #out_df[cols_list].to_csv("test_data.csv", index=False)
        utils.logger.info("Total Data from GBIF backend: %d" %(len(out_df.index)))
        return out_df[cols_list]
