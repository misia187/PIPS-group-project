# Script: functions_analysis.R
# Purpose: Defines the functions that the analyses use more than once.
#          This file only defines functions; analyses.R runs them.
#          make_2x2_table(), phi_coefficient(), test_2x2():
#           used in every symptom-diagnosis test and comorbidity test
#          test_comorbidity():
#           run on the real data, and on every simulated dataset
# Date: 2026-10-19

#-------------------------------------------------------------------
# 1. LOAD PACKAGES
# No packages needed: chisq.test, fisher.test and p.adjust are base R.
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# 2. 2x2 TABLES AND TESTS
#-------------------------------------------------------------------

# make_2x2_table()
# Makes a 2x2 table of two 0/1 variables. The levels are fixed to 0 and 1,
# so the table is always 2x2, even if one value never occurs.
# Input:  x, y = two vectors of 0s and 1s
# Output: a 2x2 table (rows = x, columns = y)
make_2x2_table <- function(x, y) {
  table(factor(x, levels = c(0, 1)), factor(y, levels = c(0, 1)))
}

# phi_coefficient()
# Calculates phi: the correlation between two 0/1 variables
# (-1 to 1, 0 = no relation).
# Input:  tab = a 2x2 table from make_2x2_table()
# Output: one number
phi_coefficient <- function(tab) {
  # as.numeric() because multiplying large table counts can be too big
  # for R's whole numbers (integers) and would give NA
  a <- as.numeric(tab[1, 1])  # x = 0, y = 0
  b <- as.numeric(tab[1, 2])  # x = 0, y = 1
  c <- as.numeric(tab[2, 1])  # x = 1, y = 0
  d <- as.numeric(tab[2, 2])  # x = 1, y = 1
  
  (a * d - b * c) / sqrt((a + b) * (c + d) * (a + c) * (b + d))
}

# test_2x2()
# Tests whether two 0/1 variables are related. Uses a chi-square test,
# or Fisher's exact test when an expected count is below 5
# (the chi-square test is not reliable then).
# Input:  tab = a 2x2 table from make_2x2_table()
# Output: a list with test (name), statistic (chi-square, NA for Fisher)
#         and p (p-value)
test_2x2 <- function(tab) {
  expected <- suppressWarnings(chisq.test(tab)$expected)
  
  if (any(expected < 5)) {
    result <- fisher.test(tab)
    list(test = "Fisher", statistic = NA, p = result$p.value)
  } else {
    result <- chisq.test(tab)
    list(test = "chi-square", statistic = unname(result$statistic),
         p = result$p.value)
  }
}

#-------------------------------------------------------------------
# 3. COMORBIDITY: OBSERVED vs EXPECTED
# If two diagnoses are unrelated, the expected number of people with
# both is: (number with A) x (number with B) / (total number of people).
# A chi-square test checks whether the observed number differs from that.
# 5 diagnoses give 10 pairs, so the p-values are FDR-corrected.
#-------------------------------------------------------------------

# test_comorbidity()
# Compares observed and expected co-occurrence for every pair of diagnoses.
# Input:  dataset = data with one 0/1 column per diagnosis (real or simulated)
#         prefix  = start of the diagnosis column names: "dx_" for the
#                   diagnoses in the data (default), "rule_" for the
#                   diagnoses made by apply_dsm_rules() (e.g. in the simulation)
# Output: a data frame with one row per pair: disorder_1, disorder_2,
#         observed, expected, ratio (observed / expected), chi_square,
#         p, p_fdr
test_comorbidity <- function(dataset, prefix = "dx_") {
  disorders <- c("bipolar", "schizophrenia", "depression", "anxiety", "ptsd")
  n_people <- nrow(dataset)
  results <- data.frame()
  
  for (i in 1:(length(disorders) - 1)) {
    for (j in (i + 1):length(disorders)) {
      dx_1 <- dataset[[paste0(prefix, disorders[i])]]
      dx_2 <- dataset[[paste0(prefix, disorders[j])]]
      
      observed <- sum(dx_1 == 1 & dx_2 == 1)
      expected <- sum(dx_1) * sum(dx_2) / n_people
      test <- test_2x2(make_2x2_table(dx_1, dx_2))
      
      results <- rbind(results, data.frame(
        disorder_1 = disorders[i],
        disorder_2 = disorders[j],
        observed   = observed,
        expected   = round(expected, 1),
        ratio      = round(observed / expected, 2),
        chi_square = round(test$statistic, 2),
        p          = test$p
      ))
    }
  }
  
  results$p_fdr <- p.adjust(results$p, method = "BH")
  results
}
