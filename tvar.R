library(tidyverse)
library(readxl)
library(imputeTS)
library(tsDyn)
library(plm)
library(fixest)
library(lmtest)

ss_africa <- c("Benin", "Burkina Faso", "Cabo Verde",
               "Cote d'Ivoire", "Gambia", "Ghana", 
               "Guinea", "Guinea-Bissau", "Liberia",
               "Mali", "Niger", "Nigeria", "Senegal",
               "Sierra Leone", "Togo", "Burundi",
               "Comoros", "Djibouti", "Eritrea", 
               "Ethiopia", "Kenya", "Madagascar",
               "Malawi", "Mauritius", "Mozambique",
               "Rwanda", "Seychelles", "Somalia",
               "South Sudan", "Tanzania", "Uganda",
               "Zambia", "Zimbabwe", "Botswana",
               "Eswatini", "Lesotho",
               "Namibia", "South Africa")


#Readind data
inflation <- read_xls("INFLATION ENERGY.xls") |> 
  filter(complete.cases(year),
         year != 2024,
         !country %in% c("Eritrea","Somalia",
                         "Sudan")) |> 
  select(-REER, -REER_filled, -cpi, -TimeCode) |> 
  mutate(election_dummy = factor(election_dummy)) |> 
  group_by(country) |> 
  mutate(across(where(is.numeric), 
                ~ifelse(is.na(.x),na_kalman(.x),
                        .x)),
         across(where(is.numeric), 
                ~robustHD::winsorize(.x)),
         d_cpi = c(NA, diff(cpi_filled)),
         d_brent_crude = c(NA, diff(brent_crude)),
         d_ln_exchrate = c(NA, diff(ln_exchrate)),
         d_gdp_deflator_filled = 
           c(NA, diff(gdp_deflator_filled)),
         d_lending_rate = 
           c(NA, diff(lending_rate_filled))) |> 
  ungroup() 

#Converting to panel data
inflation <- pdata.frame(inflation,
                         index = c("country",
                                   "year"),
                         row.names = T)

#TVAR
tvar_mod <- TVAR(inflation |> 
                   select(cpi_filled,
                          lending_rate_filled,
                          brent_crude,
                          gdp_growth_filled,
                          ln_exchrate),
                 lag=2, 
                 nthresh=1, 
                 thDelay=1, 
                 trim=0.1,
                 mTh=1,
                 gamma = inflation |> 
                   pull(cpi_filled) |> median(),
                 plot=F)

irf_lower <- irf(tvar_mod,
                 n.ahead = 10,         
                 ortho = TRUE,         
                 runs = 100,           
                 ci = 0.95,            
                 boot = TRUE,          
                 cumulative = FALSE,   
                 regime = "L",
                 impulse = "brent_crude",
                 response = c("cpi_filled",
                              "lending_rate_filled"))
plot(irf_lower)

irf_high <- irf(tvar_mod,
                n.ahead = 10,         
                ortho = TRUE,         
                runs = 100,           
                ci = 0.95,            
                boot = TRUE,          
                cumulative = FALSE,   
                regime = "H",
                impulse = "brent_crude",
                response = c("cpi_filled",
                             "lending_rate_filled"))
plot(irf_high)

#Taylor rule estimation
taylor_mod <- plm(
  lending_rate_filled ~ gdp_deflator_filled +
    ln_exchrate + brent_crude + gdp_growth +
    election_dummy,
  data = inflation, model = "within")

taylor_mod_se <- coeftest(taylor_mod, 
                          vcov = vcovHC(taylor_mod, 
                                        type = "HC1",
                                        cluster = "group"))

taylor_coefs <- coef(taylor_mod_se)
df_coef_taylor <- data.frame(
  term = rownames(taylor_mod_se),
  estimate = taylor_mod_se[, "Estimate"],
  std.error = taylor_mod_se[, "Std. Error"]
)

df_coef_taylor <- df_coef_taylor %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

df_coef_taylor$term <- recode(df_coef_taylor$term,
                              "gdp_deflator_filled" = "Inflation",
                              "gdp_growth" = "GDP Growth",
                              "ln_exchrate" = "Log Exchange Rate",
                              "election_dummy1" = "Election(yes)",
                              "brent_crude" = "Brent Price"
)

ggplot(df_coef_taylor,
       aes(x = estimate, y = term)) +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  labs(title = "Taylor Rule Coefficient Plot",
       x = "Coefficient Estimate", y = "") +
  theme_minimal()

#Inflation pass through analysis
pass_through <- plm(d_cpi ~
                      d_brent_crude + d_ln_exchrate +
                      d_lending_rate +
                      election_dummy,
                    data = inflation)
summary(pass_through)

pass_through_se <- coeftest(pass_through, 
                            vcov = vcovHC(pass_through, 
                                          type = "HC1",
                                          cluster = "group"))

pass_coefs <- coef(pass_through_se)

df_coef_pass <- data.frame(
  term = rownames(pass_through_se),
  estimate = pass_through_se[, "Estimate"],
  std.error = pass_through_se[, "Std. Error"]
)

df_coef_pass <- df_coef_pass %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

df_coef_pass$term <- recode(
  df_coef_pass$term,
  "d_brent_crude" = "Differenced Brent Price",
  "d_ln_exchrate" = "Differenced Log Exchange Rate",
  "d_lending_rate" = "Differenced Lending Rate",
  "election_dummy1" = "Election(yes)"
)

ggplot(df_coef_pass,
       aes(x = estimate, y = term)) +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  labs(title = "Taylor Rule Coefficient Plot",
       x = "Coefficient Estimate", y = "") +
  theme_minimal()

inflation |> 
  group_by(year) |> 
  summarise(cpi_filled = median(cpi_filled, na.rm = T)) |> 
  ungroup() |> 
  mutate(year = 1989 + as.numeric(year)) |> 
  ggplot(aes(year, cpi_filled)) +
  geom_line() +
  theme_bw() +
  labs(x = "Year", y = "Inflation")

inflation |> 
  group_by(year) |> 
  summarise(gdp_growth_filled = median(gdp_growth_filled, na.rm = T)) |> 
  ungroup() |> 
  mutate(year = 1989 + as.numeric(year)) |> 
  ggplot(aes(year, gdp_growth_filled)) +
  geom_line() +
  theme_bw() +
  labs(x = "Year", y = "GDP Growth")

inflation |> 
  group_by(year) |> 
  summarise(brent_crude = median(brent_crude, na.rm = T)) |> 
  ungroup() |> 
  mutate(year = 1989 + as.numeric(year)) |> 
  ggplot(aes(year, brent_crude)) +
  geom_line() +
  theme_bw() +
  labs(x = "Year", y = "Brent Price")

inflation |> 
  group_by(year) |> 
  summarise(ln_exchrate = median(ln_exchrate, na.rm = T)) |> 
  ungroup() |> 
  mutate(year = 1989 + as.numeric(year)) |> 
  ggplot(aes(year, ln_exchrate)) +
  geom_line() +
  theme_bw() +
  labs(x = "Year", y = "Log(Exchange Rate)")

