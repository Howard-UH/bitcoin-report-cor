# Usage Guide

## Prerequisites
- R (>= 4.0 recommended)
- Internet access (to download Yahoo Finance data and to load CDN assets in `report.html`)
- R packages:

  ```r
  install.packages(c(
    "quantmod", "dplyr", "tidyr", "ggplot2", "PerformanceAnalytics",
    "lmtest", "car", "xts", "zoo", "tibble", "broom", "kableExtra"
  ))
  ```

## Run the Analysis
- Interactive R session:

  ```r
  source("correlation-1.R")
  ```

- Non-interactive (CLI):

  ```bash
  Rscript correlation-1.R
  ```

This will:
- Fetch daily prices for BTC, DXY, VIX, GOLD, and US10Y from Yahoo Finance (2017-01-01 to today)
- Compute daily log returns and generate plots (if an interactive device is available)
- Run Granger causality tests and a multivariate regression with diagnostics

### Saving Figures
The script displays figures but does not save them by default. To save, wrap plots and call `ggsave`:

```r
p <- ggplot(returns, aes(x = ret_VIX, y = ret_BTC)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red")

ggsave("BTCVIX_SC.png", plot = p, width = 7, height = 5, dpi = 150)
```

## View the Interactive Report
- Open `report.html` in a modern browser.
- Note: It loads Tailwind CSS and Chart.js from CDNs. If offline, download those files and update the `<script>`/`<link>` tags to local paths.

## Customization Recipes
- **Change sample window**: Edit `from`/`to` in `getSymbols(...)`.
- **Add/remove assets**: Adjust the ticker list, extend the merged `prices`, add corresponding `ret_*` columns, and update `macro_vars`.
- **Export tables**: Use `kableExtra::kbl(summary_results)` and `save_kable()` for HTML/PNG export if desired.
- **Extract model stats**: `broom::tidy(model_multi)` and `broom::glance(model_multi)`.

## Reproduce the Report Figures
If you want the static PNGs in the README to reflect your latest run, regenerate them with `ggsave` and overwrite the existing files:

```r
# Example for BTC vs DXY
p <- ggplot(returns, aes(x = ret_DXY, y = ret_BTC)) +
  geom_point(alpha = 0.5) + geom_smooth(method = "lm", color = "red")
ggsave("BTCDXY_SC.png", plot = p, width = 7, height = 5, dpi = 150)
```

## Troubleshooting
- "could not resolve host: query1.finance.yahoo.com": retry later or switch source; network issues can affect `getSymbols`.
- `package ‘xyz’ is not available`: ensure CRAN mirror is set and R version meets requirements.
- Empty plots: Check for `NA` values; ensure `returns <- ... %>% na.omit()` ran.