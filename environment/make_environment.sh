#!/bin/bash

# Assumes user install of anaconda

conda create --name asv_walk python=3.5 pip pytest pandas jupyter -y

# Map R libs correctly
/home/jwero/GitHub/conda_environments/helpers/conda_env_R_libs.sh asv_walk

source activate asv_walk

# install new gcc
conda install -y gcc

# install r
conda install -y -c r r-essentials=1.5.2 r-rmarkdown=1.3 r-devtools r-leaflet r-viridis r-rcurl 

