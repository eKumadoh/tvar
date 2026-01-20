# Threshold VAR and Monetary Policy Analysis in Sub-Saharan Africa

## Overview

This repository contains R code for analyzing **inflation dynamics, monetary policy behavior, and external shock transmission** in Sub-Saharan Africa using **panel data and nonlinear time-series models**.

The project integrates:
- Threshold Vector Autoregression (TVAR)
- Panel Taylor rule estimation
- Inflation pass-through analysis

The analysis focuses on **regime-dependent dynamics** driven by inflation thresholds and evaluates how **oil price shocks**, **exchange rate movements**, and **policy rates** interact across different inflation regimes.

📌 **This repository contains code only. Empirical results, tables, and interpretations are intentionally excluded**, as the associated manuscript is currently under preparation.

---

## Data Description

- Unbalanced panel of Sub-Saharan African countries
- Annual macroeconomic data
- Countries include (but are not limited to):
  - Ghana, Nigeria, Kenya, South Africa, Senegal, Tanzania, Uganda, Zambia, Zimbabwe, among others
- Key variables:
  - Inflation (CPI)
  - Lending interest rate
  - Brent crude oil price
  - Exchange rate (log)
  - GDP growth
  - GDP deflator
  - Election dummy (political cycle indicator)

⚠️ Raw data are **not redistributed**. Users must supply compatible datasets.

---

## Data Processing

The code implements:
- Kalman smoothing for missing values (`imputeTS`)
- Winsorization to control outliers
- First differencing for pass-through analysis
- Panel indexing using `plm::pdata.frame`

---

## Methodology

### 1. Threshold Vector Autoregression (TVAR)

A TVAR model is estimated to capture **nonlinear inflation dynamics**:

- Two inflation regimes (low vs high inflation)
- Threshold variable: inflation (CPI)
- Threshold set at the sample median
- Lag order: 2
- Impulse Response Functions (IRFs):
  - Regime-specific
  - Bootstrapped confidence intervals
  - Oil price (Brent crude) shocks as impulse
  - Inflation and lending rate as responses

This allows for **state-dependent monetary transmission**.

---

### 2. Taylor Rule Estimation

A panel Taylor rule is estimated using fixed effects:

\[
i_{it} = \alpha_i + \beta_1 \pi_{it} + \beta_2 y_{it} + \beta_3 e_{it} + \beta_4 oil_t + \beta_5 election_{it} + \varepsilon_{it}
\]

- Estimation via `plm`
- Country fixed effects
- Robust standard errors clustered at the country level
- Coefficient uncertainty visualized using confidence interval plots

---

### 3. Inflation Pass-Through Analysis

Short-run inflation pass-through is analyzed using a differenced panel model:

- Changes in CPI regressed on:
  - Changes in oil prices
  - Changes in exchange rates
  - Changes in lending rates
  - Political cycle dummy
- Robust inference with clustered standard errors

This captures **cost-push and exchange-rate transmission mechanisms**.

---

## Visualization

The repository includes code to generate:
- Regime-specific impulse response plots
- Taylor rule coefficient plots with confidence intervals
- Inflation, GDP growth, oil price, and exchange rate time trends

---

## Software and Packages

Key R packages used:
- `tsDyn`
- `plm`
- `fixest`
- `lmtest`
- `imputeTS`
- `tidyverse`
- `robustHD`

---

## Reproducibility

- All analytical steps are scripted
- Deterministic results given the data
- Modular code structure
- Suitable for extension to alternative thresholds or regions

---

