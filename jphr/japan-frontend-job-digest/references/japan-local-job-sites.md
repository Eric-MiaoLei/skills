# Japan Local Job Sites

Use this reference when collecting frontend jobs from Japanese domestic marketplaces before falling back to expat-focused boards.

## Preferred domestic sites

- `Green`: broad Japanese web and product hiring, often includes detailed stack, benefits, and company profile fields.
- `Wantedly`: strong startup and product-company coverage; useful for culture, mission, team details, and casual hiring pipelines.
- `Forkwell Jobs`: engineer-focused listings with clearer technical expectations than generalist boards.
- `YOUTRUST`: startup and referral-heavy hiring; useful for modern product teams and informal role descriptions.
- `paiza転職`: engineering-oriented listings with concrete skill and requirement sections.
- `Findy`: developer-focused marketplace with frequent frontend and product-engineering openings.
- `type`: mainstream Japanese hiring site with useful filters for web engineer roles.
- `doda`: large domestic board with broad coverage and structured requirement sections.
- `マイナビ転職`: mainstream domestic board, useful when startup-focused sites are thin.
- `エン転職`: another broad domestic board with structured company and requirement information.

## Source priority

Use this order when the same role appears in multiple places:

1. Official employer career page
2. Information-rich Japanese domestic listing
3. Japan-focused international board such as TokyoDev or JapanDev
4. Large aggregator or repost

## Extraction hints for Japanese listings

- `仕事内容`: usually supports `summary`
- `必須条件`, `応募資格`, `必須スキル`: usually supports `experience_requirements` or `other_requirements`
- `歓迎条件`, `歓迎スキル`: usually supports `other_requirements`
- `学歴`, `学歴不問`: supports `education_requirements`
- `給与`, `想定年収`: supports `salary`
- `勤務地`: supports `location`
- `勤務形態`, `リモート`, `在宅`: supports `work_mode`
- `福利厚生`, `待遇`: supports `benefits`
- `従業員数`, `社員数`, company overview size text: supports `company_size`

## Output compatibility rules

- Always emit the same JSON schema no matter which site the job came from.
- Keep `source` as a human-readable site or company name such as `Green`, `Wantedly`, `Findy`, or `Official Careers`.
- Do not add site-specific fields to the final JSON.
- Preserve factual Japanese terminology in `notes` only when it cannot be cleanly normalized into the shared schema.
- If a domestic listing is information-rich but lacks a direct apply link, prefer the listing URL you verified and mention the limitation in `notes`.
