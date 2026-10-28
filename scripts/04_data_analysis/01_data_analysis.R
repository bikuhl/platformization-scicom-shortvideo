#' Platformization of science communication in short videos
#' Analysis script: reproduces the statistics, tables, and figures of the paper
#' Input: platformization_dataset.csv (see CODEBOOK.md). Run in a fresh R session.

library(tidyverse)
library(lubridate)
library(showtext)
library(emmeans)

# ============================================================
# 0. SETTINGS
# ============================================================
data_path <- "../../data/platformization_dataset.csv"   # relative to this script
out_tab   <- "output/tables"
out_fig   <- "output/figures"
dir.create(out_tab, recursive = TRUE, showWarnings = FALSE)
dir.create(out_fig, recursive = TRUE, showWarnings = FALSE)

fig_w <- 6.3                                  # text width in inches
plat_levels <- c("TikTok", "Shorts")
plat_fill   <- c("TikTok" = "grey30", "Shorts" = "grey80")
plat_text   <- c("TikTok" = "white",  "Shorts" = "black")

# Font for figures (falls back to the default sans font without internet access)
fig_family <- "sans"
if (tryCatch({ font_add_google("Noto Sans", "fig_font"); TRUE }, error = function(e) FALSE)) {
  fig_family <- "fig_font"
}
showtext_auto(); showtext_opts(dpi = 300)
lbl <- 6 / .pt

# ============================================================
# 1. LOAD DATA
# ============================================================
df <- read_csv(data_path, na = c("", "NA"), show_col_types = FALSE) %>%
  mutate(Platform         = factor(Platform, levels = plat_levels),   # reference: TikTok
         Account_category = factor(Account_category),
         Upload_date      = as.Date(Upload_date),
         year_month       = floor_date(Upload_date, "month"),
         days_since_start = as.numeric(Upload_date - min(Upload_date)))
stopifnot(nrow(df) == 1055)

# Optional pseudonymous account ID (needed for communicator counts, not in the default dataset)
has_id <- "Account_id" %in% names(df)
if (!has_id) message("No Account_id in dataset: communicator counts and the 'unique accounts' panel are skipped.")

ord_idx <- c("Professional academics", "Content creators", "Media/news publishers",
             "Commercial companies", "Students", "Academic institutions",
             "Political/public actors/institutions")
ord_eng <- c("Content creators", "Professional academics", "Students", "Media/news publishers",
             "Political/public actors/institutions", "Commercial companies", "Academic institutions")

ind <- tribble(
  ~aff,                   ~label,                      ~var,
  "Algorithmic curation", "Hashtags (presence)",       "plat_hashtag",
  "",                     "Platform-specific hashtag", "plat_platform_hashtag",
  "Hypertextuality",      "Links (absence)",           "plat_no_link",
  "Interactivity",        "Call-to-participation",     "plat_ctp",
  "",                     "Account referencing",       "plat_mention",
  "Multimodality",        "In-app production",         "plat_in_app",
  "",                     "Vertical format",           "plat_vertical",
  "",                     "Visual effects",            "plat_effect",
  "",                     "Music/ambient sound",       "plat_music",
  "",                     "On-screen text",            "plat_text")

# Formatting helpers
fmt_int <- function(x) formatC(round(x), format = "d", big.mark = ",")
fmt_d   <- function(x, d) formatC(x, format = "f", digits = d, big.mark = ",")
stars   <- function(p) ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "")))
fmt_p   <- function(p) ifelse(p < .001, "<.001", sub("^0", "", sprintf("%.3f", p)))
fmt_r   <- function(r) { s <- sprintf("%.2f", r); ifelse(s == "-0.00", "0.00", s) }
pct0    <- function(x) sprintf("%.0f", 100 * mean(x))
pct1    <- function(x) sprintf("%.1f", 100 * mean(x))
share   <- function(x) round(100 * mean(x), 1)

# ============================================================
# 2. SAMPLE DESCRIPTION
# ============================================================
cat("\n=== Sample ===\n")
print(table(df$Platform))
print(count(df, Period))
print(df %>% count(Period, Platform) %>% group_by(Period) %>% mutate(pct = round(100 * n / sum(n), 1)))

cat("\n=== Disciplines ===\n")
print(df %>% count(Discipline, sort = TRUE) %>% mutate(pct = round(100 * n / sum(n), 1)))

cat("\n=== Communicator types (all videos, by platform) ===\n")
print(df %>% count(Account_category, sort = TRUE) %>% mutate(pct = round(100 * n / sum(n), 1)))
print(df %>% count(Platform, Account_category) %>% group_by(Platform) %>%
        mutate(pct = round(100 * n / sum(n), 1)) %>% arrange(Platform, desc(n)), n = 30)

if (has_id) {
  cs <- df %>% filter(!is.na(Account_id)) %>% count(Platform, Account_id, name = "n_videos")
  cat("\n=== Videos per communicator ===\n")
  print(cs %>% group_by(Platform) %>%
          summarise(n_communicators = n(), M = mean(n_videos), SD = sd(n_videos),
                    min = min(n_videos), max = max(n_videos)))
  print(cs %>% summarise(n_communicators = n(), M = mean(n_videos), SD = sd(n_videos)))
}

cat("\n=== Engagement metrics ===\n")
print(df %>% summarise(across(c(Views, Likes, Comments),
        list(M = mean, SD = sd, min = min, max = max, median = median,
             p10 = ~quantile(.x, .10), p90 = ~quantile(.x, .90)))) %>%
        pivot_longer(everything(), names_to = c("metric", "stat"), names_sep = "_") %>%
        pivot_wider(names_from = stat, values_from = value))
for (v in c("Views", "Likes", "Comments")) {
  tt_v <- t.test(reformulate("Platform", v), data = df)   # Welch
  cat(sprintf("%s ~ Platform: t(%.2f) = %.2f, p = %s\n", v, tt_v$parameter, tt_v$statistic,
              format.pval(tt_v$p.value, digits = 3)))
}

# ============================================================
# 3. INDICATORS BY PLATFORM (descriptive details)
# ============================================================
by_plat <- function(var, label = var) {
  df %>% group_by(Platform) %>%
    summarise(n = n(), n_yes = sum(.data[[var]] == 1, na.rm = TRUE),
              pct = share(.data[[var]] == 1), .groups = "drop") %>% mutate(indicator = label)
}
cat("\n=== Hashtags ===\n")
print(by_plat("Has_hashtag")); print(by_plat("Has_platform_hashtag"))

cat("\n=== Links ===\n")
print(df %>% summarise(overall_pct_with_link = share(Has_link_anywhere == 1)))
print(df %>% group_by(Platform) %>%
        summarise(across(c(Has_link_anywhere, Link_in_title, Link_in_description, Link_in_transcript,
                           Link_in_text_in_video, Link_in_account_description,
                           Internal_link_anywhere, External_link_anywhere),
                         ~share(.x == 1))))
print(df %>% filter(Platform == "Shorts") %>% count(Cut) %>% mutate(pct = round(100 * n / sum(n), 1)))

cat("\n=== Interactivity ===\n")
print(df %>% group_by(Platform) %>%
        summarise(call_any = share(Call_to_participation > 0),
                  call_internal = share(Call_to_participation == 1),
                  call_external = share(Call_to_participation == 2),
                  mention = share(Has_mention == 1),
                  stitch_n = sum(Has_stitch), duet_n = sum(Has_duet), challenge_n = sum(Has_challenge),
                  stitch = share(Has_stitch == 1), duet = share(Has_duet == 1),
                  challenge = share(Has_challenge == 1)))

cat("\n=== In-app production ===\n")
print(df %>% group_by(Platform) %>%
        summarise(in_app_n = sum(Has_in_app), in_app_pct = share(Has_in_app == 1),
                  # shares among in-app produced videos
                  sound_of_in_app  = share(InApp_sound[Has_in_app == 1] == 1),
                  effect_of_in_app = share(InApp_effect[Has_in_app == 1] == 1),
                  cut_of_in_app    = share(Cut[Has_in_app == 1] %in% c("Cut", "Cut:Short"))))

cat("\n=== Format ===\n")
print(df %>% count(Format_type) %>% mutate(pct = round(100 * n / sum(n), 1)))
print(df %>% count(Platform, Format_type) %>% group_by(Platform) %>% mutate(pct = round(100 * n / sum(n), 1)))

cat("\n=== Visual effects ===\n")
print(df %>% group_by(Platform) %>%
        summarise(across(c(Has_any_effect, Effect_split_screens, Effect_green_screen, Effect_stickers,
                           Effect_emojis, Effect_GIFs, Effect_comment, Effect_other), ~share(.x == 1))))
cat("Overall any effect:", share(df$Has_any_effect == 1), "%\n")

cat("\n=== Audio ===\n")
print(df %>% count(Platform, Audio_composition) %>% group_by(Platform) %>%
        mutate(pct = round(100 * n / sum(n), 1)))
cat("\n=== On-screen text ===\n")
print(df %>% count(Platform, Text_type) %>% group_by(Platform) %>% mutate(pct = round(100 * n / sum(n), 1)))
print(df %>% count(Text_type) %>% mutate(pct = round(100 * n / sum(n), 1)))

# ============================================================
# 4. AFFORDANCE ALIGNMENT INDEX
# ============================================================
tt <- t.test(platformization_index ~ Platform, data = df)   # Welch
cat(sprintf("\nIndex: M = %.2f (SD = %.2f); TikTok vs Shorts: t(%.2f) = %.2f, p = %s\n",
            mean(df$platformization_index), sd(df$platformization_index),
            tt$parameter, tt$statistic, format.pval(tt$p.value, digits = 3)))

m_time <- lm(platformization_index ~ days_since_start * Platform, data = df)
cat("\n=== Index ~ time x platform ===\n"); print(summary(m_time))
slopes <- emtrends(m_time, ~ Platform, var = "days_since_start")
print(test(slopes))
print(as.data.frame(slopes) %>%
        mutate(per_year = days_since_start.trend * 365,
               lower_year = lower.CL * 365, upper_year = upper.CL * 365))

# ============================================================
# 5. ENGAGEMENT: CORRELATIONS AND MODELS
# ============================================================
cat("\n=== Correlations index x engagement ===\n")
for (v in c("Views", "Likes", "Comments")) {
  ct <- cor.test(df$platformization_index, df[[v]])
  cat(sprintf("%s: r = %.2f, p = %s, R2 = %.1f%%\n", v, ct$estimate,
              format.pval(ct$p.value, digits = 3), 100 * ct$estimate^2))
}

fit <- function(dv) list(
  m1 = lm(reformulate("platformization_index", dv), df),
  m2 = lm(reformulate(c("platformization_index", "Platform"), dv), df),
  m3 = lm(reformulate(c("platformization_index", "Platform", "Account_category"), dv), df),
  m4 = lm(reformulate(c("platformization_index", "Platform", "Account_category", "Upload_date"), dv), df))
fv <- fit("Views"); fl <- fit("Likes"); fc <- fit("Comments")

cat("\n=== Delta R2 (Views) ===\n")
print(round(c(M2 = summary(fv$m2)$r.squared - summary(fv$m1)$r.squared,
              M3 = summary(fv$m3)$r.squared - summary(fv$m2)$r.squared,
              M4 = summary(fv$m4)$r.squared - summary(fv$m3)$r.squared), 3))

# ============================================================
# 6. TABLES (formatted as in the paper, written to CSV)
# ============================================================
coef_cell <- function(m, term, d = 0) {
  s <- summary(m)$coefficients
  if (!term %in% rownames(s)) return("--")
  paste0(if (d == 0) fmt_int(s[term, 1]) else fmt_d(s[term, 1], d), stars(s[term, 4]))
}
comm_cell <- function(m) {
  d1 <- drop1(m, test = "F")
  if (!"Account_category" %in% rownames(d1)) return("--")
  paste0("Included", stars(d1["Account_category", "Pr(>F)"]))
}
f_cell <- function(m) {
  f <- summary(m)$fstatistic
  paste0(sprintf("%.2f", f[[1]]), stars(pf(f[[1]], f[[2]], f[[3]], lower.tail = FALSE)))
}
reg_col <- function(m, d_date = 1) c(
  coef_cell(m, "platformization_index"), coef_cell(m, "PlatformShorts"), comm_cell(m),
  coef_cell(m, "Upload_date", d_date),
  sprintf("%.3f", summary(m)$r.squared), sprintf("%.3f", summary(m)$adj.r.squared),
  f_cell(m), fmt_int(nobs(m)))
reg_labels <- c("Affordance alignment", "Platform", "Communicator", "Upload date",
                "R2", "Adj. R2", "F", "N")

by_comm <- function(vars, names_out) {
  df %>% filter(Account_category %in% ord_idx) %>%
    mutate(Account_category = as.character(Account_category)) %>%
    group_by(Account_category) %>%
    summarise(n = n(), across(all_of(vars), pct1), .groups = "drop") %>%
    slice(match(ord_idx, Account_category)) %>% mutate(n = as.character(n)) %>%
    rename(`Communicator type` = Account_category) %>%
    set_names(c("Communicator type", "n", names_out))
}

# Table: engagement by communicator type (thousands)
t_eng <- df %>% filter(Account_category %in% ord_eng) %>%
  mutate(Account_category = as.character(Account_category)) %>%
  group_by(Account_category) %>%
  summarise(n = n(), across(c(Views, Likes, Comments),
                            list(m = ~mean(.x) / 1000, s = ~sd(.x) / 1000)), .groups = "drop") %>%
  slice(match(ord_eng, Account_category)) %>%
  transmute(`Communicator type` = Account_category, n = as.character(n),
            Views    = paste0(fmt_d(Views_m, 1),    " (", fmt_d(Views_s, 1),    ")"),
            Likes    = paste0(fmt_d(Likes_m, 1),    " (", fmt_d(Likes_s, 1),    ")"),
            Comments = paste0(fmt_d(Comments_m, 1), " (", fmt_d(Comments_s, 1), ")"))

# Table: indicators by platform
idx_ms <- function(x) sprintf("%.1f (%.1f)", mean(x), sd(x))
t_aff <- pmap_dfr(ind, function(aff, label, var) {
  x <- df[[var]]; ct <- chisq.test(table(df$Platform, x))
  tibble(Affordance = aff, Indicator = label, Total = pct0(x),
         TikTok = pct0(x[df$Platform == "TikTok"]), Shorts = pct0(x[df$Platform == "Shorts"]),
         chi2 = sprintf("%.2f", ct$statistic), p = fmt_p(ct$p.value))
}) %>% add_row(Affordance = "Alignment index", Indicator = "M (SD)",
               Total = idx_ms(df$platformization_index),
               TikTok = idx_ms(df$platformization_index[df$Platform == "TikTok"]),
               Shorts = idx_ms(df$platformization_index[df$Platform == "Shorts"]),
               chi2 = "", p = fmt_p(tt$p.value))

# Table: index by communicator type
t_idx <- df %>% filter(Account_category %in% ord_idx) %>%
  mutate(Account_category = as.character(Account_category)) %>%
  group_by(Account_category) %>%
  summarise(n = n(), m = mean(platformization_index), s = sd(platformization_index), .groups = "drop") %>%
  slice(match(ord_idx, Account_category)) %>%
  transmute(`Communicator type` = Account_category, n = as.character(n),
            `M (SD)` = sprintf("%.1f (%.1f)", m, s))

t_c1 <- by_comm(c("plat_hashtag", "plat_platform_hashtag", "plat_no_link", "plat_ctp", "plat_mention"),
                c("Hashtags (presence)", "Platform-specific hashtag", "Links (absence)",
                  "Call-to-participation", "Account referencing"))
t_c2 <- by_comm(c("plat_in_app", "plat_vertical", "plat_effect", "plat_music", "plat_text"),
                c("In-app production", "Vertical format", "Visual effects",
                  "Music/ambient sound", "On-screen text"))

# Tables: regressions
t_reg <- tibble(Predictor = reg_labels,
                `Model 1` = reg_col(fv$m1), `Model 2` = reg_col(fv$m2),
                `Model 3` = reg_col(fv$m3), `Model 4` = reg_col(fv$m4))
t_reg_out <- tibble(Predictor = reg_labels, Views = reg_col(fv$m4, 1),
                    Likes = reg_col(fl$m4, 1), Comments = reg_col(fc$m4, 2))

# Table: individual indicators -> views
m_all <- lm(Views ~ plat_hashtag + plat_platform_hashtag + plat_no_link + plat_ctp + plat_mention +
              plat_in_app + plat_vertical + plat_effect + plat_music + plat_text +
              Platform + Account_category + Upload_date, data = df)
t_ind <- pmap_dfr(ind, function(aff, label, var) {
  m_alone <- lm(reformulate(var, "Views"), df)
  m_ctrl  <- lm(reformulate(c(var, "Platform", "Account_category", "Upload_date"), "Views"), df)
  tibble(Indicator = label, `r (bivariate)` = fmt_r(cor(df[[var]], df$Views)),
         `b (alone)` = coef_cell(m_alone, var), `b (controlled)` = coef_cell(m_ctrl, var),
         `b (all together)` = coef_cell(m_all, var))
})

tabs <- list(
  table_engagement_by_communicator.csv                         = t_eng,
  table_indicators_by_platform.csv                             = t_aff,
  table_index_by_communicator.csv                              = t_idx,
  table_communicator_algorithmic_hypertext_interactivity.csv   = t_c1,
  table_communicator_multimodality.csv                         = t_c2,
  table_regression_views_hierarchical.csv                      = t_reg,
  table_regression_engagement_outcomes.csv                     = t_reg_out,
  table_indicators_predicting_views.csv                        = t_ind)
iwalk(tabs, ~{ cat("\n===", .y, "===\n"); print(as.data.frame(.x)); write_csv(.x, file.path(out_tab, .y)) })

# ============================================================
# 7. FIGURES
# ============================================================
theme_ccr <- function(base_size = 9) {
  theme_minimal(base_size = base_size, base_family = fig_family) +
    theme(axis.title = element_text(size = base_size + 1),
          axis.text = element_text(size = base_size, colour = "black"),
          legend.position = "bottom", legend.title = element_text(size = base_size),
          legend.text = element_text(size = base_size), legend.margin = margin(t = -4),
          panel.grid.minor = element_blank(),
          strip.text = element_text(size = base_size + 1, face = "bold"))
}
save_fig <- function(p, name, h) ggsave(file.path(out_fig, name), p, width = fig_w, height = h, device = "pdf")

plat_labels <- function(data) {
  tab <- data %>% count(Platform)
  labs <- lapply(seq_len(nrow(tab)), function(i)
    bquote(.(as.character(tab$Platform[i])) ~ "(" * italic(n) ~ "=" ~ .(tab$n[i]) * ")"))
  names(labs) <- as.character(tab$Platform)
  unname(labs[plat_levels])
}

# ---- Figure 1: monthly uploads ----
min_inside <- 4
f1 <- df %>% count(year_month, Platform)
tot1 <- f1 %>% group_by(year_month) %>% summarise(total = sum(n), .groups = "drop")
small_top <- f1 %>% filter(Platform == "TikTok", n < min_inside) %>% left_join(tot1, by = "year_month")

fig1 <- ggplot(f1, aes(x = year_month, y = n, fill = Platform)) +
  geom_col(position = "stack", width = 28) +
  geom_text(data = ~ filter(.x, !(Platform == "TikTok" & n < min_inside)),
            aes(label = n, colour = Platform), position = position_stack(vjust = 0.5),
            size = lbl, family = fig_family, show.legend = FALSE) +
  geom_text(data = small_top, aes(x = year_month, y = total, label = n), inherit.aes = FALSE,
            vjust = -0.4, colour = "black", size = lbl, family = fig_family) +
  scale_fill_manual(values = plat_fill, labels = plat_labels(df)) +
  scale_colour_manual(values = plat_text, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(x = "Upload month", y = "Number of videos", fill = NULL) + theme_ccr()
save_fig(fig1, "figure1_uploads_over_time.pdf", 3)

# ---- Figure 2: disciplines ----
f2 <- df %>% filter(!is.na(Discipline)) %>% count(Discipline, Platform, name = "freq")
ord2 <- f2 %>% group_by(Discipline) %>% summarise(t = sum(freq)) %>% arrange(desc(t)) %>% pull(Discipline)
f2 <- f2 %>% mutate(Discipline = factor(Discipline, levels = rev(ord2)),
                    Platform = factor(Platform, levels = plat_levels))
tot2 <- f2 %>% group_by(Discipline) %>% summarise(total = sum(freq), .groups = "drop")
thr2 <- 0.05 * max(tot2$total)
small2 <- f2 %>% filter(freq < thr2) %>% arrange(Discipline, desc(Platform)) %>%   # Shorts first
  group_by(Discipline) %>% summarise(label = paste(freq, collapse = " / "), .groups = "drop") %>%
  left_join(tot2, by = "Discipline")

fig2 <- ggplot(f2, aes(x = freq, y = Discipline, fill = Platform)) +
  geom_col(position = "stack", width = 0.6) +
  geom_text(data = ~ filter(.x, freq >= thr2), aes(label = freq, colour = Platform),
            position = position_stack(vjust = 0.5), size = lbl, family = fig_family, show.legend = FALSE) +
  geom_text(data = small2, aes(x = total, y = Discipline, label = label), inherit.aes = FALSE,
            hjust = -0.2, colour = "black", size = lbl, family = fig_family) +
  scale_fill_manual(values = plat_fill, labels = plat_labels(df)) +
  scale_colour_manual(values = plat_text, guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_y_discrete(labels = function(x) str_wrap(x, width = 30)) +
  labs(x = "Number of videos", y = "Discipline", fill = NULL) + theme_ccr()
save_fig(fig2, "figure2_disciplines.pdf", 3.5)

# ---- Figure 3: communicator types (videos; unique accounts if Account_id exists) ----
fd <- df %>% filter(Account_category %in% ord_idx) %>%
  mutate(Account_category = as.character(Account_category))
cd <- fd %>% count(Account_category, Platform, name = "Count") %>% mutate(Metric = "Videos")
if (has_id) {
  cd <- bind_rows(cd, fd %>% group_by(Account_category, Platform) %>%
                    summarise(Count = n_distinct(Account_id), .groups = "drop") %>%
                    mutate(Metric = "Unique accounts"))
}
ord3 <- cd %>% filter(Metric == "Videos") %>% group_by(Account_category) %>%
  summarise(t = sum(Count)) %>% arrange(desc(t)) %>% pull(Account_category)
tot3 <- cd %>% group_by(Account_category, Metric) %>% summarise(total = sum(Count), .groups = "drop") %>%
  group_by(Metric) %>% mutate(thr = 0.06 * max(total)) %>% ungroup()
cd <- cd %>% left_join(distinct(tot3, Metric, thr), by = "Metric") %>%
  mutate(Account_category = factor(Account_category, levels = rev(ord3)),
         Metric = factor(Metric, levels = c("Videos", "Unique accounts")),
         Platform = factor(Platform, levels = plat_levels))
small3 <- cd %>% filter(Count < thr) %>% arrange(Account_category, Metric, desc(Platform)) %>%
  group_by(Account_category, Metric) %>% summarise(label = paste(Count, collapse = " / "), .groups = "drop") %>%
  left_join(tot3 %>% mutate(Account_category = factor(Account_category, levels = levels(cd$Account_category)),
                            Metric = factor(Metric, levels = levels(cd$Metric))) %>%
              select(Account_category, Metric, total), by = c("Account_category", "Metric"))

fig3 <- ggplot(cd, aes(x = Count, y = Account_category, fill = Platform)) +
  geom_col(position = "stack", width = 0.6) +
  geom_text(data = ~ filter(.x, Count >= thr), aes(label = Count, colour = Platform),
            position = position_stack(vjust = 0.5), size = lbl, family = fig_family, show.legend = FALSE) +
  geom_text(data = small3, aes(x = total, y = Account_category, label = label), inherit.aes = FALSE,
            hjust = -0.2, colour = "black", size = lbl, family = fig_family) +
  facet_wrap(~Metric, nrow = 1, scales = "free_x") +
  scale_fill_manual(values = plat_fill, labels = plat_labels(df)) +
  scale_colour_manual(values = plat_text, guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  scale_y_discrete(labels = function(x) str_wrap(x, width = 22)) +
  labs(x = NULL, y = "Communicator type", fill = NULL) + theme_ccr()
save_fig(fig3, "figure3_communicators.pdf", 3.5)

cat("\nDone. Tables:", normalizePath(out_tab), "\nFigures:", normalizePath(out_fig), "\n")
