# Search Templates

Use these templates when querying Japanese domestic job boards, company career pages, or the web tool. Mix Japanese and English variants instead of relying on one language.

## Frontend

- `site:<domain> フロントエンドエンジニア 東京`
- `site:<domain> フロントエンド リモート`
- `site:<domain> Webエンジニア React`
- `site:<domain> frontend engineer Japan`
- `site:<domain> react engineer tokyo`
- `site:<domain> web ui engineer japan`

## Backend

- `site:<domain> バックエンドエンジニア 東京`
- `site:<domain> サーバーサイドエンジニア リモート`
- `site:<domain> バックエンド Go Python Java`
- `site:<domain> backend engineer Japan`
- `site:<domain> server-side engineer tokyo`
- `site:<domain> platform engineer japan`

## QA / Test

- `site:<domain> QAエンジニア 東京`
- `site:<domain> テストエンジニア リモート`
- `site:<domain> 品質保証 自動テスト`
- `site:<domain> qa engineer Japan`
- `site:<domain> test engineer tokyo`
- `site:<domain> sdet japan`

## Querying guidance

- Replace `<domain>` with a target domestic source such as `green-japan.com`, `wantedly.com`, `forkwell.com`, `yourust.jp`, `paiza.jp`, `findy-code.io`, `type.jp`, `doda.jp`, `tenshoku.mynavi.jp`, `employment.en-japan.com`, `bizreach.jp`, `career.levtech.jp`, `workport.co.jp`, `geekly.co.jp`, `rikunabi-next.yahoo.co.jp`, `mynavi-agent.jp`, or `careercross.com`.
- Run Japanese queries first on domestic sites.
- If a site returns weak or sparse results in English, do not interpret that as lack of jobs; retry with Japanese titles and Japanese role nouns.
- When broad role queries return too many weak matches, add city, stack, or employment-type constraints before switching sites.

## ASCII-safe templates

Use these when terminal encoding makes Japanese characters hard to read:

- frontend: `site:<domain> furontoendo enjinia tokyo`, `site:<domain> furontoendo remote`, `site:<domain> web engineer react`
- backend: `site:<domain> bakkuendo enjinia tokyo`, `site:<domain> saba saido enjinia remote`, `site:<domain> bakkuendo Go Python Java`
- qa/test: `site:<domain> QA enjinia tokyo`, `site:<domain> tesuto enjinia remote`, `site:<domain> hinshitsu hosho jido tesuto`

## Direct harvest entry points

Use these when the site has strong role-family landing pages and you want to scale coverage quickly without relying on broad search results first:

- Forkwell frontend: `https://jobs.forkwell.com/professions/front-end-engineer`
- Forkwell backend: `https://jobs.forkwell.com/professions/server-side-engineer`
- Forkwell QA: `https://jobs.forkwell.com/professions/qa-engineer`

Workflow:

- open the role-family page directly
- capture the top active rows with clear stack, salary, and remote metadata
- click through to the job detail page for the canonical `url`
- use the landing page and detail page together when one page has richer metadata than the other

## Source-specific keep/drop rules

- Green: keep direct `company/.../job/...` pages and prefer rows with explicit compensation or stack fields in the search snippet.
- Wantedly: keep only pages that still show an active outreach CTA such as `話を聞きに行きたい`; skip rows marked as closed.
- Forkwell Jobs: treat the role-family or listing page as discovery only; always click into the detail page and store that detail URL as the final `url`.
