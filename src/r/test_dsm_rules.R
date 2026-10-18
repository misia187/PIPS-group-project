# Script: test_dsm_rules.R
# Purpose: Test the DSM rules in dsm_rules.R on made-up participants
#          whose correct diagnosis we know in advance. Each test puts
#          people exactly at a cutoff (or just below it), because that is
#          where mistakes like ">" instead of ">=" would show up.
#          Sourcing this script only defines the functions; main.Rmd calls them.
#          Needs dsm_rules.R (and its functions) to be sourced first.
# Date: 2026-10-18

#-------------------------------------------------------------------
# 1. LOAD PACKAGES
# No packages needed here: this script only uses base R and the
# functions from dsm_rules.R (which loads dplyr itself).
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# 2. HELPER FUNCTIONS
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

#-------------------------------------------------------------------
# 3. RUN ALL TESTS
# Each block below:
#   a) makes a few test people with all symptoms at 0
#   b) switches on the symptoms needed for the test
#   c) runs apply_dsm_rules() and checks the diagnosis
#-------------------------------------------------------------------

# test_dsm_rules()
# Runs all edge-case tests for the five diagnoses and the thresholds.
# Input:  dataset = the renamed data from load_mental_illness()
#         key     = the variable key from make_variable_key()
# Output: a data frame with one row per test (test, passed).
#         Also prints PASS/FAIL per test and a summary.
test_dsm_rules <- function(dataset, key) {
  test_names <- c()
  results <- c()
  
  # --- Bipolar: at least 3 of 7 symptoms ---
  bip <- get_columns(key, "bipolar", "symptom")
  people <- make_test_people(dataset, key, 2)
  people[1, bip[1:3]] <- 1   # exactly 3 -> diagnosed
  people[2, bip[1:2]] <- 1   # only 2    -> not diagnosed
  result <- apply_dsm_rules(people, key)
  
  name <- "Bipolar: 3 symptoms = yes, 2 = no"
  test_names <- c(test_names, name)
  results <- c(results, check_result(name, result$rule_bipolar, c(1, 0)))
  
  # --- Depression: at least 5 of 9 symptoms ---
  dep <- get_columns(key, "depression", "symptom")
  people <- make_test_people(dataset, key, 2)
  people[1, dep[1:5]] <- 1   # exactly 5 -> diagnosed
  people[2, dep[1:4]] <- 1   # only 4    -> not diagnosed
  result <- apply_dsm_rules(people, key)
  
  name <- "Depression: 5 symptoms = yes, 4 = no"
  test_names <- c(test_names, name)
  results <- c(results, check_result(name, result$rule_depression, c(1, 0)))
  
  # --- Anxiety: at least 2 of 6 symptoms AND 6-month duration ---
  anx <- get_columns(key, "anxiety", "symptom")
  people <- make_test_people(dataset, key, 3)
  people[1, anx[1:2]] <- 1                 # 2 symptoms + duration -> yes
  people[1, "anx_duration_6_months"] <- 1
  people[2, anx[1:2]] <- 1                 # 2 symptoms, no duration -> no
  people[3, anx[1]] <- 1                   # 1 symptom + duration -> no
  people[3, "anx_duration_6_months"] <- 1
  result <- apply_dsm_rules(people, key)
  
  name <- "Anxiety: needs 2 symptoms AND duration"
  test_names <- c(test_names, name)
  results <- c(results, check_result(name, result$rule_anxiety, c(1, 0, 0)))
  
  # --- Schizophrenia: >= 1 positive AND >= 2 items in total ---
  scz_positive <- get_columns(key, "schizophrenia", "positive")
  scz_other    <- get_columns(key, "schizophrenia", "other")
  people <- make_test_people(dataset, key, 4)
  people[1, scz_positive[1]] <- 1          # 1 positive + 1 other -> yes
  people[1, scz_other[1]] <- 1
  people[2, scz_positive[1]] <- 1          # 1 positive + duration -> yes
  people[2, "scz_duration_1_month"] <- 1   # (duration counts as an item)
  people[3, scz_other[1:2]] <- 1           # 2 other, no positive -> no
  people[4, scz_positive[1]] <- 1          # 1 positive only -> no
  result <- apply_dsm_rules(people, key)
  
  name <- "Schizophrenia: positive symptom needed, 2 items in total"
  test_names <- c(test_names, name)
  results <- c(results, check_result(name, result$rule_schizophrenia, c(1, 1, 0, 0)))
  
  # --- PTSD: A>=1, B>=1, C>=1, D>=2, E>=2, and F, G, H present ---
  ptsd_A <- get_columns(key, "ptsd", "A_exposure")
  ptsd_B <- get_columns(key, "ptsd", "B_intrusion")
  ptsd_C <- get_columns(key, "ptsd", "C_avoidance")
  ptsd_D <- get_columns(key, "ptsd", "D_cognition_mood")
  ptsd_E <- get_columns(key, "ptsd", "E_arousal")
  ptsd_FGH <- get_columns(key, "ptsd", c("F_duration", "G_distress", "H_not_substance"))
  
  # The smallest set of items that meets every criterion
  ptsd_minimum <- c(ptsd_A[1], ptsd_B[1], ptsd_C[1],
                    ptsd_D[1:2], ptsd_E[1:2], ptsd_FGH)
  
  people <- make_test_people(dataset, key, 3)
  people[1:3, ptsd_minimum] <- 1           # everyone starts at the minimum
  people[2, "ptsd_clinical_distress"] <- 0 # person 2: no G -> no
  people[3, ptsd_D[2]] <- 0                # person 3: only 1 D item -> no
  result <- apply_dsm_rules(people, key)
  
  name <- "PTSD: all minimums = yes, missing G or 1 D item = no"
  test_names <- c(test_names, name)
  results <- c(results, check_result(name, result$rule_ptsd, c(1, 0, 0)))
  
  # --- Thresholds: changing a threshold changes the diagnosis ---
  people <- make_test_people(dataset, key, 1)
  people[1, bip[1:2]] <- 1                 # 2 bipolar symptoms
  th <- default_thresholds()
  th$bipolar <- 2                          # lower the cutoff to 2
  result <- apply_dsm_rules(people, key, th)
  
  name <- "Thresholds: bipolar cutoff 2 diagnoses someone with 2 symptoms"
  test_names <- c(test_names, name)
  results <- c(results, check_result(name, result$rule_bipolar, 1))
  
  # --- Summary ---
  n_failed <- sum(!results)
  if (n_failed == 0) {
    message("All ", length(results), " tests passed.")
  } else {
    message(n_failed, " of ", length(results), " tests failed.")
  }
  
  data.frame(test = test_names, passed = results)
}
