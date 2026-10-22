# OER textbooks: PreTeXt upgrade

This repo (`unl-math-course-dev/OER`, default branch `master`) holds seven separate
PreTeXt projects, one per folder: AppliedCalculus, Calculus, ContemporaryMathematics,
DifferentialEquations, LinearAlgebra, MultivariableCalculus, PreCalculus. Each folder has
its own `project.ptx`, `publication/publication.ptx`, `source/`, `assets/`, `xsl/`, and
`requirements.txt`. The top-level `xsl/` folder (old `mathbook-*.xsl`) appears unused.

Current goal: update each book to PreTeXt CLI **2.55.0** and clear all deprecation
warnings. The plan below was drafted 2026-10-19 from the 2.55.0 CHANGELOG and the core
deprecation list (`pretext-common.xsl`, `publisher-variables.xsl`).

## Ground rules

- **Deployment changes are ON HOLD** pending discussion with stakeholders. Do not add,
  edit, or delete GitHub workflows, and do not change how mathbooks.unl.edu builds.
  (Today the server pulls this repo and builds the books itself.)
- **Never run `pretext deploy` inside a book folder.** It only looks for `.git` in the
  folder with `project.ptx`. In a subfolder it runs `git init` there, makes an "Initial
  commit", and force-pushes a `gh-pages` branch containing only that book. That is how the
  stray inner repos in DifferentialEquations and MultivariableCalculus were created.
- Work on one book at a time, on its own branch (for example `upgrade/precalculus`). Changes
  that touch several books (tooling, top-level cleanup) go on their own branch.
- Make one commit per kind of change (for example "me/men -> md"), so each step can be
  reviewed and reverted on its own.
- Before upgrading a book, build it at its current pin and save the output as a baseline.
  After upgrading, diff against that baseline.
- Books are in use for courses, but the live site isn't built from these branches, so
  numbering or layout changes are allowed. Report every numbering change to Zach (for
  example, "Theorem 3 becomes Theorem 2").
- Preserve every `xml:id` and every cross-reference target. Course materials and WeBWorK
  sets point at these numbers and pages.

## Where each book stands (2026-10-19 scan)

| Book | Pinned | me/men | 1-panel sidebyside | @permid | Other |
|---|---|---|---|---|---|
| PreCalculus | 2.53.0 | 1,220 (+2 mdn) | 212 | 7 | legacy `css` attrs; `exercise-readingquestion`; docinfo `brandlogo` + `feedback` (in `source/bookinfo.ptx`); authors in `titlepage`; 3 `ol/@label` |
| LinearAlgebra | 2.19.2 | 2,381 (+7 mdn) | 0 | 0 | 221 latex-image; 2 `exercise/ol` |
| DifferentialEquations | 2.7.1 | 1,660 (+23 mdn) | 3 | 0 | 134 sageplot; 4 asymptote; `references/introduction`; stray inner `.git` |
| AppliedCalculus | 2.5.2 | 3,150 (+3 mdn) | 452 | 25,292 | 1,392 `ol/@label`; 6 `exercise/ol`; `<mathbook>` root in 2 files; `tabular//fn` |
| Calculus | 2.5.1 | 2,340 (+3 mdn) | 349 | 19,702 | 34 `ol/@label`; 6 `exercise/ol`; `<mathbook>` root in 2 files |
| ContemporaryMathematics | 2.4.1 | 82 | 89 | 20 | titled division `introduction` |
| MultivariableCalculus | 2.4.1 | 661 (+3 mdn) | 6 | 28 | 21 `statement/ol` (9 in exercises, 12 in activities); stray inner `.git` (local clones only) |

MultivariableCalculus details (rechecked 2026-10-19): no `references/introduction`
(`bibliography.ptx` is title-only and not included); the 2 `ol/@label` are inside a comment;
the publication file already uses `css/@theme`; leftovers `source/colophon.ptx.bak` and an
unused `update.xml`.

All books (local clones): an unused `codechat_config.yaml` (CodeChat removed in 2.50). It is
gitignored, so it isn't in the GitHub repo. The custom LaTeX
XSL overrides `mode="half-title"`, which core renamed to `half-title-ad-card`, so that
override is currently ignored.

## Lessons from MultivariableCalculus (apply to every book)

- **Project numbering:** before 2.42, activities/projects had their own counter by default.
  Now they share the block counter unless `numbering/projects/@distinct="yes"`. Add it, or
  nearly every activity number changes.
- **List markers in Exercises:** 2.4.x counted every list inside an `exercises` division one
  level deeper, so an unmarked list showed `a.`. 2.55 doesn't, so it shows `1.` instead.
  Give such lists an explicit `@marker`.
- **Lists in activities:** an `ol` directly inside `activity`, `exploration`, or a `statement`
  is a schema error (only the `exercise` case is a deprecation). Wrap it in `p`.
- **Image alt text:** `image/@alt` doesn't exist in PreTeXt and is silently dropped. Use a
  `shortdescription` child; `description` must contain `p`.
- **External directory:** `source/directories/@external` moved to `docinfo/directories/@external`
  (2026-07-30). `@generated` stays in the publication file.
- **Duplicate `xml:id`s** stop `pretext validate`. Check for them first.
- **This cloud sandbox** can't reach `webwork-ptx.aimath.org` (blocked by network policy), has
  no TeX/asy/Sage, and has no `jing` (use `pretext validate --engine salve`).

## Lessons from PreCalculus

- Books already on 2.42 or later number projects and letter lists like 2.55 does. Don't
  add `projects/@distinct` there; compare against the old core before copying a fix.
- `docinfo/feedback` is ignored by 2.53+; it lives at `publication/html/feedback/@href`.
- Core's automatic frontmatter repair labels the colophon `front-colophon`. Keep
  `colophon/@label="front-colophon"` so the page keeps its address.
- `bibinfo` takes one `copyright`; put extra notices elsewhere (Zach chose Acknowledgements).
- A `references` division can't be an appendix's only content; it goes after the appendices.
- One-panel `sidebyside`: move `@width`/`@margins` to the `image` (for a `figure`, its
  image). With `widths="20% 60% 20%"` and one panel, core used 20%; 60% was the intent.
- `md` in a table `cell` must be wrapped in `p`; PreTeXt then warns about missing column
  widths, but the HTML layout is unchanged.
- Unwrapping an `introduction` can number blocks that weren't numbered before. Diff numbers.
- PreCalculus's WeBWorK host `math-webwork3.unl.edu` must be allowed in the sandbox.

## Phase 0: cleanup

1. Back up, then remove the inner `.git` folders in DifferentialEquations and
   MultivariableCalculus. They have no remote; the OER repo already tracks those files.
   The Multivariable one has `main` and `gh-pages` branches; DiffEq has 2 commits.
2. Delete leftovers: `AppliedCalculus/source/OLD ptx/`, `*.bak` files, `*.textClipping`,
   `LinearAlgebra/LinearAlgebraV2-master.zip`, `DifferentialEquations/xsl/cde-latex-backup.xsl`.
   Confirm the top-level `xsl/` is unused before removing it.
3. Asset folders are huge and duplicated across books (most of each `output/web` is
   `external/`, a copy of `assets/`). List unreferenced assets, but delete only after
   Zach reviews the list.

## Phase 1: tools

- Use a single venv with `pretext==2.55.0` (Python 3.10 or newer). Also needed: Node 22.10
  or newer (fill-in-the-blank), jing (`pretext validate`), local `asy` (default since 2.38),
  Sage (DifferentialEquations plots), and TeX (latex-image in LinearAlgebra and DiffEq).
- In each book, update the `requirements.txt` pin, then run `pretext update-project`. That
  command replaces the old `pretext update` and removes `codechat_config.yaml`.

## Phase 2: source migration (scripted; one commit per item)

1. Publication file: `css` attributes become `@theme`; `exercise-readingquestion` becomes
   `exercise-reading`; move `brandlogo` and `feedback` from docinfo into the publication
   file. Make sure project-like numbering stays the same (it changed in 2.42; see
   `numbering/projects`).
2. Docinfo and frontmatter: move authors and credits from `titlepage`/`colophon` into
   `bibinfo`. `docinfo/cross-references` becomes `docinfo/defaults/xrefs/@text`.
3. Math: `me` becomes `md` with no `mrow`; `men` and `mdn` become `md` with
   `@number="yes"`. Keep `xml:id` and `@tag`.
4. Lists and exercises: `ol/@label` and `ul/@label` become `@marker`. Wrap an `ol` that is
   a direct child of `exercise` or `statement` in a `p`. Multi-part exercises written as
   `ol` are deprecated (2.50); flag them for conversion to `task`, but don't convert them
   automatically.
5. A `sidebyside` with only one panel: use `image/@width` or remove the wrapper. Core keeps
   supporting the old form until at least 2028-08-23, so this is lower priority.
6. Cleanup: strip `@permid`; `<mathbook>` becomes `<pretext>`; footnotes (`fn`) inside
   `tabular` become table notes (`tn`); `references/introduction` becomes `headnote`; drop
   titles on division `introduction`/`conclusion`.
7. Custom XSL: rename the `half-title` override to `half-title-ad-card` and check every
   other override against core.

## Phase 3: verify

- `pretext validate` should report zero deprecations.
- Build `web` and `pdf` and diff them against the baseline. Check especially:
  - numbering
  - WeBWorK (one representation file per problem since 2.40)
  - images
  - MathJax 4 rendering (2.39)
- PreCalculus's WeBWorK uses `https://math-webwork3.unl.edu`; the other books use
  `webwork-ptx.aimath.org`.

## Order

MultivariableCalculus (done, PR #102), PreCalculus (PR #103), then LinearAlgebra,
DifferentialEquations, ContemporaryMathematics, Calculus, AppliedCalculus.

## Notes for later (deployment, on hold)

- The per-book `.github/workflows/pretext-cli.yml` files never run. GitHub only reads
  workflows from the repo-root `.github/`, and these trigger on `main`, not `master`.
- The root `.gitignore` contains `.*`, which would also ignore a future root `.github/`.
- The direction under discussion: one root workflow that builds the books and publishes
  them to GitHub Pages as a fallback, possibly with the server just pulling built HTML.
  GitHub Pages sites are limited to 1 GB.
