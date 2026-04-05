# Job Schema

Use this schema when collecting and ranking Japanese frontend, backend, and QA/test job opportunities.

## Top-level object

```json
{
  "report_title": "Japan Frontend Job Opportunities",
  "created_at": "2026-04-04",
  "target_profile": "Frontend, backend, or QA engineer profile for Japan roles, including Japanese-language listings",
  "search_scope": "Tokyo and remote-friendly roles in Japan",
  "methodology": "Verified with live listings and official sources where possible.",
  "assumptions": [
    "Target candidate prefers English-friendly product companies."
  ],
  "key_takeaways": [
    "Japanese domestic boards often contain richer Japanese-language listings than expat-focused boards."
  ],
  "jobs": []
}
```

## Job record fields

```json
{
  "title": "Senior Frontend Engineer",
  "company": "Example KK",
  "job_family": "frontend",
  "company_size": "500-1000 employees",
  "location": "Tokyo, Japan",
  "work_mode": "Hybrid",
  "employment_type": "Full-time",
  "salary": "JPY 7,000,000 - 10,000,000",
  "japanese_level": "Business",
  "english_level": "Professional",
  "visa_support": "Unknown",
  "tech_stack": "React, TypeScript, Next.js",
  "benefits": ["Full social insurance", "Commuting allowance", "Remote work support"],
  "education_requirements": "Bachelor's degree preferred",
  "experience_requirements": "3+ years of frontend product development experience",
  "other_requirements": "Must already reside in Japan or be eligible to relocate",
  "summary": "Build and improve the customer-facing web platform.",
  "url": "https://example.com/jobs/frontend",
  "source": "Official Careers",
  "source_url": "https://example.com/jobs/frontend",
  "source_date": "2026-04-04",
  "first_posted_at": "2026-03-28",
  "hiring_status": "open",
  "status_reason": "",
  "match_score": 8.7,
  "notes": "Remote policy stated explicitly. Visa support not mentioned."
}
```

## Normalization rules

- `job_family`: use `frontend`, `backend`, `qa`, or `fullstack`. Prefer explicit family labels from the source workflow over inference when available.
- `location`: preserve the listing's stated city and country; add `Remote in Japan` only when stated.
- `work_mode`: use one of `Onsite`, `Hybrid`, `Remote`, `Remote in Japan`, `Unknown`.
- `employment_type`: use one of `Full-time`, `Contract`, `Freelance`, `Internship`, `Unknown`.
- `salary`: keep the original currency and range when provided.
- `japanese_level`: use plain labels such as `None stated`, `Basic`, `Business`, `Native`, `Unknown`.
- `english_level`: use plain labels such as `None stated`, `Conversational`, `Professional`, `Native`, `Unknown`.
- `visa_support`: use `Yes`, `No`, `Unknown`, or a short factual phrase from the listing.
- `tech_stack`: a comma-separated short list.
- `company_size`: keep the original company-size wording from the listing or company page. If the listing omits it, check the linked company profile or official company page before leaving it unknown.
- `benefits`: use a short array of factual benefit-summary strings; trim, dedupe, skip blanks, and prefer concise summaries over long pasted policy text.
- `education_requirements`: capture stated degree or education requirements as a short string.
- `experience_requirements`: capture years of experience, level, or domain experience requirements as a short string.
- `other_requirements`: capture other concrete requirements such as residency, language, or eligibility constraints that do not fit the fields above.
- `summary`: 1 to 2 sentences only.
- `source_url`: store the exact listing or source page URL where the record was found or verified. If there is no distinct source page beyond the job URL, fall back to `url`.
- `source_date`: always use absolute date format `YYYY-MM-DD`; use the listing verification date, not the report export date.
- `first_posted_at`: use the first known listing publication date in `YYYY-MM-DD` format whenever the source exposes it. If the source does not expose an earlier publication date, fall back to the current verified listing date so downstream dashboards still have a sortable field.
- `hiring_status`: use `open`, `closed`, or `unknown`. Set `closed` only when the page explicitly indicates that the role is no longer hiring, filled, closed, expired, or no longer accepting applications.
- `status_reason`: store the factual closure wording or a short normalized reason such as `position filled`, `applications closed`, or `listing expired`. Leave empty when the status is `open` or `unknown`.
- Internal validation fields such as `html_validation_text`, `page_text`, `response_text`, or `raw_text` may be used during normalization to infer `hiring_status` and `status_reason`, but they should not be emitted as extra top-level output fields.
- `match_score`: use a 0 to 10 score only when ranking helps.
- `notes`: use for caveats, inferred details, and missing information.
- `source`: use a stable human-readable site or company name such as `Official Careers`, `Green`, `Wantedly`, `Forkwell Jobs`, `YOUTRUST`, `paiza転職`, `Findy`, `type`, `doda`, `マイナビ転職`, or `エン転職`.

## Optional top-level fields

- Preferred `source` labels for domestic boards include `Green`, `Wantedly`, `Forkwell Jobs`, `YOUTRUST`, `paiza`, `Findy`, `type`, `doda`, `Mynavi Tenshoku`, `En Tenshoku`, and `Official Careers`.
- Additional acceptable `source` labels include `BizReach`, `LevTech Career`, `Workport`, `Geekly`, `Rikunabi NEXT`, `Mynavi IT Agent`, and `CareerCross`.
- `assumptions`: short bullet-style strings that explain inferred scope, filters, or candidate profile choices.
- `key_takeaways`: short bullet-style strings that summarize the market or shortlist at a glance.

## Inclusion guidance

Prefer roles that are clearly frontend-focused, including:

- Frontend Engineer
- Senior Frontend Engineer
- Web UI Engineer
- React Engineer
- Staff Frontend Engineer
- Backend Engineer
- Server-side Engineer
- Platform Engineer
- API Engineer
- QA Engineer
- Test Engineer
- SDET
- Automation Engineer
- Full-stack roles only if frontend or backend is a major responsibility

Exclude roles that are mainly:

- Native mobile-only
- Design-only
- Data-only

## Report ordering

Default order:

1. Highest fit
2. Highest information quality
3. Best salary transparency
4. Best remote or language accessibility

Keep at most 20 jobs in the final shortlist after dedupe and ranking. If fewer than 20 valid jobs are found, keep all valid jobs.

When the run includes multiple role families, apply the cap per family:

- frontend: up to 20
- backend: up to 20
- qa/test: up to 20

Target at least 10 valid jobs per family when the market supports it. If a family has fewer than 10 valid jobs after filtering, keep all valid jobs without changing the output schema.

## Source compatibility

- Keep the final JSON shape identical across domestic Japanese boards, company career pages, and international Japan-focused sites.
- Normalize Japanese listing labels into the shared fields instead of creating board-specific keys.
- Prefer richer domestic listings when they add factual fields such as benefits, employee count, or requirement detail, but keep output field names unchanged.
- Keep Japanese job titles exactly as listed when that is the source title; do not force English translation in the structured output.
- Always verify whether the job is still hiring. Do not infer `closed` only because a listing was hard to find on a later pass; require an explicit closure signal from the source page or a verified successor page.
- When available, `company_size` and `benefits` should be preserved all the way through the final JSON instead of being collapsed into `summary` or `notes`.
