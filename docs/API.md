# API and Components Reference

This project comprises a single R analysis script (`correlation-1.R`) and a static interactive report (`report.html`). While there are no exported libraries, the script and client-side components expose a clear set of entry points and configurable parameters that act as the "public API" for users extending or reusing the work.

## R Analysis Script (`correlation-1.R`)

- **Purpose**: Fetch market data, compute returns, visualize relationships, run Granger causality tests, and fit a multivariate regression with diagnostics.
- **Key Dependencies**: `quantmod`, `dplyr`, `tidyr`, `ggplot2`, `PerformanceAnalytics`, `lmtest`, `car`, `xts`, `zoo`, `tibble`, `broom`, `kableExtra`.

### Entry Points and Parameters
- **Data source and date range**
  - Functionality: `quantmod::getSymbols` with Yahoo Finance tickers.
  - Default: from `2017-01-01` to `Sys.Date()`.
  - Edit within the script:

    ```r
    getSymbols(c("BTC-USD", "DX-Y.NYB", "^VIX", "GC=F", "^TNX"),
               src = "yahoo", from = "2017-01-01", to = Sys.Date())
    ```

- **Assets included**
  - Controlled via the ticker vector above. Mapping to variables occurs via `Cl(get(...))` and the merged `prices` object with column names: `BTC`, `DXY`, `VIX`, `GOLD`, `US10Y`.

- **Return construction**
  - Daily log returns are created in the `returns` data frame as columns: `ret_BTC`, `ret_DXY`, `ret_VIX`, `ret_GOLD`, `ret_US10Y`.

- **Granger causality**
  - Macro variables loop: `macro_vars <- c("ret_DXY", "ret_VIX", "ret_GOLD", "ret_US10Y")`.
  - Test order: `order = 3` in `lmtest::grangertest`.
  - Output summary stored in `summary_results` (tibble with `Variable`, `Direction`, `p_value`, `significant`).

- **Regression and diagnostics**
  - Model object: `model_multi <- lm(ret_BTC ~ ret_DXY + ret_VIX + ret_GOLD + ret_US10Y, data = returns)`.
  - Multicollinearity: `vif_result <- car::vif(model_multi)`.
  - Residual checks: residual plot, Q-Q plot, and Durbin-Watson via `lmtest::dwtest(model_multi)`.

### Script Outputs and Artifacts
- In-memory objects useful for downstream use:
  - `returns`: data frame of aligned daily log returns with `date`.
  - `summary_results`: tibble of Granger causality results.
  - `model_multi`: fitted `lm` model.
  - `vif_result`: named numeric vector of VIFs.
- Visualizations (displayed when run interactively): scatter plots and time series plots per pair; diagnostic plots.

### Common Extensions (Examples)
- **Change the date range**

  ```r
  getSymbols(..., from = "2019-01-01", to = as.Date("2024-12-31"))
  ```

- **Add an asset (e.g., S&P 500 proxy `^GSPC`)**

  ```r
  getSymbols(c("BTC-USD", "DX-Y.NYB", "^VIX", "GC=F", "^TNX", "^GSPC"), src = "yahoo", from = ..., to = ...)
  SPX <- Cl(get("GSPC"))
  prices <- merge(BTC, DXY, VIX, GOLD, US10Y, SPX)
  colnames(prices) <- c("BTC", "DXY", "VIX", "GOLD", "US10Y", "SPX")

  returns <- df %>% mutate(
    # ... existing columns ...,
    ret_SPX = c(NA, diff(log(SPX)))
  ) %>% na.omit()

  macro_vars <- c("ret_DXY", "ret_VIX", "ret_GOLD", "ret_US10Y", "ret_SPX")
  ```

- **Export a plot to file**

  ```r
  p <- ggplot(returns, aes(x = ret_VIX, y = ret_BTC)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", color = "red")
  ggsave("BTCVIX_SC.png", plot = p, width = 7, height = 5, dpi = 150)
  ```

- **Extract tidy regression results**

  ```r
  broom::tidy(model_multi)  # coefficients table
  broom::glance(model_multi)  # model-level statistics
  ```

## Interactive Report (`report.html`)

- **Purpose**: Present core findings with tabs and a Chart.js scatter plot (BTC vs VIX), plus textual cards and diagnostics.
- **Key Dependencies**: Tailwind CSS (CDN), Chart.js (CDN). Internet is required to load these assets from CDNs.

### Components and Hooks
- **Tabs**
  - Markup uses buttons with class `tab-button` and content containers with class `tab-content`.
  - The active tab receives class `tab-active`; inactive contents have class `hidden`.
  - Behavior is initialized on `DOMContentLoaded` by attaching click listeners to buttons and toggling classes.

  Minimal pattern:

  ```html
  <nav>
    <button class="tab-button tab-active" data-tab="tabA">Tab A</button>
    <button class="tab-button" data-tab="tabB">Tab B</button>
  </nav>
  <div id="tabA" class="tab-content">...</div>
  <div id="tabB" class="tab-content hidden">...</div>
  ```

- **Scatter chart (BTC vs VIX)**
  - Function: `createScatterChart()` creates a Chart.js scatter chart and mounts it on `<canvas id="btcVixScatterChart">`.
  - Default data: simulated to match a target correlation (`-0.228`).

### Customization Examples
- **Use real data instead of simulated**

  ```html
  <script>
  // Example arrays from your backend or precomputed JSON
  const vixReturns = [-0.01, 0.005, ...];
  const btcReturns = [0.02, -0.015, ...];

  function createScatterChartFromArrays(xVals, yVals) {
    const ctx = document.getElementById('btcVixScatterChart').getContext('2d');
    const data = xVals.map((x, i) => ({ x, y: yVals[i] }));
    new Chart(ctx, {
      type: 'scatter',
      data: { datasets: [{ label: 'BTC vs VIX 日報酬率', data }] },
      options: { responsive: true, maintainAspectRatio: false }
    });
  }

  document.addEventListener('DOMContentLoaded', () => {
    createScatterChartFromArrays(vixReturns, btcReturns);
  });
  </script>
  ```

- **Add a new tab with a second chart**

  ```html
  <!-- Button -->
  <button class="tab-button" data-tab="finding4">發現四：新結果</button>

  <!-- Content -->
  <div id="finding4" class="tab-content hidden">
    <canvas id="newChart"></canvas>
  </div>

  <script>
  document.addEventListener('DOMContentLoaded', function() {
    const ctx = document.getElementById('newChart').getContext('2d');
    new Chart(ctx, { type: 'line', data: { labels: [...], datasets: [...] } });
  });
  </script>
  ```

### Notes
- To self-host assets without CDNs, download Tailwind CSS and Chart.js and reference them locally.
- Keep class names (`tab-button`, `tab-content`, `tab-active`) consistent to benefit from the existing JS behavior.