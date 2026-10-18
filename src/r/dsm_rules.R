# Script: dsm_rules.R
# Purpose: Rebuild the five diagnoses in the Mentalillness dataset from the
#          symptom columns, using DSM-style counting rules, and check that
#          the rebuilt diagnoses match the dx_ columns in the data.
#          Sourcing this script only defines the functions; main.Rmd calls them.
#          Needs the variable key from variable_key.R and the renamed data
#          from load_mental_illness() in functions.R.
#          apply_dsm_rules() can also be used for the simulation: change the
#          thresholds to see what happens to prevalence and comorbidity.
# Date: 2026-10-18

#-------------------------------------------------------------------
# 1. LOAD PACKAGES
# dplyr: mutate() to add the rebuilt diagnoses as new columns
#-------------------------------------------------------------------
suppressPackageStartupMessages(library(dplyr))

#-------------------------------------------------------------------
# 2. THRESHOLDS
# The rules found in the data (verified on all 3,753 rows):
#   Bipolar       at least 3 of 7 symptoms
#   Depression    at least 5 of 9 symptoms
#   Anxiety       at least 2 of 6 symptoms AND 6-month duration
#   Schizophrenia at least 1 positive symptom AND at least 2 items in
#                 total (6 symptoms + the 1-month duration item)
#   PTSD          A >= 1, B >= 1, C >= 1, D >= 2, E >= 2,
#                 and F, G and H all present
#-------------------------------------------------------------------

# default_thresholds()
# Gives the minimum number of items needed for each rule.
# Input:  none
# Output: a named list of numbers. Change a number to try a different rule,
#         e.g. th <- default_thresholds(); th$depression <- 4
default_thresholds <- function() {
  list(
    bipolar       = 3,  # symptoms out of 7
    depression    = 5,  # symptoms out of 9
    anxiety       = 2,  # symptoms out of 6 (plus 6-month duration)
    scz_positive  = 1,  # positive symptoms out of 3
    scz_total     = 2,  # items out of 7 (6 symptoms + duration)
    ptsd_A        = 1,  # exposure, out of 2
    ptsd_B        = 1,  # intrusion, out of 4
    ptsd_C        = 1,  # avoidance, out of 2
    ptsd_D        = 2,  # cognition and mood, out of 6
    ptsd_E        = 2   # arousal, out of 6
  )
}

#-------------------------------------------------------------------
# 3. HELPER FUNCTIONS
#-------------------------------------------------------------------

# get_columns()
# Looks up which columns belong to a disorder and criterion in the key.
# Input:  key       = the variable key from make_variable_key()
#         disorder  = e.g. "bipolar"
#         criterion = one or more criterion labels, e.g. "symptom"
# Output: a vector of short column names
get_columns <- function(key, disorder, criterion) {
  rows <- key$disorder == disorder & key$criterion %in% criterion
  columns <- key$name[rows]
  
  if (length(columns) == 0) {
    stop("No columns found for ", disorder, " / ",
         paste(criterion, collapse = ", "))
  }
  columns
}

# count_items()
# Counts, for each participant, how many of the given columns are 1.
# Input:  dataset = a data frame with 0/1 columns
#         columns = names of the columns to count
# Output: a vector with one count per participant (row)
count_items <- function(dataset, columns) {
  rowSums(dataset[, columns, drop = FALSE])
}

#-------------------------------------------------------------------
# 4. APPLY THE RULES
#-------------------------------------------------------------------

# apply_dsm_rules()
# Counts the symptoms per disorder (and per PTSD criterion) and rebuilds
# the five diagnoses from those counts.
# Input:  dataset    = the renamed data from load_mental_illness()
#         key        = the variable key from make_variable_key()
#         thresholds = list from default_thresholds() (or a changed copy)
# Output: the same data frame with extra columns:
#         n_  = symptom counts (e.g. n_bipolar, n_ptsd_D)
#         rule_ = rebuilt diagnosis, 0 or 1 (e.g. rule_bipolar)
apply_dsm_rules <- function(dataset, key, thresholds = default_thresholds()) {
  th <- thresholds
  
  # Step 1: count symptoms per disorder
  dataset$n_bipolar    <- count_items(dataset, get_columns(key, "bipolar", "symptom"))
  dataset$n_depression <- count_items(dataset, get_columns(key, "depression", "symptom"))
  dataset$n_anxiety    <- count_items(dataset, get_columns(key, "anxiety", "symptom"))
  
  # Schizophrenia: positive symptoms, and all items together
  # (positive + other symptoms + the 1-month duration item)
  dataset$n_scz_positive <- count_items(dataset, get_columns(key, "schizophrenia", "positive"))
  dataset$n_scz_total    <- count_items(dataset, get_columns(key, "schizophrenia",
                                                             c("positive", "other", "duration")))
  
  # PTSD: one count per DSM-5 criterion
  dataset$n_ptsd_A <- count_items(dataset, get_columns(key, "ptsd", "A_exposure"))
  dataset$n_ptsd_B <- count_items(dataset, get_columns(key, "ptsd", "B_intrusion"))
  dataset$n_ptsd_C <- count_items(dataset, get_columns(key, "ptsd", "C_avoidance"))
  dataset$n_ptsd_D <- count_items(dataset, get_columns(key, "ptsd", "D_cognition_mood"))
  dataset$n_ptsd_E <- count_items(dataset, get_columns(key, "ptsd", "E_arousal"))
  
  # Step 2: turn the counts into diagnoses (1 = rule met, 0 = not met)
  dataset <- dataset %>%
    mutate(
      rule_bipolar    = ifelse(n_bipolar >= th$bipolar, 1, 0),
      rule_depression = ifelse(n_depression >= th$depression, 1, 0),
      rule_anxiety    = ifelse(n_anxiety >= th$anxiety &
                                 anx_duration_6_months == 1, 1, 0),
      rule_schizophrenia = ifelse(n_scz_positive >= th$scz_positive &
                                    n_scz_total >= th$scz_total, 1, 0),
      rule_ptsd = ifelse(n_ptsd_A >= th$ptsd_A &
                           n_ptsd_B >= th$ptsd_B &
                           n_ptsd_C >= th$ptsd_C &
                           n_ptsd_D >= th$ptsd_D &
                           n_ptsd_E >= th$ptsd_E &
                           ptsd_duration_1_month == 1 &       # F
                           ptsd_clinical_distress == 1 &      # G
                           ptsd_not_substance_induced == 1,   # H
                         1, 0)
    )
  
  dataset
}

#-------------------------------------------------------------------
# 5. VERIFY THE RULES
#-------------------------------------------------------------------

# verify_dsm_rules()
# Compares each rebuilt diagnosis (rule_) with the diagnosis in the data (dx_).
# Input:  dataset = output of apply_dsm_rules()
# Output: a data frame with one row per disorder: how many participants
#         have the diagnosis in the data, how many by our rule, and how
#         many rows agree. Prints a message saying whether all rows match.
verify_dsm_rules <- function(dataset) {
  disorders <- c("bipolar", "depression", "anxiety", "schizophrenia", "ptsd")
  results <- data.frame()
  
  for (disorder in disorders) {
    # Stop if apply_dsm_rules() has not been run on this data yet
    if (!(paste0("rule_", disorder) %in% names(dataset))) {
      stop("Column rule_", disorder, " not found. ",
           "Run apply_dsm_rules() first and pass its output to verify_dsm_rules().")
    }
    
    observed <- dataset[[paste0("dx_", disorder)]]
    rebuilt  <- dataset[[paste0("rule_", disorder)]]
    
    n_match <- sum(observed == rebuilt)
    
    results <- rbind(results, data.frame(
      disorder      = disorder,
      n_observed    = sum(observed),
      n_rebuilt     = sum(rebuilt),
      n_match       = n_match,
      percent_match = round(100 * n_match / nrow(dataset), 2)
    ))
  }
  
  if (all(results$n_match == nrow(dataset))) {
    message("All five diagnoses are reproduced exactly (",
            nrow(dataset), " of ", nrow(dataset), " rows).")
  } else {
    message("Not all diagnoses match: see the n_match column.")
  }
  
  results
}
