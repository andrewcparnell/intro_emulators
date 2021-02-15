# Script to go along with the half-day course 'Introduction to emulation'

# This script shows the steps to build an emulator for an OpenFOAM Navier-Stokes example

# Load in packages --------------------------------------------------------

rm(list = ls())
library(ggplot2)
library(GPfit)
library(lhs)
set.seed(123)

# Need to set the working directory here to where the openFOAM model is stored
# setwd("simulator2/elbowFlow2d/")

# Check simulator ---------------------------------------------------------

# These are the inputs
largeInletVelocityMagnitude <- 0.5 # Range (0,1)
smallInletVelocityMagnitude <- 0.5 # Range (0,1)
kinematicViscosity <- 1e-4 # Range (1e-5, 1e-3)

# Have to clean the system first
system("./dockerClean2.sh")

# Now run the simulator
answer <- system(paste(
  "./dockerRun.sh",
  largeInletVelocityMagnitude,
  smallInletVelocityMagnitude,
  kinematicViscosity
),
intern = TRUE
)

# Stored in the vector at position 434
answer[length(answer) - 1] # "0.760503"

# 1. Design ---------------------------------------------------------------

# I'm going to support I can afford to run the simulator 50 times

# Put in the ranges of each input
# 1 .Magnitude of velocity at large inlet (assumed to act into the domain normal to the edge); recommended range: 0 <= velocity <= 1
# 2. Magnitude of velocity at small inlet (assumed to act into the domain normal to the edge); recommended range: 0 <= velocity <= 1
# 3. Fluid kinematic viscosity; recommended range: 1e-5 < viscosity <= 1e-3

# Choose the number of runs I want to do
n_runs <- 20
n_inputs <- 3

# Now choose my initial grid using a Latin hypercube design
initial_grid <- maximinLHS(n_runs, n_inputs)
df_grid <- data.frame(
  largeInletVelocityMagnitude = initial_grid[, 1],
  smallInletVelocityMagnitude = initial_grid[, 2],
  kinematicViscosity = initial_grid[, 3] * (1e-5 - 1e-3) + 1e-3
)

# Plot bits of the design
ggplot(df_grid, aes(x = largeInletVelocityMagnitude, y = smallInletVelocityMagnitude)) +
  geom_point()
ggplot(df_grid, aes(x = largeInletVelocityMagnitude, y = kinematicViscosity)) +
  geom_point()
ggplot(df_grid, aes(x = smallInletVelocityMagnitude, y = kinematicViscosity)) +
  geom_point()

# Run the simulator at these values
# Create a container to hold the outputs
df_grid$out <- rep(NA, length = n_runs)

# Now run it
# for (i in 1:n_runs) {
#   print(i)
#   system("./dockerClean2.sh")
#   curr_answer <- system(paste("./dockerRun.sh",
#                          df_grid$largeInletVelocityMagnitude[i],
#                          df_grid$smallInletVelocityMagnitude[i],
#                          df_grid$kinematicViscosity[i]),
#                    intern = TRUE)
#   df_grid$out[i] <- as.numeric(curr_answer[length(curr_answer) - 1])
#   print(df_grid$out[i])
# }
# # Save these for later use
# saveRDS(df_grid, 'simulator_run.rds')
df_grid <- readRDS("simulator_run.rds")

# Plot some of the outputs
ggplot(df_grid, aes(x = largeInletVelocityMagnitude, y = smallInletVelocityMagnitude, colour = out)) +
  geom_point()
ggplot(df_grid, aes(x = largeInletVelocityMagnitude, y = smallInletVelocityMagnitude, colour = out)) +
  geom_point()
ggplot(df_grid, aes(x = smallInletVelocityMagnitude, y = kinematicViscosity, colour = out)) +
  geom_point()

# Also plot the output
qplot(df_grid$out)

# Build the emulator ------------------------------------------------------

# Fit the emulator
# emulator <- GP_fit(initial_grid, df_grid$out)
# saveRDS(emulator, 'emulator_run.rds')
emulator <- readRDS("emulator_run.rds")

# Check the emulator ------------------------------------------------------

# Method 1 - Create some plots

# Fix two values and vary the third
x1_new <- 0.5
x2_new <- 0.5
x3_new <- seq(0, 1, length = 100)
X_new <- matrix(NA, nrow = 100, ncol = n_inputs)
X_new[, 1] <- x1_new
X_new[, 2] <- x2_new
X_new[, 3] <- x3_new

# Now create predictions everywhere
pred <- predict(emulator, X_new)

# Create a new data frame for plotting
df_new <- data.frame(
  largeInletVelocityMagnitude = X_new[, 1],
  smallInletVelocityMagnitude = X_new[, 2],
  kinematicViscosity = X_new[, 3] * (1e-5 - 1e-3) + 1e-3,
  yhat = pred$Y_hat,
  ylow = pred$Y_hat - 1.96 * sqrt(pred$MSE),
  yhigh = pred$Y_hat + 1.96 * sqrt(pred$MSE)
)

ggplot(df_new, aes(x = kinematicViscosity, y = yhat)) +
  geom_line()

# Plot this again but with uncertainties
ggplot(df_new, aes(x = kinematicViscosity, y = yhat)) +
  geom_line() +
  ggtitle("Large inlet and Small inlet velocities fixed at 0.5") +
  geom_line(aes(y = ylow), linetype = "dotted") +
  geom_line(aes(y = yhigh), linetype = "dotted")

# Next try varying two parameters and fixing the other
x1_new <- seq(0, 1, length = 100)
x3_new <- seq(0, 1, length = 100)
x_new <- expand.grid(x1_new, x3_new)
# Now vary temperature left across this field
X_new <- matrix(x_max,
  nrow = nrow(x_new),
  ncol = n_inputs,
  byrow = TRUE
)
# Replace the first column with the varying variable
X_new[, 1] <- x_new[, 1]
X_new[, 2] <- 0.5
X_new[, 3] <- x_new[, 2]

# Now create predictions everywhere
pred <- predict(emulator, X_new)

# Create a new data frame for plotting
df_new <- data.frame(
  largeInletVelocityMagnitude = X_new[, 1],
  smallInletVelocityMagnitude = X_new[, 2],
  kinematicViscosity = X_new[, 3] * (1e-5 - 1e-3) + 1e-3,
  yhat = pred$Y_hat,
  RMSE = sqrt(pred$MSE)
)

ggplot(df_new, aes(x = largeInletVelocityMagnitude, y = kinematicViscosity, z = yhat)) +
  geom_contour_filled()
# Plot the RMSE instead
ggplot(df_new, aes(x = largeInletVelocityMagnitude, y = kinematicViscosity, z = RMSE)) +
  geom_contour_filled() +
  labs(fill = "RMSE") +
  ggtitle("Small inlet velocity fixed at 0.5")


# Method 2 - run some cross validations
# This is leave one out cross validation
# Remove one of the points, re-fit the GP and then see how badly it did
loo_fit <- rep(NA, n_runs)
for (i in 1:n_runs) {
  print(i)
  # Fit an emulator with one point missing
  curr_emulator <- GP_fit(
    initial_grid[-i, ],
    df_grid$out[-i]
  )
  # Get the prediction for the missing point
  loo_fit[i] <- predict(
    curr_emulator,
    initial_grid[i, , drop = FALSE]
  )$Y_hat
}
saveRDS(loo_fit, "loo_fits.rds")
loo_fit <- readRDS("loo_fit.rds")

# Now plot the left out fitted values against the true values
qplot(loo_fit, df_grid$out, geom = "point") +
  geom_abline() +
  xlab("LOO-CV fitted value") +
  ylab("True value")
# An amazingly good fit
