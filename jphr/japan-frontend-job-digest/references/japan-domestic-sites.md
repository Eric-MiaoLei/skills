# Japan Domestic Sites

Use this reference when collecting frontend jobs from Japanese domestic marketplaces before falling back to expat-focused boards.

Prefer broad Japanese-language retrieval. Many domestic boards expose richer listings under Japanese titles and Japanese requirement sections than under English labels.

## Preferred domestic sites

- `Green`: broad Japanese web and product hiring, often includes detailed stack, benefits, and company profile fields.
- `Wantedly`: strong startup and product-company coverage; useful for culture, mission, team details, and casual hiring pipelines.
- `Forkwell Jobs`: engineer-focused listings with clearer technical expectations than generalist boards.
- `YOUTRUST`: startup and referral-heavy hiring; useful for modern product teams and informal role descriptions.
- `paiza`: engineering-oriented listings with concrete skill and requirement sections.
- `Findy`: developer-focused marketplace with frequent frontend and product-engineering openings.
- `type`: mainstream Japanese hiring site with useful filters for web engineer roles.
- `doda`: large domestic board with broad coverage and structured requirement sections.
- `Mynavi Tenshoku`: mainstream domestic board, useful when startup-focused sites are thin.
- `En Tenshoku`: another broad domestic board with structured company and requirement information.
- `BizReach`: high-skill and mid-to-senior hiring marketplace with many Japanese-language engineering openings.
- `LevTech Career`: engineering-focused Japanese career portal with good stack and requirement detail.
- `Workport`: large Japanese career portal with broad web and software engineering coverage.
- `Geekly`: IT-focused Japanese recruiting platform with dense software and product hiring coverage.
- `Rikunabi NEXT`: mainstream domestic board with broad engineering coverage.
- `Mynavi IT Agent`: engineering-focused career portal from the Mynavi ecosystem.

## Source priority

Use this order when the same role appears in multiple places:

1. Official employer career page
2. Information-rich Japanese domestic listing
3. Japan-focused international board such as TokyoDev or JapanDev
4. Large aggregator or repost

## Extraction hints

- job description sections usually support `summary`
- must-have conditions, applicant qualifications, or required skill sections usually support `experience_requirements` or `other_requirements`
- preferred conditions or welcome skill sections usually support `other_requirements`
- education sections usually support `education_requirements`
- compensation or expected annual salary sections usually support `salary`
- work location sections usually support `location`
- work-style, remote, or work-from-home sections usually support `work_mode`
- benefits or treatment sections usually support `benefits`
- employee-count or company overview size text usually supports `company_size`

## Search-language guidance

- Search with both Japanese and English keywords for each role family.
- Prefer Japanese search phrases first on domestic sites because English-only searches can under-retrieve listings.
- Do not treat English-professional roles as the default market slice.
- Keep Japanese titles when the listing is authored in Japanese; translation can go into `notes` only if it helps clarity.

## Output compatibility rules

- Always emit the same JSON schema no matter which site the job came from.
- Keep `source` as a human-readable site or company name such as `Green`, `Wantedly`, `Findy`, `Mynavi Tenshoku`, `En Tenshoku`, or `Official Careers`.
- Additional stable `source` labels can include `BizReach`, `LevTech Career`, `Workport`, `Geekly`, `Rikunabi NEXT`, `Mynavi IT Agent`, and `CareerCross`.
- Do not add site-specific fields to the final JSON.
- Preserve factual Japanese terminology in `notes` only when it cannot be cleanly normalized into the shared schema.
- If a domestic listing is information-rich but lacks a direct apply link, prefer the listing URL you verified and mention the limitation in `notes`.
