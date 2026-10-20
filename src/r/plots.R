# Script: plots.R
# Purpose: Make the plots from the result tables of analyses.R and save them:
#            (1) heatmap of symptom-diagnosis relations (phi)
#            (2) observed vs expected comorbidity
#            (3) proportion diagnosed by symptom count (step plot)
#          Run analyses.R first: this script reads its tables from
#          output/tables/. Run from the project folder.
# Date: 2026-10-19

#-------------------------------------------------------------------
# 1. LOAD PACKAGES, THRESHOLDS & RESULTS
# ggplot2: all plots
#-------------------------------------------------------------------
library(ggplot2)
source("src/r/functions_dsm_rules.R")   # default_thresholds, for the cutoff lines

if (!file.exists("output/tables/symptom_associations.csv")) {
  stop("Result tables not found. Run src/r/analyses.R first.")
}

associations <- read.csv("output/tables/symptom_associations.csv")
comorbidity  <- read.csv("output/tables/comorbidity.csv")
count_steps  <- read.csv("output/tables/count_vs_diagnosis.csv")

disorders <- c("bipolar", "schizophrenia", "depression", "anxiety", "ptsd")

# Folder for the figures
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

#-------------------------------------------------------------------
# 2. SYMPTOM x DIAGNOSIS HEATMAP
# One row per symptom, one column per diagnosis, colour = phi.
# Symptoms are grouped by the disorder they belong to.
# A star marks a significant relation after FDR correction.
#-------------------------------------------------------------------

# Keep the symptoms in the order of the variable key
# (rev() so the first symptom is at the top of the plot)
symptom_order <- unique(associations$symptom)
associations$symptom <- factor(associations$symptom, levels = rev(symptom_order))
associations$diagnosis <- factor(associations$diagnosis, levels = disorders)
associations$symptom_disorder <- factor(associations$symptom_disorder, levels = disorders)
associations$star <- ifelse(associations$significant, "*", "")

heatmap_plot <- ggplot(associations, aes(x = diagnosis, y = symptom, fill = phi)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = star), size = 3, vjust = 0.75) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                       midpoint = 0, limits = c(-1, 1)) +
  # One block of rows per disorder; space = "free_y" keeps rows equal height
  facet_grid(symptom_disorder ~ ., scales = "free_y", space = "free_y") +
  labs(title = "Relation between each symptom and each diagnosis",
       subtitle = "* = significant after FDR correction (q < .05)",
       x = "Diagnosis", y = NULL, fill = "phi") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6),
        strip.text.y = element_text(angle = 0),
        panel.grid = element_blank())

print(heatmap_plot)
ggsave("output/figures/symptom_heatmap.png", heatmap_plot,
       width = 7, height = 10, dpi = 300)   # tall: 53 symptom rows

#-------------------------------------------------------------------
# 3. COMORBIDITY: OBSERVED vs EXPECTED
# For every pair of diagnoses: how many people have both, next to how
# many would have both by chance.
#-------------------------------------------------------------------
pair <- paste(comorbidity$disorder_1, "&", comorbidity$disorder_2)

# Long format: one row per pair per type (observed or expected)
comorbidity_long <- rbind(
  data.frame(pair = pair, type = "observed", n = comorbidity$observed),
  data.frame(pair = pair, type = "expected by chance", n = comorbidity$expected)
)
comorbidity_long$pair <- factor(comorbidity_long$pair, levels = rev(pair))

comorbidity_plot <- ggplot(comorbidity_long, aes(x = pair, y = n, fill = type)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c("observed" = "#b2182b",
                               "expected by chance" = "grey70")) +
  labs(title = "Comorbidity: observed vs expected by chance",
       x = NULL, y = "Number of participants with both diagnoses",
       fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(comorbidity_plot)
ggsave("output/figures/comorbidity.png", comorbidity_plot,
       width = 7, height = 5, dpi = 300)

#-------------------------------------------------------------------
# 4. SYMPTOM COUNT vs DIAGNOSIS (STEP PLOT)
# Proportion diagnosed at each symptom count, one panel per disorder.
# The dashed line is the cutoff from default_thresholds.
#-------------------------------------------------------------------
cutoffs <- data.frame(
  disorder = c("bipolar", "depression", "anxiety", "schizophrenia"),
  cutoff   = c(default_thresholds$bipolar, default_thresholds$depression,
               default_thresholds$anxiety, default_thresholds$scz_total)
)

steps_plot <- ggplot(count_steps, aes(x = n_symptoms, y = prop_diagnosed)) +
  # direction = "mid" puts the jump halfway between two counts
  geom_step(direction = "mid", colour = "grey40") +
  # Point size = number of people at that count, so readers can see
  # which proportions are based on only a few people
  geom_point(aes(size = n_people), colour = "#b2182b") +
  # The jump should happen just left of the cutoff, so - 0.5
  geom_vline(data = cutoffs, aes(xintercept = cutoff - 0.5),
             linetype = "dashed") +
  facet_wrap(~ disorder, scales = "free_x") +
  scale_x_continuous(breaks = 0:9) +
  scale_y_continuous(limits = c(0, 1)) +
  scale_size(range = c(1, 4)) +   # smallest group still visible
  labs(title = "Proportion diagnosed by number of symptoms",
       subtitle = "Dashed line = cutoff in default_thresholds; point size = number of participants",
       x = "Number of symptoms present", y = "Proportion diagnosed",
       size = "# patients (n)") +
  theme_minimal()

print(steps_plot)
ggsave("output/figures/count_steps.png", steps_plot,
       width = 8, height = 6, dpi = 300)

