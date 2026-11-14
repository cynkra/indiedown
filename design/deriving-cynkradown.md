# What indiedown needs to look like to derive cynkradown cleanly

This note answers a concrete design question:

> What would indiedown need to look like if **cynkradown** were to be derived,
> *in its current state*, from indiedown without too many modifications?

It uses [cynkradown](https://github.com/cynkra/cynkradown) as a worked example
of a "real" corporate-design package, and works backwards to the changes
indiedown would need so that such a package is a *thin* derivation rather than a
fork.

## How derivation works today

`create_indiedown_package()` copies `inst/mypackage/` into a new package. The
skeleton has three kinds of content:

1. **A vendored engine** — `R/indiedown.R`, copied verbatim and marked
   *"copied from indiedown / do not customize this file!"*. It provides
   `indiedown_pdf_document_with_asset()`, `apply_default_yaml()`,
   `indiedown_path()`, `indiedown_path_tex()`, `indiedown_glue()` and
   `default()`.
2. **Customization assets** — `inst/indiedown/{default.yaml,preamble.tex,pre_processor.R}`
   plus `fonts/` and `res/`. These are the three documented customization points
   (`vignette("customize")`).
3. **Example corporate-design code** — `cd_page_title()`, `cd_format_date()`,
   `cd_knit_chunk_opts()`, the output format wrapper (`mypackage()`), and one
   RMarkdown template under `inst/rmarkdown/templates/report/`.

The contract is sound: *extend Pandoc's default `.tex` instead of replacing it*,
and *keep corporate-design elements as R that emits LaTeX*. cynkradown follows
exactly this contract for its modern `cynkradown()` format. The friction is not
the contract — it is everything around the **vendored engine** and the
**single-PDF-format assumption**.

## The core problem: the vendored engine drifts

cynkradown carries a copy of `R/indiedown.R`. Diffing it against today's
skeleton copy shows drift in *both* directions:

- cynkradown's copy **exports** `indiedown_pdf_document_with_asset()` (it needs
  the builder so its own format wrappers and the deprecated vintage formats can
  call it). The skeleton copy does **not** export it.
- cynkradown's copy still has `FIXME` roxygen for `indiedown_pdf_document_with_asset()`
  and `default()`; the skeleton copy has since gained proper titles, `@return`
  and `@examples` — improvements that never flowed back to cynkradown.

This is the classic vendoring failure mode: a file that is "not to be edited" but
has no delivery mechanism, no version stamp, and no way to detect or repair
drift. Regenerating cynkradown from today's indiedown would silently *remove* an
exported function it depends on and *rewrite* its roxygen.

**What indiedown needs:** a single, authoritative way to deliver the engine.
Two viable shapes, in order of preference:

1. **Export the engine and depend on it (`Imports: indiedown`).** Promote
   `indiedown_pdf_document_with_asset()`, `indiedown_path()`,
   `indiedown_path_tex()`, `indiedown_glue()`, `default()` and
   `apply_default_yaml()` to exported, documented, `R CMD check`-clean functions
   of the *indiedown package itself* (today these live only inside the skeleton
   copy — indiedown's own `NAMESPACE` exports none of them). A derived package
   then keeps **zero** copied engine code; it only ships assets and its own CD
   functions. This is what makes cynkradown derivable "without too many
   modifications": the entire `R/indiedown.R` copy disappears.
2. **Keep vendoring, but make it managed.** If copying is preferred (e.g. to
   avoid a runtime dependency), ship the engine as a single resource and add an
   `update_indiedown()` that rewrites the derived package's copy byte-for-byte,
   plus a version marker so drift is detectable. The copy must already be
   exactly what a real package needs — including exporting the format builder.

Either way, the immediate fix is that the engine indiedown ships must be the
*superset* cynkradown actually uses (notably: `indiedown_pdf_document_with_asset()`
exported) and must pass `R CMD check` with no `FIXME` placeholders.

## What else the skeleton must grow to cover cynkradown

cynkradown is bigger than `mypackage`. Sorting its surface into "indiedown should
provide / model this" vs. "legitimately stays local":

### 1. A *family* of header generators, not one title page

indiedown ships a single `cd_page_title()`. cynkradown ships six:
`cd_header_article()`, `cd_header_cover()`, `cd_header_leaflet()`,
`cd_header_letter()`, `cd_header_report()`, `cd_header_simple()`. They are all
the same idea — an R function returning `knitr::asis_output()` LaTeX that reads
assets via `indiedown_path()`.

indiedown does not need to ship cynkra's headers, but to be derivable "without
too many modifications" it should:

- treat *multiple* header generators as the expected shape (the vignette already
  hints at this), and
- ship two or three representative examples (e.g. article + letter + report) so a
  derived package edits content rather than inventing the pattern.

### 2. More than one RMarkdown template, and a way to scaffold them

`create_indiedown_package()` wires up exactly one template (`report`).
cynkradown ships five (article, letter, report, slides, handout). Deriving
cynkradown means adding four templates by hand.

indiedown should either scaffold a small set of templates, or document +
support `usethis::use_rmarkdown_template()` as the first-class way to add more
(the customize vignette mentions it; the generator does not help with it).

### 3. Non-PDF output is currently out of scope

cynkradown's `cynkra_slides()` is an **HTML** format built on
`xaringan::moon_reader()` with a CSS asset (`inst/css/slides.css`). indiedown is,
by name and design, *"Individual R Markdown PDF Templates"*. This is the single
largest scope mismatch: nothing in indiedown models an asset-aware HTML/CSS
format.

For a clean derivation indiedown must do one of:

- **Broaden the contract** to "asset-aware R Markdown formats" and provide an
  HTML counterpart to `indiedown_pdf_document_with_asset()` (CSS/asset resolution
  via the same `inst/indiedown` + `indiedown_path()` machinery), or
- **Explicitly scope HTML out** and document that HTML formats are a
  package-specific add-on. Then `cynkra_slides()` is one of the accepted "few
  modifications" rather than a gap in indiedown.

Recommendation: keep indiedown PDF-focused for now but state the boundary
explicitly, so slides are a known local add-on rather than undefined behavior.

### 4. A correct DESCRIPTION baseline

The skeleton `DESCRIPTION` imports `glue, knitr, rmarkdown, utils, withr, yaml`
— which is exactly what the engine and example CD code use. cynkradown's
`DESCRIPTION` is **missing** `yaml`, `utils` and `withr` (all used by the vendored
engine / `cd_format_date()`) and adds `htmltools, magick, xaringan` for its
extras. A derived package should start from the skeleton's correct import set; the
generator already gets this right, so the lesson is mostly "don't let it rot."

### 5. Things that legitimately stay in the derived package

These are *not* gaps in indiedown — they are the expected local additions and
should remain in cynkradown:

- ggplot2 theming (`theme_cynkra()`, `scale_*_cynkra()`, `sec_scale()`, color
  helpers),
- table helpers (`kable_twocolumn()`, `kable_extra_extra`),
- `get_unsplash()`, `cd_sign()`,
- spell-checking helpers (`spell_check_rmd()`, `update_wordlist_rmd()`),
- the actual cynkra fonts, colors and logos in `inst/indiedown/`.

The customize vignette already says "put helper functions in `R/`". indiedown
just needs to keep that an explicit, supported extension point.

## Things that must change in cynkradown, not in indiedown

For completeness (these belong to the cynkradown side of the work): the
deprecated **vintage** formats — `cynkra_handout()`, `cynkra_report()`,
`cynkra_book()` and their `cynkra-handout.tex` / `cynkra-report.tex` templates —
*replace* Pandoc's template and predate the indiedown architecture. They are the
opposite of indiedown's "extend, don't replace" principle and cannot be derived
from indiedown by construction. They are already deprecated with warnings;
removing them is cynkradown's job, not something indiedown should accommodate.

## Summary: the shape of a derivation-ready indiedown

To let cynkradown (in its current state) be a thin derivation:

1. **Deliver the engine once, authoritatively** — export it from the indiedown
   package and depend on it, *or* ship a managed, version-stamped vendored copy
   with an `update_indiedown()` refresh. The shipped engine must already export
   `indiedown_pdf_document_with_asset()` and be `R CMD check`-clean (no `FIXME`).
2. **Model a family of header generators**, shipping a couple of real examples
   instead of a single `cd_page_title()`.
3. **Support multiple RMarkdown templates** in the generator / document the
   `usethis` path.
4. **Decide the HTML question explicitly** — either provide an asset-aware HTML
   helper or declare HTML formats an accepted local add-on.
5. **Keep the DESCRIPTION import baseline correct** and keep `R/` helper code an
   explicit extension point.

With (1) and (2) alone, the bulk of the divergence (a drifting engine copy and a
hand-built header family) disappears; (3)–(5) reduce the remaining derivation to
editing content and dropping the deprecated vintage formats.
