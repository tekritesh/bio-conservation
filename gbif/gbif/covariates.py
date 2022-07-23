"""Module to pull all covariated for gbif occurence data.
"""

from gbif import climate
from gbif import human_interference
from gbif import species
from gbif import land_cover
from gbif import soil_data
from gbif import utils
import time
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
        """
        Initialising all class instances, logger and time keeping
        
        TODO :  We are using Earth Engine for both Human Interference and LandCover. Can just use one instance of ee eventually.
        """
        
        self.time_taken = time.time()

        utils.logger.info("Hello there curious one! Hold up while we fetch your covariates for your lovely species")
        utils.logger.info("Init GBIF Covariate API")
        self.inst_species=species.Occurence()
        self.inst_human_interference = human_interference.HumanInterference()
        self.inst_climate = climate.GetClimateData()
        self.inst_soil = soil_data.SoilDataParser()
        self.inst_land_cover = land_cover.LandCover()
        self.df_species = pd.DataFrame()
        utils.logger.info("Initialed GBIF Covariate API in %0.2f" % (round(time.time()- self.time_taken,1)) )
    
    def __wrapper_human_interference(self):
        """
            Runs the  human interence API for every lat/lon against a gbif speicies occurence instance
        """

        utils.logger.info("Getting Human Interference Data")

        if 'date' not in self.df_species.columns:
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
        """
            Runs the  climate data API for every lat/lon against a gbif speicies occurence instance
        """


        utils.logger.info("Getting Climate Data")

        if 'date' not in self.df_species.columns:
            self.df_species['date'] = self.df_species['eventDate'].astype(str).str[:10]

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

    def __wrapper_soil_data(self, country=""):
        """
            Runs the  soil data API for every lat/lon and country against a gbif speicies occurence instance
        """
        utils.logger.info("Getting Soil Data")

        if 'date' not in self.df_species.columns:
            self.df_species['date'] = self.df_species['eventDate'].astype(str).str[:10]

        self.df_species[['phh2o', 'clay']] = self.df_species[['decimalLatitude',
                                        'decimalLongitude',
                                        'date']].\
                                        apply(lambda x: self.inst_soil.get_soil_data(lat_deg= x.decimalLatitude,
                                                                            lon_deg=x.decimalLongitude,
                                                                            country=country),
                                            axis=1, result_type="expand")
        

        return self.df_species

    def __wrapper_land_cover(self):
        """
            Runs the  land cover data API for every lat/lon  against a gbif speicies occurence instance
        """

        utils.logger.info("Getting Land Cover Data")

        if 'date' not in self.df_species.columns:
            self.df_species['date'] = self.df_species['eventDate'].astype(str).str[:10]

        self.df_species[['land_type']] = self.df_species[['decimalLatitude',
                                        'decimalLongitude',
                                        'date']].\
                                        apply(lambda x: self.inst_land_cover.get_land_label(lat_deg= x.decimalLatitude,
                                                                            lon_deg=x.decimalLongitude,
                                                                            start_date=x.date,
                                                                            end_date=x.date),
                                            axis=1)
        

        return self.df_species


    def get_gbif_covariates(self, event_date, country, test=False):
        """
            Function to get occurence, climate, human interferenc, soil, and land cover data from their
            respective APIs.

            event_date: date of gbif occurrence
            country: country to get the occurence from
            test : Default false. If True, gets only first 300 data points
            
        """

        self.time_taken = time.time()

        """
        Since the occurence data controls the query size iterations for subsequent covariates, so in testing,
        limiting only the occurence data collection by using the test flag.  This should in turn control all the other 
        queries downstream.
        """
        self.df_species = self.inst_species.get_occurrences(
            eventDate=event_date,
            country=country,
            test=True)
        utils.logger.info("Finished GBIF occurence Data collection in %0.2f" % round(time.time()- self.time_taken,1))
        
        self.time_taken = time.time()
        self.df_species= self.__wrapper_human_interference()
        utils.logger.info("Finished Human Interference Data collection in %0.2f" % round(time.time()- self.time_taken,1))
        
        self.time_taken = time.time()
        self.df_species = self.__wrapper_climate()
        utils.logger.info("Finished Climate Data collection in %0.2f" % round(time.time()- self.time_taken,1))

        self.time_taken = time.time()
        self.df_species = self.__wrapper_soil_data(country=country)
        utils.logger.info("Finished Soil Data collection in %0.2f" % round(time.time()- self.time_taken,1))

        self.time_taken = time.time()
        self.df_species = self.__wrapper_land_cover()
        utils.logger.info("Finished Land Cover Data collection in %0.2f" % round(time.time()- self.time_taken,1))

        utils.logger.info("Finished fetching all covariates. Have Fun!")

        return self.df_species

