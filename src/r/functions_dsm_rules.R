# Script: functions_dsm_rules.R
# Purpose: Defines the DSM-style counting rules that rebuild the five
#          diagnoses from the symptom columns, plus two small helpers for
#          testing the rules. This file only defines things; the script
#          test_dsm_rules.R runs the checks, and analyses.R uses the rules.
#          apply_dsm_rules() is a function because it is run many times:
#          on the real data, in every test, and in the simulation (with
#          changed thresholds).
#          Needs the variable key from variable_key.R.
# Date: 2026-10-19

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
#
# default_thresholds is a plain list. To try a different rule, copy it
# and change a number:
#   th <- default_thresholds
#   th$depression <- 4
#-------------------------------------------------------------------

default_thresholds <- list(
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

#-------------------------------------------------------------------
# 3. LOOK UP COLUMNS
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

apply_dsm_rules <- function(dataset, key, thresholds = default_thresholds) {
  th <- thresholds
  
  # Step 1: count symptoms per disorder
  # (rowSums adds up the 0/1 columns for each participant)
  dataset$n_bipolar    <- rowSums(dataset[, get_columns(key, "bipolar", "symptom")])
  dataset$n_depression <- rowSums(dataset[, get_columns(key, "depression", "symptom")])
  dataset$n_anxiety    <- rowSums(dataset[, get_columns(key, "anxiety", "symptom")])
  
  # Schizophrenia: positive symptoms, and all items together
  # (positive + other symptoms + the 1-month duration item)
  dataset$n_scz_positive <- rowSums(dataset[, get_columns(key, "schizophrenia", "positive")])
  dataset$n_scz_total    <- rowSums(dataset[, get_columns(key, "schizophrenia",
                                                          c("positive", "other", "duration"))])
  
  # PTSD: one count per DSM-5 criterion
  dataset$n_ptsd_A <- rowSums(dataset[, get_columns(key, "ptsd", "A_exposure")])
  dataset$n_ptsd_B <- rowSums(dataset[, get_columns(key, "ptsd", "B_intrusion")])
  dataset$n_ptsd_C <- rowSums(dataset[, get_columns(key, "ptsd", "C_avoidance")])
  dataset$n_ptsd_D <- rowSums(dataset[, get_columns(key, "ptsd", "D_cognition_mood")])
  dataset$n_ptsd_E <- rowSums(dataset[, get_columns(key, "ptsd", "E_arousal")])
  
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
# 5. HELPERS FOR TESTING THE RULES
# Used by every test in test_dsm_rules.R
#-------------------------------------------------------------------

# make_test_people()
# Makes made-up participants with every symptom set to 0, so each test
# can switch on exactly the symptoms it needs.
# Input:  dataset = the renamed data (used as a template for the columns)
#         key     = the variable key from make_variable_key()
#         n       = how many participants to make
# Output: a data frame with n rows, all symptom/criterion columns 0
make_test_people <- function(dataset, key, n) {
  people <- dataset[rep(1, n), ]   # n copies of the first row
  rownames(people) <- NULL
  
  symptom_cols <- key$name[key$criterion != "diagnosis"]
  people[, symptom_cols] <- 0
  people
}

# check_result()
# Compares what the rules gave with what we expected and prints the result.
# Input:  test_name = short description of the test
#         actual    = rebuilt diagnoses (e.g. result$rule_bipolar)
#         expected  = the diagnoses we expect, e.g. c(1, 0)
# Output: TRUE if the test passed, FALSE if not (and prints PASS or FAIL)
check_result <- function(test_name, actual, expected) {
  passed <- all(actual == expected)
  
  if (passed) {
    message("PASS: ", test_name)
  } else {
    message("FAIL: ", test_name,
            " (expected ", paste(expected, collapse = ", "),
            ", got ", paste(actual, collapse = ", "), ")")
  }
  passed
}

