# Script to go along with the half-day course 'Introduction to emulation'

# This script shows the steps to build an emulator for a simple 2D input sine wave example


# Load in packages --------------------------------------------------------

rm(list = ls())
library(ggplot2)
library(GPfit)
library(lhs)
set.seed(123)

# Create simulator --------------------------------------------------------

# Going to write the simulator as a function
f <- function(x1, x2) {
  stopifnot(x1 >= 0 & x1 <= 1) # Range of x1 is (0,1)
  stopifnot(x2 >= 0 & x2 <= 1) # Same for x2
  return(10 * sin(pi * x1 * x2)) # Simulator function
}
# f(0.7, 0.7)

# Create a quick plot of it
n <- 100 # Number of data points
x1 <- x2 <- seq(0, 1, length.out = n) # Range of x1 and x2
X <- expand.grid(x1, x2) # Expand to have all combinations of x1 and x2
df <-
  data.frame(
    x1 = X[, 1],
    x2 = X[, 2],
    y = f(X[, 1], X[, 2])
  ) # Turn into a data frame for plotting

# Contour plot using ggplot
ggplot(df, aes(x1, x2, z = y)) +
  geom_contour_filled()


# 1. Design ---------------------------------------------------------------

# I'm going to support I can afford to run the simulator twenty times (ignore the fact I just ran it 10,000 times above!)

# Choose the number of runs I want to do
n_grid <- 20
n_inputs <- 2

# Now choose my initial grid using a latin hypercube design
initial_grid <- maximinLHS(n_grid, n_inputs)
df_grid <- data.frame(
  x1 = initial_grid[, 1],
  x2 = initial_grid[, 2]
) 
# Beware - the LHS has to be on the region 0 to 1 so you usually need to re-sclae the values here

# Plot the design
ggplot(df_grid, aes(x = x1, y = x2)) +
  geom_point()

# Run the simulator at these values
# Create a container to hold the outputs
df_grid$out <- rep(NA, length = n_grid)

# Now run it
for (i in 1:n_grid) {
  df_grid$out[i] <- f(initial_grid[i, 1], initial_grid[i, 2])
}

# Plot the outputs
ggplot(df_grid, aes(x = x1, y = x2, colour = out)) +
  geom_point()

# Build the emulator ------------------------------------------------------

# Fit the emulator
emulator <- GP_fit(initial_grid, df_grid$out)

# Predict on a new grid of values
x_new <- seq(0, 1, length = 10) # Beware - we will create 10^6 new values!
X_new <- expand.grid(x_new, 
                     x_new)
pred <- predict(emulator, X_new)

# Create a new data frame for plotting
df_new <- data.frame(
  x1 = X_new[, 1],
  x2 = X_new[, 2],
  yhat = pred$Y_hat
)
ggplot(df_new, aes(x1, x2, z = yhat)) +
  geom_contour_filled()
# Looks pretty good!

# Check the emulator ------------------------------------------------------

# Method 1 - Create some plots (e.g. the above)

# Plot the uncertainty from the GP
df_new$se <- pred$MSE
ggplot(df_new, aes(x1, x2, z = se)) +
  geom_contour_filled()
# Mostly very low - especially in the centre

# Method 2 - run some cross validations
# This is leave one out cross validation
# Remove one of the points, re-fit the GP and then see how badly it did
loo_fit <- rep(NA, n_grid)
for (i in 1:n_grid) {
  # Fit an emulator with one point missing
  curr_emulator <- GP_fit(
    df_grid[-i, 1:n_inputs],
    df_grid$out[-i]
  )
  # Get the prediction for the missing point
  loo_fit[i] <- predict(
    curr_emulator,
    df_grid[i, 1:n_inputs]
  )$Y_hat
}

# Now plot the left out fitted values against the true values
qplot(loo_fit, df_grid$out, geom = "point") +
  geom_abline() +
  xlab("LOO-CV fitted value") +
  ylab("True value")
# Could go back and explore these some more
