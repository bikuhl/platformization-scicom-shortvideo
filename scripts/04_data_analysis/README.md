# Data Analysis

This folder contains the R script for statistical analysis and reproduction of results, tables, and figures reported in the paper.

## Requirements

### R Version

- R >= 4.0.0

### Required Packages

Install all required packages using:

```r
install.packages(c(
  "tidyverse",
  "lubridate",
  "showtext",
  "emmeans"
))
```

## Data

The analysis requires the final dataset located at:

`../../data/platformization_dataset.csv`

Variables are documented in `../../CODEBOOK.md`.

## What the Script Does

The analysis script performs the following operations:

1. Data Loading & Preparation
2. Sample Description
3. Platformization Indicators Analysis
4. Affordance Alignment Index and Temporal Analysis
5. Engagement Analysis (correlations and regression models)
6. Tables (written as CSV files to `output/tables/`)
7. Figures (written as PDF files to `output/figures/`)

## Usage

Open a fresh R session, set the working directory to this folder, and run:

```r
source("01_data_analysis.R")
```
