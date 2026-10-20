# Script: functions_data.R
# Purpose: Defines the functions for loading and checking the Mentalillness
#          dataset. This file only defines functions; the run scripts
#          (test_dsm_rules.R, analyses.R) source it and call them.
#          load_mental_illness() needs the variable key from
#          functions_variable_key.R.
# Date: 2026-10-18

#-------------------------------------------------------------------
# 1. LOAD PACKAGES
# No packages needed: this script only uses base R.
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# 2. CHECK DATA
#-------------------------------------------------------------------

# check_binary()
# Checks that each column only contains 0 or 1 (no missing values).
# Input:  dataset = a data frame
#         columns = names of the columns to check
# Output: none; stops with an error naming the first column that fails

check_binary <- function(dataset, columns) {
  for (col in columns) {
    if (!all(dataset[[col]] %in% c(0, 1))) {
      stop("Column '", col, "' contains values other than 0 or 1.")
    }
  }
  message("Check passed: all ", length(columns), " columns contain only 0 and 1.")
}

#-------------------------------------------------------------------
# 3. LOAD AND RENAME DATA
#-------------------------------------------------------------------

# load_mental_illness()
# Reads the dataset, renames every column to its short name from the key,
# and checks that all values are 0 or 1.
# Input:  path = location of Mentalillness.csv
#         key  = the variable key from make_variable_key() (variable_key.R)
# Output: a data frame with an id column and 58 renamed columns
load_mental_illness <- function(path = "data/Mentalillness.csv", key) {
  if (!file.exists(path)) {
    stop("Data file not found: ", path)
  }
  
  # check.names = FALSE keeps the original column names (with spaces).
  # Without it, R changes "1 month duration" into "X1.month.duration".
  dataset <- read.csv(path, check.names = FALSE)
  
  # "Sleep disturbance" appears twice: once for anxiety, once for PTSD.
  # Rename the second one (the PTSD one) to match the key.
  sleep_cols <- which(names(dataset) == "Sleep disturbance")
  names(dataset)[sleep_cols[2]] <- "Sleep disturbance (PTSD)"
  
  # Replace each original column name with its short name
  for (i in 1:nrow(key)) {
    old_name <- key$original[i]
    new_name <- key$name[i]
    
    if (!(old_name %in% names(dataset))) {
      stop("Column not found in the data: ", old_name)
    }
    
    names(dataset)[names(dataset) == old_name] <- new_name
  }
  names(dataset)[names(dataset) == "ID"] <- "id"
  
  check_binary(dataset, key$name)
  dataset
}

