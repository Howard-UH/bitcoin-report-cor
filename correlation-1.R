#title: "Analysis of the correlation between Bitcoin and the US dollar index, VIX, gold,and US bond returns"
###1.
library(kableExtra)
library(tidyr)
library(quantmod)
library(dplyr)
library(PerformanceAnalytics)
library(ggplot2)
library(tibble)
library(lmtest)
library(zoo)
library(xts)
library(car) 
library(broom)

if ("dplyr" %in% loadedNamespaces()) conflictRules("dplyr", exclude = "lag")


### 2. 抓資料（2017 至今）
getSymbols(c("BTC-USD", "DX-Y.NYB", "^VIX", "GC=F", "^TNX"), 
           src = "yahoo", from = "2017-01-01", to = Sys.Date())

BTC <- Cl(get("BTC-USD"))
DXY <- Cl(get("DX-Y.NYB"))
VIX <- Cl(get("VIX"))
GOLD <- Cl(get("GC=F"))
US10Y <- Cl(get("TNX"))

prices <- merge(BTC, DXY, VIX, GOLD, US10Y)
colnames(prices) <- c("BTC", "DXY", "VIX", "GOLD", "US10Y")

prices <- na.omit(prices)

### 3. 轉為 data.frame 並加日期
df <- data.frame(date = index(prices), coredata(prices))

### 4. 計算對數報酬率
returns <- df %>%
  mutate(
    ret_BTC = c(NA, diff(log(BTC))),
    ret_DXY = c(NA, diff(log(DXY))),
    ret_VIX = c(NA, diff(log(VIX))),
    ret_GOLD = c(NA, diff(log(GOLD))),
    ret_US10Y = c(NA, diff(log(US10Y)))
  ) %>%
  na.omit()


###散佈圖+相關係數
ggplot(returns, aes(x = ret_DXY, y = ret_BTC)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  labs(title = paste("BTC vs DXY 報酬率散佈圖\n相關係數 =",
                     round(cor(returns$ret_BTC, returns$ret_DXY), 3)),
       x = "DXY 報酬率", y = "BTC 報酬率")


# 🔹 BTC vs VIX
ggplot(returns, aes(x = ret_VIX, y = ret_BTC)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  labs(title = paste("BTC vs VIX 報酬率散佈圖\n相關係數 =",
                     round(cor(returns$ret_BTC, returns$ret_VIX), 3)),
       x = "VIX 報酬率", y = "BTC 報酬率")

# 🔹 BTC vs GOLD
ggplot(returns, aes(x = ret_GOLD, y = ret_BTC)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  labs(title = paste("BTC vs GOLD 報酬率散佈圖\n相關係數 =",
                     round(cor(returns$ret_BTC, returns$ret_GOLD), 3)),
       x = "GOLD 報酬率", y = "BTC 報酬率")

# 🔹 BTC vs US10Y
ggplot(returns, aes(x = ret_US10Y, y = ret_BTC)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  labs(title = paste("BTC vs US10Y 報酬率散佈圖\n相關係數 =",
                     round(cor(returns$ret_BTC, returns$ret_US10Y), 3)),
       x = "US10Y 報酬率", y = "BTC 報酬率")



###Granger因果檢定
macro_vars <- c("ret_DXY", "ret_VIX", "ret_GOLD", "ret_US10Y")
summary_results <- data.frame()

for (var in macro_vars) {
  # 建立公式
  fwd_formula <- as.formula(paste("ret_BTC ~", var))
  rev_formula <- as.formula(paste(var, "~ ret_BTC"))
  
  # 雙向 Granger 檢定
  gr_fwd <- grangertest(fwd_formula, order = 3, data = returns)
  gr_rev <- grangertest(rev_formula, order = 3, data = returns)
  
  # 加入結果摘要表格
  summary_results <- bind_rows(
    summary_results,
    tibble(Variable = var,
           Direction = paste(var, "→ BTC"),
           p_value = gr_fwd$`Pr(>F)`[2],
           significant = ifelse(gr_fwd$`Pr(>F)`[2] < 0.05, "Yes", "No")),
    tibble(Variable = var,
           Direction = paste("BTC →", var),
           p_value = gr_rev$`Pr(>F)`[2],
           significant = ifelse(gr_rev$`Pr(>F)`[2] < 0.05, "Yes", "No"))
  )
  
  # 印出檢定結果
  cat("\n📊 Granger 因果檢定：", var, "與 BTC\n")
  cat("➡", var, "是否能預測 BTC？\n")
  print(gr_fwd)
  cat("⬅ BTC 是否能預測", var, "？\n")
  print(gr_rev)
}

#摘要
summary_results %>%
  kbl(caption = "Granger 因果檢定摘要：是否有統計上顯著的預測能力", digits = 4) %>%
  kable_styling(full_width = F, bootstrap_options = c("striped", "hover", "condensed"))




###多元線性回歸分析
model_multi <- lm(ret_BTC ~ ret_DXY + ret_VIX + ret_GOLD + ret_US10Y, data = returns)
summary(model_multi)


# 🔍 共線性檢查：VIF（Variance Inflation Factor）
vif_result <- vif(model_multi)
print(vif_result)

# 🔍 殘差分析：殘差圖、常態 Q-Q 圖、Durbin-Watson
# 1. 殘差 vs 拟合值
plot(model_multi$fitted.values, resid(model_multi),
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

# 2. Q-Q plot
qqnorm(resid(model_multi), main = "Normal Q-Q Plot of Residuals")
qqline(resid(model_multi), col = "blue")

# 3. Durbin-Watson 自相關檢定
dwtest(model_multi)



###時序圖
# 建立長格式資料
ret_long <- returns %>%
  select(date, ret_BTC, ret_DXY, ret_VIX, ret_GOLD, ret_US10Y) %>%
  pivot_longer(-date, names_to = "series", values_to = "return")

# 🔹 BTC vs DXY
ggplot(ret_long %>% filter(series %in% c("ret_BTC", "ret_DXY")), aes(x = date, y = return, color = series)) +
  geom_line() + labs(title = "BTC vs DXY 日報酬率走勢", y = "日報酬率")

# 🔹 BTC vs VIX
ggplot(ret_long %>% filter(series %in% c("ret_BTC", "ret_VIX")), aes(x = date, y = return, color = series)) +
  geom_line() + labs(title = "BTC vs VIX 日報酬率走勢", y = "日報酬率")

# 🔹 BTC vs GOLD
ggplot(ret_long %>% filter(series %in% c("ret_BTC", "ret_GOLD")), aes(x = date, y = return, color = series)) +
  geom_line() + labs(title = "BTC vs GOLD 日報酬率走勢", y = "日報酬率")

# 🔹 BTC vs US10Y
ggplot(ret_long %>% filter(series %in% c("ret_BTC", "ret_US10Y")), aes(x = date, y = return, color = series)) +
  geom_line() + labs(title = "BTC vs US10Y 日報酬率走勢", y = "日報酬率")


