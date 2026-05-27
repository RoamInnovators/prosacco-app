# Old Version Mobile App — Screen Audit (May 2026)

## Fully API-wired
- Auth: launch, sign-in, OTP, password reset (`app_bootstrap`, `member_*_screen`)
- Home: summary, recent transactions, notifications (`member_home_screen`)
- Accounts: overview, deposit, withdraw, transfers, buy shares (`member_accounts_screen`, `accounts/*`)
- Loans: catalog, applications, apply, guarantor inbox (`loans/*`)
- Statements: account pick, generate, email request, transactions (`statements/*`)
- Profile: security hub, edit, password, devices, KYC, beneficiaries, notifications (`profile/*`)

## Intentionally limited (no backend route yet)
- **Airtime** — real account picker; purchase shows unavailable (no `/member/bills/airtime`)
- **Pay scan** — QR capture only; payments not enabled
- **Agent withdrawal** — channel shows “Coming soon”
- **Home** — announcement/search stubs until announcements API is wired in app

## Removed / replaced mock data
- `kMemberAccountOptions`, `kKenyanBanks`, statement sample generators
- Account carousel fallback slides with fake balances
- Statement hub “sample data” label and estimated-only flows (now uses `generateStatement` for current month)

## Global UX
- **Balance visibility**: one eye icon toggles all balances app-wide (`BalanceVisibilityController`)
- **Account card colors**: BOSA / FOSA / Shares / FD / SS distinct gradients (`AccountCardPalette`)
