# PIPS Group Project

## Psychiatric Symptom Patterns and Diagnostic Classification

This repository contains a group project developed for the *Programming in Psychological Science* course at the University of Amsterdam.

The project explores relationships between psychiatric symptoms and diagnostic classifications using a synthetic mental health dataset. It combines data processing, diagnostic rule verification, statistical analyses, visualisations, and an interactive Shiny application.

**The project is intended for educational purposes and does not provide clinical diagnoses.**

## Project objectives

The project addresses three main questions:

1. How are individual psychiatric symptoms associated with their corresponding diagnoses and with other diagnoses?
2. To what extent do different psychiatric diagnoses co-occur in the dataset?
3. How do symptom counts and predefined diagnostic thresholds influence classification outcomes?

The interactive component additionally aims to demonstrate how changes to symptom profiles can influence diagnostic classifications.

## Dataset

The project uses `Mentalillness.csv`, a synthetic mental health dataset obtained from Kaggle.

The original dataset contains 3,753 participant records and 58 binary symptom, criterion, and diagnostic variables covering five psychiatric disorders:

- Bipolar disorder
- Schizophrenia
- Depression
- Anxiety disorder
- Post-traumatic stress disorder (PTSD)

Variables are coded as 0 (absent) or 1 (present).

A variable key maps the original column names to shorter, standardised names and identifies their associated disorders and criteria.

**Important:** The data are synthetically generated, and diagnostic outcomes follow predefined classification rules. Results should not be interpreted as representative of real clinical populations.

## Project components

### 1. Data preparation and validation

The project loads the dataset, standardises variable names, checks binary values, and constructs a variable key.

### 2. Diagnostic rule verification

The five diagnostic indicators are reconstructed using predefined DSM-style classification rules.

The implementation includes checks of agreement with the original diagnosis variables and tests of selected threshold conditions.

### 3. Statistical analyses

The project includes:

- Chi-square tests of symptom–diagnosis associations
- Phi coefficients as measures of association
- False discovery rate correction for multiple testing
- Comparisons of observed and expected diagnostic co-occurrence
- Visualisations of symptom counts and diagnostic thresholds

### 4. Data visualisations

Three principal figures are generated:

- A symptom–diagnosis association heatmap
- An observed-versus-expected comorbidity plot
- A symptom-count and diagnostic-classification plot

Figures and result tables are saved in the `output/` directory.

### 5. Interactive Shiny application

The Shiny application allows users to select a dataset row and explore its recorded symptom profile and diagnostic indicators.

Symptoms are grouped by disorder and classification criterion, alongside a reference section for diagnostic criteria.

**Current development status:** The initial prototype displays symptom profiles and diagnostic labels. Interactive symptom modifications are not yet connected to recalculation of the diagnoses. This functionality is planned for a later update.

## Repository structure

```text
PIPS-group-project/
├── data/
│   ├── Mentalillness.csv
│   └── variable_key.csv
├── src/
│   └── r/
│       ├── functions_data.R
│       ├── functions_variable_key.R
│       ├── functions_dsm_rules.R
│       ├── functions_analysis.R
│       ├── analyses.R
│       ├── plots.R
│       └── test_dsm_rules.R
├── tests/
│   └── test_functions.R
├── output/
│   ├── figures/
│   └── tables/
├── main.Rmd
├── Shiny_Sim.Rmd
├── README.md
└── PIPS-group-project.Rproj
```


## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/misia187/PIPS-group-project.git
```

Alternatively, download the ZIP file from GitHub.

### 2. Open the project

Open `PIPS-group-project.Rproj` in RStudio.

Keep the project directory structure intact because the scripts use relative file paths.

### 3. Install dependencies

The project requires R and the following packages:

- `dplyr` — Data manipulation
- `ggplot2` — Data visualisation
- `shiny` — Interactive Shiny application
- `rmarkdown` — HTML report generation
- `knitr` — R Markdown code execution and tables

Install them in RStudio by running:

```r
install.packages(c("dplyr", "ggplot2", "shiny", "rmarkdown", "knitr"))
```

The `stats`, `tools`, and `utils` packages are included with R and do not require separate installation.

## Running the statistical report

1. Open `main.Rmd` in RStudio.
2. Click **Knit** to render the document.
3. Review the generated HTML report.

The document includes dataset information, diagnostic rule verification, statistical results, and visualisations.

## Running the Shiny application

Open PIPS-group-project.Rproj in RStudio.

Install the required packages if they are not already available.

Open Shiny_Sim.Rmd.

Execute the setup and application code in RStudio to initialise the dataset and construct the Shiny application.

Launch the returned Shiny application using RStudio.

The application allows users to select a dataset row and inspect its symptom profile, original diagnostic classifications, and associated DSM-style criteria.

***Current prototype limitation:*** Symptom checkboxes can be toggled, but the displayed diagnoses do not yet recalculate in response to these changes. This functionality is planned for a subsequent update.

The application is intended for educational exploration of synthetic data and should not be used for clinical diagnosis.
## Running the tests

Preliminary project and data checks can be run from the project directory:

```r
source("tests/test_functions.R")
```

The project also contains DSM-rule verification code in:

`src/r/test_dsm_rules.R`

Additional independent function tests are being developed.

## Methodological limitations

The dataset is synthetic, and the diagnostic indicators are determined by predefined rules. Consequently:

- Symptom–diagnosis associations may partly reflect the classification rules used to generate the diagnoses.
- The observed patterns do not establish diagnostic validity in real clinical populations.
- A nonsignificant statistical test does not demonstrate the absence of a relationship.
- The simplified classification rules should not be considered substitutes for comprehensive DSM-5 clinical assessment.

## Data source and citation

The dataset was obtained from Kaggle. The complete dataset title, original creator, URL, and retrieval details will be added after source verification.

To reference this project, include the repository name, contributors, year, and URL:

https://github.com/misia187/PIPS-group-project

## Development status

This project is under active development. The statistical analysis and diagnostic verification components have been implemented. The Shiny prototype is being extended, and documentation, integration, and independent testing are ongoing.
