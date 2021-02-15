#!/bin/bash

# Script to numerically solve a 2-D flow problem using OpenFOAM 
# Philip Cardiff, UCD
# Feb-21

# Before running this script, you should pull the public docker image of
# foam-extend-4.0 (fork of OpenFOAM). You can pull the image with:
# $> docker pull philippic/foam-extend-4.0-ubuntu18.04

# Run the diffusion PDE model using the docker image
echo "Solving 2-D steady-state Navier-Stokes PDE in OpenFOAM"

# Check number of input parameters is correct
if [[ $# -ne 3 ]]
then
    echo
    echo "Incorrect number of parameters"; echo
    echo "Usage: dockerRun.sh largeInletVelocityMagnitude \
smallInletVelocityMagnitude kinematicViscosity "; echo
    echo "For example:"
    echo "    ./dockerRun.sh 0.1 1 1e-05"
    echo
    exit
fi

# Check that the case has been cleaned and the placeholders have been replaced
if ! grep -q "SMALL_INLET_VELOCITY" 0/U
then
    echo
    echo "Please run './dockerClean.sh' first!"
    echo
    exit 1
fi

# Run OpenFOAM
docker run --rm --mount src=$(PWD),target=/home/app/model,type=bind \
       philippic/foam-extend-4.0-ubuntu18.04:latest bash -c \
       "source /home/app/foam/foam-extend-4.0/etc/bashrc > /dev/null \
        && cd model \
        && sed -i 's/SMALL_INLET_VELOCITY/${1}/g' 0/U \
        && sed -i 's/LARGE_INLET_VELOCITY/${2}/g' 0/U \
        && sed -i 's/VISCOSITY/${3}/g' constant/transportProperties \
        && simpleFoam"

# Print the velocity magnitude at a point to the stdout
echo; echo "Velocity magnitude at the centre of the pipe after the mixing point is"
tail -1 probes/0/U | awk '{gsub(/[()]/,""); print sqrt($2*$2+$3*$3)}'
echo
