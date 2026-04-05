---
name: japan-frontend-job-digest
description: Research current frontend, backend, QA, test, SDET, or web-engineering jobs in Japan, normalize live listings into ranked shortlists, and export the result as a Chinese Word-compatible .doc report. Use when Codex needs to search Japanese job markets for frontend, backend, or testing roles, compare openings, capture salary or language requirements, note visa or relocation signals, or turn job research into reusable JSON plus a shareable report.
---

# Japan Engineering Job Digest

Research current Japan frontend, backend, and testing opportunities, normalize them into the shared schema, then export a Chinese `.doc` report that opens in Microsoft Word or WPS.

Because job listings are time-sensitive, always verify live URLs with the `web` tool before finalizing the report.

## Use the bundled files

- Read [references/job-schema.md](references/job-schema.md) before normalizing records.
- Read [references/japan-domestic-sites.md](references/japan-domestic-sites.md) before searching so source selection stays biased toward Japanese domestic platforms.
- Read [references/search-templates.md](references/search-templates.md) when drafting site-specific search queries for frontend, backend, and QA/test roles.
- Read [references/closure-signals.md](references/closure-signals.md) when deciding whether a role is still open, closed, or unknown.
- Run [scripts/build-job-report-json.ps1](scripts/build-job-report-json.ps1) to wrap raw listings into report JSON, preserve top-level metadata, and remove duplicate rows.
- Run [scripts/export-job-report.ps1](scripts/export-job-report.ps1) to create the final Word-compatible `.doc`.

## Default output

Unless the user gives another location, write outputs under:

- `F:\workspace\skills\jphr\outputs\japan-frontend-jobs\<YYYY-MM-DD>\jobs.json`
- `F:\workspace\skills\jphr\outputs\japan-frontend-jobs\<YYYY-MM-DD>\japan-frontend-jobs-report.doc`

Treat `jobs.json` as the only canonical machine-readable output for downstream systems such as the dashboard sync. Do not point automations or websites at `jobs-built.json`, `jobs-live.json`, `jobs-top20-regression.json`, or any other experimental filename.

If the user asks for JSON-only or DOC-only delivery, skip the other artifact.

## Workflow

### 1. Infer the search frame

Infer these from the request when possible:

- target role and stack
- one or more role families: frontend, backend, qa/test
- city, nationwide, or remote-in-Japan scope
- seniority and employment type
- language constraints
- hard filters such as visa support, compensation floor, or remote ratio

If the request is underspecified, make reasonable assumptions and record them in top-level `assumptions`. Do not assume the user prefers English-speaking roles unless the request says so.

### 2. Search live listings

Prioritize current Japanese domestic sources first, then fill gaps with company career pages and international-facing Japan tech boards. Search separately for frontend, backend, and qa/test keywords whenever the user asks for multiple role families or leaves the role family broad.

Use both Japanese and English search phrases for every role family. Do not rely on English-only titles or English-only keyword combinations.

When a domestic board exposes role-family landing pages, open those landing pages directly before broad web search and harvest the top active rows with the richest metadata. This is especially useful on Forkwell Jobs, where role-family pages often surface salary, remote policy, and tech stack in one place.

Primary Japanese domestic source pool:

- Green
- Wantedly
- Forkwell Jobs
- YOUTRUST
- paiza
- Findy
- type
- doda
- Mynavi Tenshoku
- En Tenshoku
- BizReach
- LevTech Career
- Workport
- Geekly
- Rikunabi NEXT
- Mynavi IT Agent
- official company career pages in Japanese

Secondary source pool when domestic coverage is thin:

- TokyoDev
- JapanDev
- Daijob
- CareerCross
- LinkedIn Jobs
- Indeed Japan

Suggested keyword families:

- frontend: `frontend engineer`, `front-end engineer`, `web ui engineer`, `react engineer`, `フロントエンドエンジニア`, `フロントエンド`, `Webエンジニア`
- backend: `backend engineer`, `back-end engineer`, `server-side engineer`, `platform engineer`, `api engineer`, `バックエンドエンジニア`, `サーバーサイドエンジニア`, `バックエンド`, `サーバーサイド`
- qa/test: `qa engineer`, `test engineer`, `sdet`, `automation engineer`, `QAエンジニア`, `テストエンジニア`, `品質保証`, `自動テスト`

Apply these rules:

- exhaust domestic Japanese job boards before relying on global or expat-focused boards
- prefer direct employer pages over reposts
- capture the exact URL used for verification
- record absolute verification dates in `source_date`
- skip closed, expired, or obviously duplicated listings
- when the same job appears on multiple sites, prefer the employer page first, then the most information-rich Japanese domestic listing
- keep `source` stable and human-readable, using the marketplace or company site name rather than a raw domain
- maintain the same final output schema regardless of source site; source diversity must not change field names or top-level JSON shape
- accept Japanese job titles as first-class results; do not downgrade a listing just because the title is not in English

Site-specific harvesting notes:

- Green: prefer direct company job pages under `green-japan.com/company/.../job/...` because they usually expose salary, location, stack, and work-style metadata in the first screenful.
- Wantedly: only keep listings that still expose `話を聞きに行きたい` or another active-contact CTA. Drop listings that explicitly show `募集終了しました`.
- Forkwell Jobs: start from role-family pages or the main jobs listing, then click through to the canonical detail URL under `jobs.forkwell.com/<company>/jobs/<id>` before writing the final record.
- when adding new sources, prefer Japanese domestic boards, agents, and career portals before broad global aggregators

### 3. Normalize every opening

Read [references/job-schema.md](references/job-schema.md) and use those field names.

Always populate at least:

- `title`
- `company`
- `location`
- `work_mode`
- `employment_type`
- `url`
- `source`
- `source_date`
- `summary`

Populate `salary`, `japanese_level`, `english_level`, `visa_support`, `tech_stack`, `company_size`, `benefits`, `education_requirements`, `experience_requirements`, and `other_requirements` whenever the listing supports them. Treat `company_size` and `benefits` as priority metadata: if the listing or company page exposes them, capture them instead of leaving them out. Put inferred or uncertain details in `notes`, not in factual fields.

Always populate `first_posted_at`. Use the first known listing publication date when the source exposes it. If the source does not expose an earlier publication date, fall back to `source_date` so downstream dashboards keep a sortable first-recruitment field.

Always populate `source_url`. Use the exact listing or source page URL where the data was found or verified. If the source page and the job page are the same, set `source_url` equal to `url`.

Always validate whether the role is still open. Populate:

- `hiring_status` as `open`, `closed`, or `unknown`
- `status_reason` with the factual closure wording when the listing explicitly says the role is closed, filled, expired, or no longer accepting applications

When validating status, inspect the returned HTML or extracted page text as well as visible badges or buttons. If the HTML or extracted text contains phrases such as `This job is no longer available.`, `This position is closed and is no longer accepting applications.`, `募集終了`, or `応募受付終了`, treat the role as `closed` and sync that result into the final output JSON.

Do not mark a role as closed only because a later crawl did not find it. Missing capture is not a closure signal.

Internally classify each job as `frontend`, `backend`, or `qa` for ranking and caps, but keep the final output shape unchanged. Derive that classification from the explicit role target when possible, otherwise infer from title, summary, and stack.

When using Japanese domestic sites, normalize local wording into the shared schema without changing the output contract. Examples:

- Japanese education labels such as "no education requirement" or degree requirements -> `education_requirements`
- Japanese must-have skill or applicant requirement sections -> `experience_requirements` or `other_requirements`, depending on content
- Japanese benefits or compensation-and-benefits sections -> `benefits`
- Japanese employee-count or company-profile size text -> `company_size`

For `benefits`, write a short factual summary array rather than copying a long raw block. Good examples include items like `Full social insurance`, `Remote work allowance`, `Flexible hours`, `Stock options`, or `Commuting support`.

For `company_size`, keep the original scale wording when available, such as `120 employees`, `500-1000 employees`, or `約300名`. If the job page does not show it, check the linked company profile or official company page before giving up.

### 4. Rank and filter

Keep the shortlist useful rather than exhaustive:

- target 10 to 20 high-signal jobs per role family
- cap each role family at 20 jobs
- if a role family has fewer than 10 valid jobs, keep all valid jobs instead of padding with weak matches
- sort within each role family by role fit first, then listing quality and freshness
- remove duplicates by URL or near-identical company-title-location combinations

Use ranking factors such as stack fit, salary transparency, visa friendliness, remote flexibility, and listing completeness. Treat Japanese-language titles and Japanese-required roles as normal market results, not as lower-quality results by default. When mixing frontend, backend, and qa jobs in one run, preserve all selected jobs in the same final `jobs` array rather than splitting the output schema.

Bias ranking toward fresher, more complete domestic listings when role fit is otherwise similar.

When rebuilding the dashboard's canonical dataset, prefer real live jobs only. Keep regression or synthetic files out of the canonical `jobs.json` that feeds downstream sync.

### 5. Build report JSON

Save your normalized data as either:

- a top-level array of job objects
- an object containing a `jobs` array and optional top-level metadata

Recommended invocation:

```powershell
$skillRoot = "F:\workspace\skills\jphr\japan-frontend-job-digest"
$reportDate = Get-Date -Format "yyyy-MM-dd"
$outputDir = "F:\workspace\skills\jphr\outputs\japan-frontend-jobs\$reportDate"

powershell -ExecutionPolicy Bypass -File "$skillRoot\scripts\build-job-report-json.ps1" `
  -InputJson "<path-to-job-array-or-partial-json>" `
  -OutputJson "$outputDir\jobs.json" `
  -ReportTitle "Japan Frontend Job Opportunities" `
  -CreatedAt $reportDate `
  -TargetProfile "Frontend engineer with React experience" `
  -SearchScope "Tokyo and remote-friendly roles in Japan" `
  -Methodology "Verified against live listing pages on $reportDate."
```

The builder accepts optional top-level `assumptions` and `key_takeaways` arrays and preserves them in the final JSON. It dedupes globally, then keeps up to 20 jobs per role family while preserving the same final JSON structure.

If you also write a secondary filename such as `jobs-built.json` for inspection, run the final formal pass directly against `jobs.json`, or add `-WriteCanonicalCopy` explicitly when you really do want a second filename to also refresh the canonical file. Do not let regression or scratch outputs overwrite `jobs.json` by accident.

### 6. Export the `.doc`

Run:

```powershell
$skillRoot = "F:\workspace\skills\jphr\japan-frontend-job-digest"

powershell -ExecutionPolicy Bypass -File "$skillRoot\scripts\export-job-report.ps1" `
  -InputJson "<path-to-jobs.json>" `
  -OutputDoc "<path-to-report.doc>"
```

The exporter writes HTML-backed `.doc` output, so it does not rely on Microsoft Word automation or external Python packages.

## Report expectations

Keep the report compact and decision-oriented. Use Chinese structure and labels by default, while preserving original job titles, company names, and URLs.

Include:

- generation date and search scope
- explicit assumptions when the brief was underspecified
- key takeaways or summary bullets when helpful
- a comparison table
- detailed sections for each shortlisted job
- a short recommendation section for the best next applications

For each detailed job section, include company size, benefits, education requirements, experience requirements, and other requirements when available.

## Quality bar

Before finishing:

- confirm that included listings still appear open or current
- set `hiring_status` to `closed` only when the source explicitly confirms closure
- ensure every kept job has a working URL
- use concrete dates instead of relative phrases
- avoid unsupported claims about salary or visa sponsorship
- make sure the exported `.doc` opens with legible formatting

