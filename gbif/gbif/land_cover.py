import ee
import geemap
import pandas as pd
import logging


# startDate = '2021-01-01'
# endDate = '2022-06-01'
# brazil_data = pd.read_csv('bquxjob_2c525673_181e4342f32.csv')
# uk_data = pd.read_csv('bquxjob_39d5dfa3_181e432946c.csv')

# all_data = pd.concat([brazil_data, uk_data])
# all_data = all_data.reset_index(drop=True)

#all_data = all_data.iloc[0:5]
class LandCover():
    def __init__(self, log_level=logging.INFO):
        self.log = logging.getLogger("land_cover-logger")
        self.log.setLevel(log_level)
    
    def get_land_label(self, lat_deg, lon_deg, start_date, end_date):

        try:
            self.log.debug("")
            ee.Initialize()
            geometry = ee.Geometry.Point([lon_deg, lat_deg])
            dw = ee.ImageCollection('GOOGLE/DYNAMICWORLD/V1').filterDate(start_date, end_date).filterBounds(geometry)
            dwImage = ee.Image(dw.first())
            dwImagenew = dw.mode()
            label_index = dwImagenew.sample(geometry, scale=10).first().get('label').getInfo()
            label_type = dwImage.getInfo()['bands'][label_index]['id']

        except Exception as e:
            self.log.error(e)
            label_type = ""
        
        return label_type