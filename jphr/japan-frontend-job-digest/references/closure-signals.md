# Closure Signals

Use this reference when deciding whether a listing is still hiring.

## Closed signals

Treat the role as `hiring_status: closed` only when the page explicitly shows signals like:

- English: `closed`, `expired`, `position filled`, `filled`, `no longer hiring`, `applications closed`, `no longer accepting applications`
- English full-sentence examples: `This job is no longer available.`, `This position is closed and is no longer accepting applications.`
- Japanese: `募集終了`, `掲載終了`, `応募終了`, `受付終了`, `採用終了`, `充足`, `募集を終了`, `現在募集しておりません`, `応募受付を終了`

When possible, preserve the exact phrase in `status_reason`.

## Open signals

Treat the role as `hiring_status: open` when the page explicitly shows signals like:

- English: `open`, `active`, `hiring`, `recruiting`, `accepting applications`, `available`
- Japanese: `募集中`, `採用中`, `応募受付中`, `エントリー受付中`, `積極採用中`

## Unknown signals

- If the page does not clearly indicate open or closed, use `hiring_status: unknown`.
- If a later crawl simply fails to find the page or the scraper misses it, do not convert that into `closed`.

## Site-specific hints

- `Wantedly`: treat `募集終了しました`, `Wantedlyでの募集は終了しました`, or a visible `募集終了` badge/button as `closed`. Treat `話を聞きに行きたい` or a visible active-contact CTA as evidence for `open`.
- `Green`: treat `募集終了` in the title or listing header as `closed`. The Green support docs also describe ended listings as `クローズ`.
- For other sites, prefer explicit page text over assumptions. If the listing is missing but the site offers no explicit closure wording, keep `hiring_status: unknown`.

## Additional site hints

- `doda`: treat `DodaFront/View/EndJobDetail` pages, `過去求人情報`, or `募集が終了した求人` as `closed`.
- `paiza`: treat `この求人の募集は終了しています` as `closed`.
- `Forkwell Jobs`: treat `募集終了求人` or a confirmed `募集を終了する` or `募集終了` state as `closed`.
- `Findy`: if the page shows an active entry or interest CTA, that can support `open`. If the role simply disappears from search or a company job list without an explicit closure phrase, keep `unknown`.

## Additional open hints

- `Wantedly`: a visible `話を聞きに行きたい` button, `今すぐ一緒に働きたい`, or `エントリー済み` after interaction is consistent with an active listing.
- `doda`: a visible blue `応募する` button on a job page is evidence for `open`.
- `paiza`: an active listing often includes `応募要件` and an application flow with `カジュアル面談` or interview steps. If the page instead explicitly says the role has ended, prefer `closed`.
- `Forkwell Jobs`: visible `話を聞きたい` or `応募` entry actions support `open`.
- `Findy`: `いいかも`, `カジュアル面談`, or a visible entry CTA can support `open`.
