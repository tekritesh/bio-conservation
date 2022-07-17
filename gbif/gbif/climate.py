"""Module to pull data for Climate Params.
"""

import pandas as pd
from meteostat import Point, Daily
from datetime import datetime
from gbif import utils


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

        utils.logger.info("Getting climate data for Lat,Log:[%f,%f] for dates:[%s, %s]" % (lat_deg, lon_deg, start_date, end_date))
        
        try:
            data = Daily(location, start_date, end_date)
            data = data.fetch()
            utils.logger.info("Recieved Data Points: %d" %(len(data.index)))
        except Exception as e:
            utils.logger.error(e)
            data = pd.DataFrame()
            
            
        return data

