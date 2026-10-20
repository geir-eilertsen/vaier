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

The console keeps a sign-in of its own, separate from the one your published apps share, so no app ever receives a session that could open Vaier. You sign in once: whichever you sign in to first, opening the console or the Launchpad brings the other along in a redirect you don't see. **Sign out** ends both. An app that keeps working offline, such as openHAB, may ask for its own password once the apps' sign-in is gone; open Vaier once, or reload the app with Ctrl+Shift+R.

### The first-run password, before you have registered anything

A stack with **no provider configured** still starts, with one door for one account. Vaier prints the console URL, the email and the password at the bottom of its boot log:

```bash
docker compose logs vaier
```

Put `sudo` in front if your user is not in the `docker` group. The [installer](ADVANCED.md#the-installer) prints the same three lines for you when run at a terminal. Open the console and press **Sign in with the first-run password**. That first sign-in makes you the admin.

- The account's email is `VAIER_ADMIN_EMAIL` if set, otherwise `ACME_EMAIL`. The password is kept in `./vaier/config/first-run-password` (mode `0600`).
- **The door closes on its own** once an **admin signs in through a new provider** added from **People → Sign-in providers** (or at once, for one added through `.env`).
- **Handing over.** Sign in with Google or GitHub under the *same* email and you stay admin. For a different address, set `VAIER_ADMIN_EMAIL` to it first.

### Registering Google or GitHub

Configure Google, GitHub, both, or neither for now. The sign-in page shows a button per configured provider; with only one, sign-in goes straight there. Both send people back to Dex, so register this redirect URI:

- **Google** — an OAuth 2.0 Web application client in the [Google Cloud console](https://console.cloud.google.com/apis/credentials), redirect URI `https://dex.yourdomain.com/callback`.
- **GitHub** — an OAuth App in [GitHub developer settings](https://github.com/settings/developers), callback URL `https://dex.yourdomain.com/callback`. Any GitHub account may sign in; your approval decides who's let in.

Then give Vaier the client id and secret, one of two ways:

- **From People → Sign-in providers.** The section shows the redirect URI with a copy button, a link to each provider's console, and the id and secret fields. **Save** applies it in a few seconds; once set, it folds to one line with **Change**. If it fails, the working config stays and the error shows under the button. The secret is write-only and is stored in `./vaier/config/sign-in-providers.env` (mode `0600`).
- **From `.env`.** Set `VAIER_OIDC_GOOGLE_CLIENT_ID` / `VAIER_OIDC_GOOGLE_CLIENT_SECRET` and/or `VAIER_OIDC_GITHUB_CLIENT_ID` / `VAIER_OIDC_GITHUB_CLIENT_SECRET` and run `docker compose up -d`. **`.env` wins**: People then shows that provider read-only as *set in .env*.

`install.sh` generates the stack's own secrets into `.env` for you. Missing one? `docker compose` stops with a message naming it: re-run the installer in the `vaier` folder. It adds what is missing and never overwrites a value.

Once `docker compose ps` shows every service `Up`, open `https://vaier.yourdomain.com` and sign in with the new provider under the first-run account's email (see *Handing over* above), so you stay the admin. Anyone else lands as **pending** until you let them in from **People**.

A CrowdSec ban on your own address does not stop you signing in: the console is one of the [recovery doors](NETWORKING.md#the-recovery-doors), so you can reach the Security view and lift the block.

---

## Access management

Manage who can sign in from **People** in the navigation bar. Each identity — Google, GitHub or the first-run account — has a **role** (pending → user → admin) and free-form **access groups**. People has three parts:

- **Waiting to be let in** — shown only while someone waits: **Let in**, **Let in as admin**, **Turn away**.
- **Let in** — everyone with access, admins first, then users. The **…** menu offers **Make an admin** / **Make a user**, **Change groups** and **Remove access**. **Add a person** lets someone in before their first sign-in.
- **Sign-in providers** — Google and GitHub (above).

A first-time sign-in mails every admin (if SMTP is configured), at most once every ten minutes; a later mail says how many are waiting. At most 25 people wait at once — past that, a newcomer is turned back without being kept, so use **Add a person** for someone you expect. **Turn away** and **Remove access** stick: that person is kept out quietly — they never wait in People again and no admin is mailed when they try. To let them in later, use **Add a person** with their address.

- Admins reach everything; pending identities reach nothing.
- **Access groups** (e.g. `devs`, `family`) gate individual services.
- **Last-admin protection**: the only admin cannot be demoted or removed.

---

## Who can open a service

Each published service's page starts with **Who can open it**: *Anyone — no sign-in*, or *Only people who sign in to Vaier* (Google or GitHub sign-in, with Vaier deciding who's approved). Change it any time.

Either way, a published service never receives your Vaier sign-in: Vaier blanks it on the way in, so an app you don't fully trust cannot use it to reach the console. An app that keeps its own login is not affected.

## Per-service access rules

For a service behind sign-in, open its entry in the **Explorer** and use the **Allowed groups** chip picker. Empty means any approved user gets in. With groups set, only users holding at least one of them (plus admins) get in. Path-scoped services sharing one subdomain share one rule.

## Service credentials

Some services keep a login of their own behind social login — openHAB's API, say. A **service credential** is a username and password Vaier hands the service for every person it lets in. In the **Explorer**, open the published service and fill in **The login Vaier gives it** under **Sign people in for it**. It needs *Only people who sign in to Vaier* under **Who can open it**. It also needs an address of its own: on an address shared by more than one service behind social login, a login would reach every one of them, so Vaier will not set or send it. Publishing a second signed-in service on an address that already has a login is refused; if an address ends up shared anyway, the service page marks its login **Paused** until one of them moves. Unpublishing a service drops the logins set on its address.

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

A service open to *Anyone* whose own sign-in reads as **none** is an **open service**: anyone who finds the name can use it. Vaier mails admins about each one **once**. In the service's pane, **Put Vaier's sign-in in front** puts it behind sign-in; **This is meant to be public** silences it.
