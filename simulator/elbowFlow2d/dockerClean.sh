#!/bin/bash

# Script used to clear the results and mesh from the model and reset the
# variables; this should be run before dockerRun.sh is run
# Philip Cardiff, UCD
# Feb-21

docker run -it --mount src=$(PWD),target=/home/app/model,type=bind \
       philippic/foam-extend-4.0-ubuntu18.04:latest bash -c \
       'source /home/app/foam/foam-extend-4.0/etc/bashrc > /dev/null \
       && cd model && \rm -rf 0.* [1-9]* probes case.foam \
       && \cp 0/org/U 0/ && \cp constant/org/transportProperties constant'
