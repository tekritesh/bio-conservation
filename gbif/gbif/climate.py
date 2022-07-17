"""Module to pull data for Climate Params.
"""

import pandas as pd
import numpy as np
from meteostat import Point, Daily
from datetime import datetime
#from gbif import utils


class GetClimateData():
    """Class to invoke meteo stat apis to get daily data 
    """
    def __init__(self):
        pass
        # utils.logger.setLevel(log_level)

    def get_interpolated_climate_data(self,lat_deg, lon_deg,start_date, end_date, altitude=0 ):
        """Function to Get Interpolated climate data for lat,lon,altitude for a given date
        Refer : https://dev.meteostat.net/python/point.html#api for a complete picture

        lat_deg(float): latitude coordinates in degrees
        lon_deg(float): longitude coordinates in degrees
        altitude(float): altitude of the geo co-ordinate in meters
        start_date(string): start date for climate data
        end_date(string): end date for climate data
        """
        start_date = datetime.fromisoformat(start_date)
        end_date = datetime.fromisoformat(end_date)

        location = Point(lat_deg, lon_deg, altitude)

        #utils.logger.info("Getting climate data for Lat,Log:[%f,%f] for dates:[%s, %s]" % (lat_deg, lon_deg, start_date, end_date))
        column_names = ['tavg', 'tmin', 'tmax', 'prcp', 'snow', 'wdir', 'wspd', 'wpgt', 'pres', 'tsun' ]
        try:
            data = Daily(location, start_date, end_date)
            data = data.fetch().reset_index()
            if data.shape[0] < 1:
                data = pd.DataFrame([[np.nan]*len(column_names)],columns = column_names)
            #utils.logger.info("Recieved Data Points: %d" %(len(data.index)))
        except Exception as e:
            #utils.logger.error(e)
            data = pd.DataFrame([[np.nan]*len(column_names)],columns = column_names)
            
        return data.loc[0,'tavg'], data.loc[0,'tmin'], data.loc[0,'tmax'], data.loc[0,'prcp'], \
                data.loc[0,'snow'], data.loc[0,'wdir'], data.loc[0,'wspd'], data.loc[0,'wpgt'],\
                     data.loc[0,'pres'], data.loc[0,'tsun']

