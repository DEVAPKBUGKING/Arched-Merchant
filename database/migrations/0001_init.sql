-- 0001_init.sql
-- FONDASI LEDGER — jangan ubah tanpa alasan kuat.
-- Semua saldo dihitung dari tabel ledger_entries. Tidak ada field saldo yang bisa diedit.

create extension if not exists "pgcrypto";

-- ============ MERCHANTS ============
create table if not exists merchants (
  id              uuid primary key default gen_random_uuid(),
  auth_user_id    uuid not null unique references auth.users(id) on delete cascade,
  email           text not null,
  phone           text,
  display_name    text not null,
  status          text not null default 'pending'
                  check (status in ('pending','active','suspended','rejected')),
  kyc_verified_at timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ============ LEDGER (DOUBLE-ENTRY) ============
-- Setiap transaksi punya minimal 2 baris: debit + kredit.
-- Saldo merchant = sum(credit) - sum(debit) untuk account_type yang relevan.
create table if not exists ledger_accounts (
  id           uuid primary key default gen_random_uuid(),
  merchant_id  uuid not null references merchants(id) on delete cascade,
  account_type text not null
               check (account_type in ('available','pending','fee','adjustment')),
  currency     text not null default 'IDR',
  created_at   timestamptz not null default now(),
  unique (merchant_id, account_type, currency)
);

create table if not exists ledger_transactions (
  id            uuid primary key default gen_random_uuid(),
  reference     text not null unique,
  kind          text not null
                check (kind in ('payment','payout','fee','refund','adjustment')),
  status        text not null default 'pending'
                check (status in ('pending','posted','reversed')),
  idempotency_key text unique,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  posted_at     timestamptz
);

create table if not exists ledger_entries (
  id             uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references ledger_transactions(id) on delete cascade,
  account_id     uuid not null references ledger_accounts(id) on delete restrict,
  direction      text not null check (direction in ('debit','credit')),
  amount_minor   bigint not null check (amount_minor > 0),
  created_at     timestamptz not null default now()
);

create index if not exists idx_ledger_entries_account on ledger_entries(account_id);
create index if not exists idx_ledger_entries_tx on ledger_entries(transaction_id);

-- ============ AUDIT LOG ============
create table if not exists audit_log (
  id          bigserial primary key,
  actor_id    uuid,
  action      text not null,
  target      text,
  payload     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

-- ============ UPDATED_AT TRIGGER ============
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_merchants_updated_at on merchants;
create trigger trg_merchants_updated_at
before update on merchants
for each row execute function set_updated_at();
