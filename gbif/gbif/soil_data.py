from owslib.wcs import WebCoverageService
from pyproj import Proj, transform
from PIL import Image
import numpy as np
from math import cos, pi
import pandas as pd
from gbif import utils



class SoilDataParser:

    soil_data_dict_with_conversion = {'phh2o': 10,
                                      'bdod': 100,
                                      'cec': 10,
                                      'cfvo': 10,
                                      'clay': 10,
                                      'nitrogen': 100,
                                      'sand': 10,
                                      'silt': 10,
                                      'soc': 10,
                                      'ocd': 10
                                      }

    def __init__(self):
        
        self.wcs = {}
        self.projection_epsg=0
        

    def set_wcs(self):
        for datatype, conversion_factor in self.soil_data_dict_with_conversion.items():
            self.wcs[datatype] = WebCoverageService(f'http://maps.isric.org/mapserv?map=/map/{datatype}.map',
                                     version='2.0.1')
        # return wcs

    def get_projection_epsg(self,country):
        if country == 'BR':
            self.projection_epsg = 29101
        elif country == 'GB':
            self.projection_epsg =  27700

    # def get_gbif_data(self):
    #     brazil_data = pd.read_csv('bquxjob_2c525673_181e4342f32.csv')
    #     uk_data = pd.read_csv('bquxjob_39d5dfa3_181e432946c.csv')

    #     gbif_data = pd.concat([brazil_data, uk_data])
    #     gbif_data = gbif_data.reset_index(drop=True)

    #     return gbif_data

    def get_bounding_box(self, lat_deg, lon_deg):
        r_earth = 6371000.0
        displacement = 250
        lat_deg_max = lat_deg + (displacement / r_earth) * (180 / pi)
        lon_deg_max = lon_deg + (displacement / r_earth) * (180 / pi) / cos(lat_deg * pi / 180)

        lat_deg_min = lat_deg - (displacement / r_earth) * (180 / pi)
        lon_deg_min = lon_deg - (displacement / r_earth) * (180 / pi) / cos(lat_deg * pi / 180)

        projection = Proj(init=f'epsg:{self.projection_epsg}')
        geographic = Proj(init='epsg:4326')

        x_cord_max, y_cord_max = transform(geographic, projection, lon_deg_max, lat_deg_max)

        x_cord_min, y_cord_min = transform(geographic, projection, lon_deg_min, lat_deg_min)

        self.subsets = [('X', x_cord_min, x_cord_max), ('Y', y_cord_min, y_cord_max)]

        # return subsets

    def get_soil_data(self,lat_deg,lon_deg,country):

        utils.logger.info("Getting Soil Data for [%f,%f, %s]" %(lat_deg,lon_deg, country))
        
        self.set_wcs()
        self.get_projection_epsg(country)
        self.get_bounding_box(lat_deg=lat_deg, lon_deg=lon_deg)
        
        utils.logger.debug('Bounding Box', self.subsets)

        soil_covariates = {}
        for datatype, conversion_factor in self.soil_data_dict_with_conversion.items():
            cov_id = f'{datatype}_0-5cm_mean'
            crs = f"http://www.opengis.net/def/crs/EPSG/0/{self.projection_epsg}"

            response = self.wcs[datatype].getCoverage(
                identifier=[cov_id],
                crs=crs,
                subsets=self.subsets,
                format='GEOTIFF_INT16')

            with open('test.tif', 'wb') as file:
                file.write(response.read())

            im = Image.open('test.tif')

            imarray = np.array(im)
            median_value = np.median(imarray) / conversion_factor

            soil_covariates[datatype] = median_value
        return soil_covariates




