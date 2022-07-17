"""Module to pull all covariated for gbif occurence data.
"""

from gbif import climate
from gbif import human_interference
from gbif import species
from gbif import land_cover
from gbif import soil_data
from gbif import utils

import pandas as pd



class GBIF_COVARIATES():
    """Class to initiliaze covaritate fetch
    - Queries GBIF first to get occurence data
    - Next Gets human interference
    - Next Gets climate interference
    - Next Gets Soil interference
    - Next Gets Land interference
    """

    def __init__(self) :
        utils.logger.info("Init GBIF Covariate API")
        self.inst_species=species.Occurence()
        self.inst_human_interference = human_interference.HumanInterference()
        self.inst_climate = climate.GetClimateData()
        self.df_species = pd.DataFrame()
    
    def __wrapper_human_interference(self):
        self.df_species['date'] = self.df_species['eventDate'].astype(str).str[:10]
        self.df_species['avg_radiance'] = self.df_species[['decimalLatitude',
                                        'decimalLongitude',
                                        'date']].\
                                        apply(lambda x: self.inst_human_interference.get_avg_radiance(lat= x.decimalLatitude,
                                                                            lon=x.decimalLongitude,
                                                                        date= x.date),
                                            axis=1)


        self.df_species['avg_deg_urban'] = self.df_species[['decimalLatitude',
                                        'decimalLongitude']].\
                                        apply(lambda x: self.inst_human_interference.get_avg_deg_urban(lat = x['decimalLatitude'],
                                                                            lon=x['decimalLongitude']),
                                            axis=1)

        # return self.df_species[['decimalLatitude', 'decimalLongitude', 
        # 'countryCode', 'eventDate',  'avg_radiance', 'avg_deg_urban', 'scientificName']].copy()
        return self.df_species

    def __wrapper_climate(self):
        self.df_species[['tavg', 'tmin', 'tmax', 'prcp', 'snow', 'wdir', 'wspd', 'wpgt', 'pres', 'tsun' 
        ]] = self.df_species[['decimalLatitude',
                                        'decimalLongitude',
                                        'date']].\
                                        apply(lambda x: self.inst_climate.get_interpolated_climate_data(lat_deg= x.decimalLatitude,
                                                                            lon_deg=x.decimalLongitude,
                                                                        start_date= x.date,
                                                                        end_date= x.date),
                                            axis=1, result_type="expand")
        

        return self.df_species


    def get_gbif_covariates(self, event_date, country):
        
        self.df_species = self.inst_species.get_occurrences(
            eventDate=event_date,
            country=country)

        self.df_species= self.__wrapper_human_interference()

        self.df_species = self.__wrapper_climate()

        return self.df_species

