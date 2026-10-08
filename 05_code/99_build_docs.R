# =============================================================================
# 99_build_docs.R
# Purpose: convert the Markdown sources of the written deliverables (docs_src/*.md)
#          into Word documents with officer + flextable (no pandoc needed).
# Usage:   Rscript 05_code/99_build_docs.R            # builds every docs_src/*.md
#          Rscript 05_code/99_build_docs.R sap        # builds files whose name contains "sap"
# Markdown supported: # / ## / ### headings, paragraphs, "- " bullets, "1. " numbered items,
#   pipe tables, ![caption](path/to/image.png), **bold**, *italic*, `code`, and a line
#   containing only \newpage. A first-line HTML comment <!-- out: folder/file.docx --> sets
#   the output path (relative to the project root). <!-- landscape --> ... <!-- /landscape --> puts the enclosed content on landscape pages.
# =============================================================================
suppressPackageStartupMessages({library(officer); library(flextable)})
root <- here::here()

base_font <- "Arial"
fp_base <- fp_text(font.family = base_font, font.size = 10.5)

# Inline formatting: split text into runs for **bold**, *italic* and `code`
inline_runs <- function(txt, size = 10.5) {
  parts <- regmatches(txt, gregexpr("\\*\\*[^*]+\\*\\*|\\*[^* ][^*]*\\*|`[^`]+`", txt), invert = NA)[[1]]
  runs <- lapply(parts[nzchar(parts)], function(p) {
    if (grepl("^\\*\\*.*\\*\\*$", p)) ftext(gsub("^\\*\\*|\\*\\*$", "", p), fp_text(font.family = base_font, font.size = size, bold = TRUE))
    else if (grepl("^\\*.*\\*$", p))  ftext(gsub("^\\*|\\*$", "", p), fp_text(font.family = base_font, font.size = size, italic = TRUE))
    else if (grepl("^`.*`$", p))      ftext(gsub("^`|`$", "", p), fp_text(font.family = "Consolas", font.size = size - 1))
    else ftext(p, fp_text(font.family = base_font, font.size = size))
  })
  runs
}
para <- function(txt, indent = 0, prefix = NULL, size = 10.5) {
  runs <- inline_runs(txt, size)
  if (!is.null(prefix)) runs <- c(list(ftext(prefix, fp_text(font.family = base_font, font.size = size))), runs)
  do.call(fpar, c(runs, list(fp_p = fp_par(padding.left = indent, padding.bottom = 4, line_spacing = 1.1))))
}

md_table <- function(lines) {
  rows <- lapply(lines, function(l) trimws(strsplit(gsub("^\\||\\|$", "", trimws(l)), "\\|")[[1]]))
  header <- rows[[1]]; body <- rows[-(1:2)]
  body <- lapply(body, function(r) { length(r) <- length(header); r[is.na(r)] <- ""; r })
  df <- as.data.frame(do.call(rbind, body), stringsAsFactors = FALSE)
  names(df) <- make.unique(ifelse(nzchar(header), header, " "))
  df[] <- lapply(df, function(x) gsub("\\*\\*|`", "", x))
  ft <- flextable(df) |>
    set_header_labels(values = setNames(as.list(header), names(df))) |>
    theme_booktabs() |>
    font(fontname = base_font, part = "all") |>
    fontsize(size = 8.5, part = "all") |>
    bold(part = "header") |>
    bg(part = "header", bg = "#E8EEF5") |>
    valign(valign = "top", part = "all") |>
    padding(padding = 2, part = "all") |>
    set_table_properties(layout = "autofit", width = 1)
  ft
}

md_to_docx <- function(md_file) {
  lines <- readLines(md_file, encoding = "UTF-8", warn = FALSE)
  out_rel <- sub("^<!-- out: (.*) -->$", "\\1", lines[1])
  if (identical(out_rel, lines[1])) stop("First line must be <!-- out: path.docx -->")
  lines <- lines[-1]
  doc <- read_docx()
  i <- 1; buf <- character()
  flush <- function() {
    if (length(buf)) doc <<- body_add_fpar(doc, para(paste(buf, collapse = " ")))
    buf <<- character()
  }
  while (i <= length(lines)) {
    l <- lines[i]
    if (grepl("^\\s*$", l)) { flush(); i <- i + 1; next }
    if (grepl("^\\\\newpage", l)) { flush(); doc <- body_add_break(doc); i <- i + 1; next }
    if (grepl("^<!-- landscape -->", l))  { flush(); doc <- body_end_section_portrait(doc);  i <- i + 1; next }
    if (grepl("^<!-- /landscape -->", l)) { flush(); doc <- body_end_section_landscape(doc); i <- i + 1; next }
    if (grepl("^#{1,3} ", l)) {
      flush(); lvl <- nchar(sub(" .*", "", l)); txt <- sub("^#+ ", "", l)
      if (lvl == 1 && i <= 3) {
        doc <- body_add_fpar(doc, fpar(ftext(txt, fp_text(font.family = base_font, font.size = 18, bold = TRUE, color = "#1F3864")),
                                       fp_p = fp_par(padding.bottom = 8)))
      } else {
        sz <- c(18, 14, 12)[lvl]; col <- c("#1F3864", "#1F3864", "#2E5597")[lvl]
        doc <- body_add_fpar(doc, fpar(ftext(txt, fp_text(font.family = base_font, font.size = sz, bold = TRUE, color = col)),
                                       fp_p = fp_par(padding.top = if (lvl == 2) 10 else 6, padding.bottom = 4)))
      }
      i <- i + 1; next
    }
    if (grepl("^\\|", l)) {
      flush(); j <- i; while (j <= length(lines) && grepl("^\\|", lines[j])) j <- j + 1
      doc <- body_add_flextable(doc, md_table(lines[i:(j - 1)]))
      doc <- body_add_par(doc, "", style = "Normal")
      i <- j; next
    }
    if (grepl("^!\\[", l)) {
      flush(); cap <- sub("^!\\[(.*)\\]\\((.*)\\).*$", "\\1", l); path <- sub("^!\\[(.*)\\]\\((.*)\\).*$", "\\2", l)
      img <- file.path(root, path)
      if (file.exists(img)) {
        dims <- tryCatch(dim(png::readPNG(img)), error = function(e) c(600, 900))
        w <- 6.3; h <- min(8.2, w * dims[1] / dims[2])
        doc <- body_add_img(doc, img, width = h / dims[1] * dims[2], height = h)
      } else doc <- body_add_par(doc, paste("[Missing figure:", path, "]"))
      doc <- body_add_fpar(doc, para(cap, size = 9))
      i <- i + 1; next
    }
    if (grepl("^\\s*[-*] ", l)) {
      flush(); ind <- nchar(sub("[-*].*", "", l))
      doc <- body_add_fpar(doc, para(sub("^\\s*[-*] ", "", l), indent = 14 + ind * 6, prefix = "•  "))
      i <- i + 1; next
    }
    if (grepl("^\\s*[0-9]+\\. ", l)) {
      flush(); num <- sub("^\\s*([0-9]+)\\. .*", "\\1", l)
      doc <- body_add_fpar(doc, para(sub("^\\s*[0-9]+\\. ", "", l), indent = 14, prefix = paste0(num, ".  ")))
      i <- i + 1; next
    }
    buf <- c(buf, trimws(l)); i <- i + 1
  }
  flush()
  out <- file.path(root, out_rel)
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  print(doc, target = out)
  message("Built ", out_rel)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  files <- list.files(file.path(root, "docs_src"), pattern = "\\.md$", full.names = TRUE)
  if (length(args)) files <- files[grepl(args[1], basename(files), ignore.case = TRUE)]
  invisible(lapply(files, md_to_docx))
}
