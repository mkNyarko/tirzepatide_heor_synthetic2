# =============================================================================
# 98_build_rmd.R
# Purpose: assemble the annotated R Markdown (HEOR_Tirzepatide_Analysis.Rmd) from
#          05_code/rmd_template.Rmd. Each {{chunk:label}} placeholder is replaced by the
#          code that follows the line "## ---- label ----" in the numbered scripts, so the
#          R Markdown and the scripts always contain the same code.
# Usage:   Rscript 05_code/98_build_rmd.R
# =============================================================================
root <- here::here()
scripts <- list.files(file.path(root, "05_code"), pattern = "^(0[0-9]|10)[a-z_]*.*\\.R$", full.names = TRUE)

chunks <- list()
for (f in scripts) {
  lines <- readLines(f, warn = FALSE)
  starts <- grep("^## ---- .+ ----$", lines)
  if (!length(starts)) next
  ends <- c(starts[-1] - 1, length(lines))
  for (k in seq_along(starts)) {
    label <- sub("^## ---- (.+) ----$", "\\1", lines[starts[k]])
    body  <- lines[(starts[k] + 1):ends[k]]
    while (length(body) && !nzchar(trimws(body[length(body)]))) body <- body[-length(body)]
    if (!is.null(chunks[[label]])) stop("Duplicate chunk label: ", label)
    chunks[[label]] <- body
  }
}

tpl <- readLines(file.path(root, "05_code", "rmd_template.Rmd"), warn = FALSE)
out <- character()
for (l in tpl) {
  if (grepl("^\\{\\{chunk:.+\\}\\}$", l)) {
    spec  <- sub("^\\{\\{chunk:(.+)\\}\\}$", "\\1", l)
    label <- sub(",.*", "", spec)
    opts  <- if (grepl(",", spec)) paste0(", ", sub("^[^,]+, *", "", spec)) else ""
    if (is.null(chunks[[label]])) stop("No code found for chunk: ", label)
    out <- c(out, paste0("```{r ", label, opts, "}"), chunks[[label]], "```")
    chunks[[label]] <- NULL
  } else out <- c(out, l)
}
if (length(chunks)) message("Labels in scripts not used in the template: ", paste(names(chunks), collapse = ", "))
writeLines(out, file.path(root, "HEOR_Tirzepatide_Analysis.Rmd"))
message("Wrote HEOR_Tirzepatide_Analysis.Rmd (", length(out), " lines)")
