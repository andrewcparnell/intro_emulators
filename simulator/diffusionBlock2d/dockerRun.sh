#!/bin/bash

# Script to numerically solve a 2-D diffusion problem using OpenFOAM 
# Philip Cardiff, UCD
# 18-Jan-20

# Before running this script, you should pull the public docker image of
# foam-extend-4.0 (fork of OpenFOAM). You can pull the image with:
# $> docker pull philippic/foam-extend-4.0-ubuntu18.04

# Run the diffusion PDE model using the docker image
echo "Solving 2-D diffusion PDE in OpenFOAM"

# Check number of input parameters is correct
if [[ $# -ne 6 ]]
then
    echo
    echo "Incorrect number of parameters"; echo
    echo "Usage: dockerRun.sh tempLeft tempRight fluxUp fluxDown tempInitial \
diffusivity"; echo
    echo "For example:"
    echo "    ./dockerRun.sh 0 100 -200 500 50 1"
    echo
    exit
fi

docker run --rm --mount src=$(PWD),target=/home/app/model,type=bind \
       philippic/foam-extend-4.0-ubuntu18.04:latest bash -c \
       "source /home/app/foam/foam-extend-4.0/etc/bashrc > /dev/null \
        && cd model && blockMesh \
        && sed -i 's/TEMP_LEFT/${1}/g' 0/T \
        && sed -i 's/TEMP_RIGHT/${2}/g' 0/T \
        && sed -i 's/FLUX_UP/${3}/g' 0/T \
        && sed -i 's/FLUX_DOWN/${4}/g' 0/T \
        && sed -i 's/TEMP_INITIAL/${5}/g' 0/T \
        && sed -i 's/DIFFUSIVITY/${6}/g' constant/transportProperties \
        && laplacianFoam && echo && echo 'Centre of domain temperature is' \
        && tail -1 probes/0/T | sed 's/.* //g'"
