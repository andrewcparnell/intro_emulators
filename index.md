# Introduction to Emulation

Welcome to a short course that covers introductory emulation using R. 

All the slides for the course are available in pdf format in the [`slides`](https://github.com/andrewcparnell/intro_emulators/tree/master/slides) folder. The videos associated with the slides are shown below. The code associated with the two examples provided is in the [`code`](https://github.com/andrewcparnell/intro_emulators/tree/master/code) folder.

Sessions:

 1. Overview (17 mins) - [stream video](https://media.heanet.ie/page/34a0a93694db46e7ba6f700bd6e5a188) - [download video](https://media.heanet.ie/download/34a0a93694db46e7ba6f700bd6e5a188) 
 2. Emulators and Design (17 mins) - [stream video](https://media.heanet.ie/page/749aa3decd294c5cb683cff4b2536f97) - [download video](https://media.heanet.ie/download/749aa3decd294c5cb683cff4b2536f97) 
 3. Building Emulators (24 mins) - [stream video](https://media.heanet.ie/page/812b8cde14024ec2add9ebe2838f27f3) - [download video](https://media.heanet.ie/download/812b8cde14024ec2add9ebe2838f27f3) 
 4. Plotting, Checking, and Calibrating Emulators (18 mins) - [stream video](https://media.heanet.ie/page/7b5bae854f1c409ea98a30e10be73a95) - [download video](https://media.heanet.ie/download/7b5bae854f1c409ea98a30e10be73a95) 
 5. Deploying and Extending the Emulator (10 mins) - [stream video](https://media.heanet.ie/page/c2a08463d0244f6094e0a36c55888712) - [download video](https://media.heanet.ie/download/c2a08463d0244f6094e0a36c55888712) 

You should watch the videos above first and then try to follow the code by downloading the software and running it yourself whilst watching the videos. 

# Running the code associated with the slides

To get started make sure you have downloaded [R](https://www.r-project.org) and [Rstudio](https://rstudio.com/products/rstudio/download/).

Then open up Rstudio and in the Console window type:
`install.packages(c('GPfit', 'ggplot2', 'lhs'))`

To be able to run the larger example, you will need to download and install [docker](https://www.docker.com). If you are running Windows you might need to install [these additional steps](https://blog.jayway.com/2017/04/19/running-docker-on-bash-on-windows/).

If all works well, you are now ready to start the course. Download all the files for the course by clicking [here](https://github.com/andrewcparnell/intro_emulators/archive/master.zip). Unzip this file and then double click on the `intro_emulators.Rproj` file. You can now start coding!

If you run into problems or find broken links please use the [issues](https://github.com/andrewcparnell/intro_emulation/issues) page. 

(An older version of this course contained a much shorter introduction to stochastic emulation. The video associated with those slides is [here](https://media.heanet.ie/download/896172607cea4cdaa9001dc3260be3dd).)
