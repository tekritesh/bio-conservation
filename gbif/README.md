# GBIF Package

#### Install Python Dependency Manager

Refer : https://python-poetry.org/docs/


#### Install Local Dependencies
This should create a local env variable and install all the libs
```
cd gbif
poetry install
```
![image](https://user-images.githubusercontent.com/65660549/179351282-ec1c04d5-eb6f-41e5-b2a7-72b82e7689ab.png)


#### Build Package
This should create *tar or *whl for us to invoke in any application under ```dist``` directory 
```
poetry build
```
![image](https://user-images.githubusercontent.com/65660549/179351304-744af1a2-5e9f-45e3-bd20-9e58a9647abb.png)


#### Test Package
Local Test of the package
```
poetry run pytest
```
![image](https://user-images.githubusercontent.com/65660549/179351333-e04b4352-876b-4901-bb26-76e3381e8ed6.png)


#### Using the poetry env to use for Jupyter
Get the env variable name
```
poetry env info
```
- Use this variable for your py-kernel when you launch your jupyter instance in vscode. 
- If you cant find this, then:
- Ctrl/Cmd + P
- Select Python Interpreter
- Enter Interpreter Path
- Use the path as per ```poetry env info``` to add your ``venv`` to vs code

#### Package Contents

- ***Covariates Data Query API***
- *GBIF Occurence Data Query API*
- *Human Interference Data Query API*
- *Soil Data Query API*
- *Land Cover Data Query API*
- *Climate Data Query API*

#### Folder Structure

- ~/gbif  : Contains all the API modules
  - covriates.py
  - human_interference.py
  - land_cover.py
  - soil_data.py
  - species.py
  - climate.py

- ~/tests : Contains **Unit Tests** for Individual APIs
  - test_gbif.py  
- ~/dist  : Contains *.whl* and *.tar* for our package 
realease
  - gbif_[version]_.tar.gz
  - gbif_[version]_.whl


#### Writing your function

To be added

#### Publish this package

To be added
