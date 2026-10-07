# Authentication and access

Back to [README](../README.md).

How sign-in is set up, how roles and per-service access rules work, and how **People** manages identities.

![Vaier's sign-in page, offering Google and GitHub](vaier-signin.jpg)

---

## Setting up sign-in

Vaier lets Google and/or GitHub prove who you are — or, until you register either, a **first-run password** of its own. Vaier itself decides who gets in.

```
Traefik → oauth2-proxy → Dex ─┬→ Google
                              ├→ GitHub
                              └→ local (the first-run password, while no provider exists)
```

### The first-run password, before you have registered anything

A stack with **no provider configured** still starts, with one door for one account. Vaier prints the console URL, the email and the password at the bottom of its boot log:

```bash
docker compose logs vaier
```

The [installer](ADVANCED.md#the-installer) prints the same three lines for you when run at a terminal. Open the console and press **Sign in with the first-run password**. That first sign-in makes you the admin.

- The account's email is `VAIER_ADMIN_EMAIL` if set, otherwise `ACME_EMAIL`. The password is kept in `./vaier/config/first-run-password` (mode `0600`).
- **The door closes on its own** once an **admin signs in through a new provider** added from **People → Sign-in providers** (or at once, for one added through `.env`).
- **Handing over.** Sign in with Google or GitHub under the *same* email and you stay admin. For a different address, set `VAIER_ADMIN_EMAIL` to it first.

### Registering Google or GitHub

Configure Google, GitHub, both, or neither for now. The sign-in page shows a button per configured provider; with only one, sign-in goes straight there. Both send people back to Dex, so register this redirect URI:

- **Google** — an OAuth 2.0 Web application client in the [Google Cloud console](https://console.cloud.google.com/apis/credentials), redirect URI `https://dex.yourdomain.com/callback`.
- **GitHub** — an OAuth App in [GitHub developer settings](https://github.com/settings/developers), callback URL `https://dex.yourdomain.com/callback`. Any GitHub account may sign in; your approval decides who's let in.

Then give Vaier the client id and secret, one of two ways:

- **From People → Sign-in providers.** The section shows the redirect URI with a copy button, a link to each provider's console, and the id and secret fields. **Save** applies it in a few seconds. If it fails, the working config stays and the error shows under the button. The secret is write-only and is stored in `./vaier/config/sign-in-providers.env` (mode `0600`).
- **From `.env`.** Set `VAIER_OIDC_GOOGLE_CLIENT_ID` / `VAIER_OIDC_GOOGLE_CLIENT_SECRET` and/or `VAIER_OIDC_GITHUB_CLIENT_ID` / `VAIER_OIDC_GITHUB_CLIENT_SECRET` and run `docker compose up -d`. **`.env` wins**: People then shows that provider read-only as *set in .env*.

`install.sh` generates three secrets into `.env` for you: `VAIER_OAUTH2_COOKIE_SECRET`, `VAIER_DEX_CLIENT_SECRET` and `VAIER_CROWDSEC_BOUNCER_KEY`. If you hand-write `.env`, generate all three — a missing one stops `docker compose` with a message naming it. Re-running `install.sh` in place is simpler: it tops up what is missing and never overwrites a value.

```bash
printf 'VAIER_DEX_CLIENT_SECRET=%s\nVAIER_OAUTH2_COOKIE_SECRET=%s\nVAIER_CROWDSEC_BOUNCER_KEY=%s\n' \
  "$(openssl rand -hex 32)" "$(openssl rand -base64 32 | tr '+/' '-_')" "$(openssl rand -hex 32)" >> .env
```

Once `docker compose ps` shows every service `Up`, open `https://vaier.yourdomain.com` and sign in as `VAIER_ADMIN_EMAIL`, who becomes the first admin. Anyone else lands as **pending** until you let them in from **People**.

A CrowdSec ban on your own address does not stop you signing in: the console is one of the [recovery doors](NETWORKING.md#the-recovery-doors), so you can reach the Security view and lift the block.

---

## Access management

Manage who can sign in from **People** in the Vaier menu. Each identity — Google, GitHub or the first-run account — has a **role** (pending → user → admin) and free-form **access groups**. People has three parts:

- **Waiting to be let in** — shown only while someone waits: **Let in**, **Let in as admin**, **Turn away**.
- **People** — admins first, then users. The **…** menu offers **Make an admin** / **Make a user**, **Change groups** and **Remove access**. **Add a person** lets someone in before their first sign-in.
- **Sign-in providers** — Google and GitHub (above).

A first-time sign-in mails every admin (if SMTP is configured).

- Admins reach everything; pending identities reach nothing.
- **Access groups** (e.g. `devs`, `family`) gate individual services.
- **Last-admin protection**: the only admin cannot be demoted or removed.

---

## Per-service auth mode

Each published service card has an **auth mode** picker: **Public** (no sign-in) or **Social** (Google or GitHub sign-in, with Vaier deciding who's approved). Change it any time.

## Per-service access rules

For a **Social** service, open its entry in the **Explorer** and use the **Allowed groups** chip picker. Empty means any approved user gets in. With groups set, only users holding at least one of them (plus admins) get in, and the service shows a **restricted** badge. Path-scoped services sharing one subdomain share one rule.

## Service credentials

Some services keep a login of their own behind social login — openHAB's API, say. A **service credential** is a username and password Vaier hands the service for every person it lets in. In the **Explorer**, open the published service and fill in **The login Vaier gives it** under **Sign people in for it**. It needs Social auth mode (*Only people who sign in to Vaier* under **Who can open it**).

- **Shared** — for everyone without their own; all of them are one user to the service.
- **Personal** — for one person, so the service can tell them apart.
- **Marvin's** — pick **Marvin** in the same list. Only for Marvin's calls, never handed to a browser. Without it, Marvin cannot use the service at all; writes always wait for your yes (see [Chat](CHAT.md#a-published-services-own-api)).

**openHAB** needs **Settings → API Security → Allow Basic Authentication**. If signing in loops, check the username and password.

Credentials live in `./vaier/config/service-credentials.yml` (mode `0600`), passwords encrypted and write-only.

## What a service asks for by itself

Vaier checks each published service's own sign-in and the service pane says what to do about it: **Basic auth** (a service credential can answer it), **another challenge** (Vaier cannot sign in for people), **its own sign-in page**, **none**, or **unknown** — never read as none.

**OpenSprinkler**: the pane suggests turning on **Ignore password** in the controller's options.

**phpMyAdmin**: switch it to basic auth — drop `PMA_ARBITRARY`, keep `PMA_HOST`, and mount a `config.user.inc.php` in `/etc/phpmyadmin/` holding `$cfg['Servers'][1]['auth_type'] = 'http';`. A database login under **Sign people in for it** then signs people straight in.

## Open services

A **Public** service whose own sign-in reads as **none** is an **open service**: anyone who finds the name can use it. Vaier mails admins about each one **once**. In the service's pane, **Put Vaier's sign-in in front** switches it to Social; **This is meant to be public** silences it.
