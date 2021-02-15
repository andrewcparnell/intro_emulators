# Script to go along with the half-day course 'Introduction to emulation' 

# This script shows the steps to build an emulator for an OpenFOAM 2D temperature field

# Load in packages --------------------------------------------------------

rm(list = ls())
library(ggplot2)
library(GPfit)
library(lhs)
set.seed(123)

# Need to set the working directory here to where the openFOAM model is stored
setwd("simulator/diffusionBlock2d/")

# Check simulator ---------------------------------------------------------

# These are the inputs
tempLeft <- 0
tempRight <- 50
fluxUp <- -200
fluxDown <- 500
tempInitial <- 50
diffusivity <- 1

# Have to clean the system first
system("./dockerClean2.sh")

# Now run the simulator
answer <- system(paste("./dockerRun.sh",
                       tempLeft,
                       tempRight,
                       fluxUp,
                       fluxDown,
                       tempInitial,
                       diffusivity),
                 intern = TRUE)

# Stored in the vector at position 120
answer[120] # "45.7103"

# 1. Design ---------------------------------------------------------------

# I'm going to support I can afford to run the simulator 50 times 

# Put in the ranges of each input
# 0 < tempLeft <= 100 (can represent temperature in degrees Celsius or Kelvin)
# 0 < tempRight <= 100
# -1000 <= fluxUp <= 1000
# -1000 <= fluxDown <= 1000
# 0 <= tempInitial <= 100
# 0 < diffusivity < 1000

# Choose the number of runs I want to do
n_grid = 50
n_inputs <- 6

# Now choose my initial grid using a latin hypercube design
initial_grid = maximinLHS(n_grid, n_inputs)
df_grid <- data.frame(
  tempLeft = initial_grid[,1]*100,
  tempRight = initial_grid[,2]*100,
  fluxUp = initial_grid[,3]*2000 - 1000,
  fluxDown = initial_grid[,4]*2000 - 1000,
  tempInitial = initial_grid[,5]*100,
  diffusivity = initial_grid[,6]*1000
)

# Plot bits of the design
ggplot(df_grid, aes(x = tempLeft, y = tempRight)) + 
  geom_point()
ggplot(df_grid, aes(x = fluxUp, y = fluxDown)) + 
  geom_point()
ggplot(df_grid, aes(x = tempInitial, y = diffusivity)) + 
  geom_point()

# Run the simulator at these values
# Create a container to hold the outputs
df_grid$out <- rep(NA, length = n_grid)

# Now run it
for (i in 1:n_grid) {
  print(i)
  system("./dockerClean2.sh")
  curr_answer <- system(paste("./dockerRun.sh",
                         df_grid$tempLeft[i],
                         df_grid$tempRight[i],
                         df_grid$fluxUp[i],
                         df_grid$fluxDown[i],
                         df_grid$tempInitial[i],
                         df_grid$diffusivity[i]),
                   intern = TRUE)
  df_grid$out[i] <- as.numeric(curr_answer[120])
}
# Save these for later use
saveRDS(df_grid, 'simulator_run.rds')

# Plot some of the outputs
ggplot(df_grid, aes(x = tempLeft, y = tempRight, colour = out)) + 
  geom_point()
ggplot(df_grid, aes(x = fluxUp, y = fluxDown, colour = out)) + 
  geom_point()
ggplot(df_grid, aes(x = tempInitial, y = diffusivity, colour = out)) + 
  geom_point()

# Also plot the output
qplot(df_grid$out)

# Build the emulator ------------------------------------------------------

# Fit the emulator 
emulator <- GP_fit(initial_grid, df_grid$out)
saveRDS(emulator, 'emulator_run.rds')

# Check the emulator ------------------------------------------------------

# Method 1 - Create some plots

# One thing would be to try varying two parameters and fixing all the others
x1_new <- seq(0, 1, length = 100)
x2_new <- seq(0, 1, length = 100)  
x_new <- expand.grid(x1_new, x2_new)
# Find the input row with the highest temperature value
x_max <- initial_grid[which.max(emulator$Y),]
# Now vary temperature left across this field
X_new <- matrix(x_max, nrow = nrow(x_new), 
                ncol = n_inputs,
                byrow = TRUE)
# Replace the first column with the varying variable
X_new[,1] <- x_new[,1]
X_new[,2] <- x_new[,2]

# Now create predictions everywhere
pred <- predict(emulator, X_new)

# Create a new data frame for plotting
df_new <- data.frame(
  tempLeft = X_new[,1]*100,
  tempRight = X_new[,2]*100,
  fluxUp = X_new[,3]*2000 - 1000,
  fluxDown = X_new[,4]*2000 - 1000,
  tempInitial = X_new[,5]*100,
  diffusivity = X_new[,6]*1000,
  yhat = pred$Y_hat
)

ggplot(df_new, aes(x = tempLeft, y = tempRight, z = yhat)) +
  geom_contour_filled()

# Plot the uncertainty from the GP
df_new$se <- pred$MSE
ggplot(df_new, aes(tempLeft, tempRight, z = se)) +
  geom_contour_filled()
# Mostly very low - especially in the centre

# Method 2 - run some cross validations
# This is leave one out cross validation
# Remove one of the points, re-fit the GP and then see how badly it did
loo_fit <- rep(NA, n_grid)
for (i in 1:n_grid) {
  print(i)
  # Fit an emulator with one point missing
  curr_emulator <- GP_fit(initial_grid[-i,], 
                          df_grid$out[-i])
  # Get the prediction for the missing point
  loo_fit[i] <- predict(curr_emulator, 
                        initial_grid[i,,drop = FALSE])$Y_hat
}
saveRDS(loo_fit, 'loo_fits.rds')

# Now plot the left out fitted values against the true values
qplot(loo_fit, df_grid$out, geom = 'point') + 
  geom_abline() + 
  xlab('LOO-CV fitted value') + 
  ylab("True value")
# An amazingly good fit



