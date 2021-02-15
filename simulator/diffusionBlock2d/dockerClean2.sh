#!/bin/bash

# Script used to clear the results and mesh from the model and reset the
# variables; this should be run before dockerRun.sh is run
# Philip Cardiff, UCD
# 18-Jan-20

docker run --mount src=$(PWD),target=/home/app/model,type=bind \
       philippic/foam-extend-4.0-ubuntu18.04:latest bash -c \
       'source /home/app/foam/foam-extend-4.0/etc/bashrc > /dev/null \
       && cd model && foamCleanTutorials \
       && \cp 0/org/T 0/ && \cp constant/org/transportProperties constant'
