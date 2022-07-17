from gbif import __version__
from gbif import climate
from gbif import human_interference
from gbif import species
from gbif import land_cover
from gbif import soil_data
from gbif import utils 

def test_version():
    assert __version__ == '0.1.0'

def test_climate_api():
    utils.logger.info("Testing Climate API")
    inst = climate.GetClimateData()
    df = inst.get_interpolated_climate_data(
        lat_deg=52.33428,
        lon_deg=4.544288,
        start_date='2022-01-02',
        end_date='2022-01-02')
    assert df['tavg'].values[0] == 10.6
    assert df['tmin'].values[0] == 9.6
    assert df['tmax'].values[0] == 11.4

def test_human_interferance_api():
    utils.logger.info("Testing Human Interference API")
    inst = human_interference.HumanInterference()
    radiance = inst.get_avg_radiance(
        lat=52.33428,
        lon=4.544288,
        date='2022-01-02')
        
    assert round(radiance,2) ==11.75

def test_species_api():
    inst = species.Occurence()
    data= inst.get_occurrences(
        eventDate='2022-01-02',
        country="GB"
        )
    assert data['key'].values[0] == 3436650793

def test_land_cover_api():
    utils.logger.info("Testing Land Cover API")
    inst = land_cover.LandCover()
    data= inst.get_land_label(
        lat_deg=52.33428,
        lon_deg=4.544288,
        start_date='2022-01-01',
        end_date='2022-06-01')
    assert data == 'grass'

def test_soil_data_api():
    utils.logger.info("Testing Soil Data API")
    inst = soil_data.SoilDataParser()
    data = inst.get_soil_data(
        lat_deg=52.33428,
        lon_deg=1.544288,
        country="GB")

    assert data["phh2o"] == 0.0
    assert data["clay"] == 0.0





