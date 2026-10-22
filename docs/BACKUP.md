# Fleet backup

Back to [README](../README.md).

**Tick what matters. Vaier does the rest.** That is the only path you need to learn. Everything after the first section is reference, for adopting existing borg setups or recovering by hand.

![A machine's Backups page: what is protected, what is not, and how the last run went](vaier-backup.jpg)

## Tick what matters

Open a machine's files in the **Explorer**, tick the folders you would want back if the machine died, and press **Back up**. That is your one decision. **Back up** appears once the fleet has a [backup server](#backup-server) and Vaier can sign in to the machine. Vaier does the rest:

- creates a repository for the machine on the backup server, with a generated passphrase;
- prepares the machine on its first backup (trusts its key, installs the client);
- runs every night;
- emails the admins only when a run fails or came back with holes.

**Back up more** takes you back to the files. **Stop backing up** removes a path; when the last one goes, the machine's job goes too. Archives already made are kept, and its time rail still browses them. Deleting a backed-up folder in the Explorer stops backing it up too; restoring it from the time rail puts it back under backup with the settings it had, and the finished transfer says **Backed up again**. Vaier remembers this only until it restarts. A backed-up folder deleted some other way shows up under **Needs you** after the next run, with **Stop backing it up**.

A machine you never want backed up can say so: **That's on purpose** on its "Back up" suggestion stops Vaier asking. Its page then reads "Not backed up — on purpose", with **Back it up after all**; backing it up later clears the mark by itself.

The archives are [borg](https://www.borgbackup.org/) repositories on the fleet's **backup server**, one per machine. The passphrases live in Vaier and in the **survival kit**.

---

## Backup server

The fleet has **at most one**. While it has none, every server and NAS in the **Explorer** suggests itself under **What to do next**: "Make ‹name› the backup server", with **Set it up**. A machine of another kind gets the suggestion once you change its device category (**Edit details**) to server or NAS. The fleet's **Needs you** list says "Nothing in your fleet is backed up", with **Set it up** when the fleet has a NAS. Vaier looks first and says what it will do in one sentence: use the borg server it found there, or set up a **pinned** borg-server container on the local disk with the most room. Press **Use it** or **Set it up**; **Change details** opens the coordinates form. When Vaier cannot see what runs on the machine, it asks one thing: the folder to keep backups in, suggested on the roomiest disk it can read. **Set it up** puts a backup server there. Already run a borg server on it? Open **Already running a backup server there?**, give its address and press **Use that server**.

The server's `backup` entry has **Server details** and, under the fold *Provision, authorize or remove this backup server*: **Provision**, **Authorize a machine**, **Setup script**, **Edit coordinates**, **Remove designation**.

- Where Vaier can't drive docker over SSH (a Synology NAS, say), it stages **setup.sh** on the host and hands you one command: `sudo bash <path>`. Where Vaier can sign in there, **Run it in ‹machine›'s shell** opens its shell with the command typed: press Enter, and **Send password** if sudo asks. If it can't reach the host, download setup.sh from the UI.
- If the backup server goes quiet, Vaier emails every admin, and again when it recovers.

**Authorize a machine** trusts a machine's SSH key on the server. The key is confined to that machine's own repositories, so one compromised machine can't touch another's archives. It also pins the server's host key on the machine.

**Adding a repository for a machine means re-authorizing that host**; until then, backups to it are refused.

---

## Backup repository

You never create one by hand: **Back up** makes one per machine. Each is an entry under the backup server's `backup` entry, showing its path, stored passphrase and archives. **Forget these backups** is offered once no machine backs up there. It takes them off the list and the time rail and erases nothing: Vaier keeps their passphrase in the survival kit, and backing the machine up again picks them up where they left off.

- A name may hold only letters, digits, `_` and `-`; "NUC 02" becomes `NUC-02`.
- Vaier generates each passphrase and keeps it in the survival kit; it can't be changed afterwards.

When a run fails because borg is missing, the machine's `backup` entry and **Needs you** offer **Get this machine ready**. It installs borg and grants the SSH user **passwordless sudo for the borg binary alone**, which **as root** jobs need. Where Vaier can't gain root, it hands you a `sudo bash <path>` command, with **Run it in ‹machine›'s shell** to type it there for you.

Vaier works from a folder in the SSH user's home. A machine whose home it can't read, or whose home path holds a space or other unusual characters, can't be backed up until that is fixed; its runs fail saying so.

---

## Backup jobs

Each machine has one job: repository, source paths, excludes, retention (`keepDaily` / `keepWeekly` / `keepMonthly`), compression (default `zstd,6`), enabled, and **as root**. It lives on the machine's `backup` entry in the **Explorer**. **Tick what matters** maintains it for you.

### Back up as root

borg runs as the SSH user, so **files that user cannot read are skipped**. Container volumes are the usual victims.

**You are asked only when it has cost you something.** Such a run settles **incomplete**, emails the admins, and **Needs you** shows *‹machine›'s last backup is missing N files*, with **Back up as root**. One click installs the grant and turns the setting on; the row then offers **Back up now**, so the holes fill today rather than tonight. Where Vaier can't gain root, it hands you a `sudo bash <path>` command.

To turn it back **off**, open the **Back up as root** fold on the `backup` entry and untick it.

**A passwordless `sudo borg` is root-equivalent.** Turning it on makes Vaier's SSH credential for that machine as powerful as root. Grant it only where that is acceptable.

### Running

Press **Back up now** on the machine's `backup` entry, or let the **nightly schedule** run every enabled job. Set its hour (default 2) in **Settings**. A night whose hour was missed — Vaier was down, or the clocks went forward — runs later that day. A machine runs one backup at a time.

Each **backup run** ends as success, warnings, **incomplete**, failed, or unknown.

- **Incomplete** — some source files couldn't be read. The archive has holes, so this counts as a **failure**: red in the Explorer and a *Backup incomplete* mail naming the lost files.
- **Warnings** — borg grumbled but lost nothing (a file changed while read). Not a failure; no mail.
- **Failed** — including a run that never started (no SSH access, no credential, no borg, its backup storage gone). Emails every admin once, and again when the job recovers. A machine that is merely off or asleep at backup time is mailed, and shown in **Needs you**, only once it has gone a day and a half without a good backup.
- **Unknown** — the run ended without a result, usually because the machine restarted, or Vaier lost touch with the machine mid-run and still couldn't reach it 12 hours after it last saw the run going. One unknown night isn't mailed; a machine that has gone **a day and a half without a good backup** is mailed like a failure and shown in **Needs you**.

Once a week, between nightly runs, Vaier has borg read each repository back on the backup server, for at most half an hour at a time; a large repository is covered over several weeks. It emails the admins only when a check finds damage, once. While a check runs, **Back up now** on that machine says so and asks you to try again later.

A run that didn't end cleanly shows its **run diagnostics**: the lines borg reported, such as `Permission denied`.

Each machine keeps its borg passphrase file and run logs in `~/.vaier-backup`. After every run Vaier clears out logs older than a week and the passphrase files of backups it no longer keeps. Starting a run closes any archive you had open on that machine, since borg needs the repository to itself. A restore or zip from the past that is still running is never cut off: the backup waits and is retried later that night, and **Back up now** says so.

A machine [switched off on purpose](EXPLORER.md#switched-off-on-purpose) is **skipped, not failed**: no run, no red mark, no mail. A machine that is merely off or unreachable at the scheduled hour fails that run, and Vaier keeps trying it every 15 minutes for the rest of the day.

### Archives

Open a **backup repository** entry to list its archives. To restore, open an archive with the Explorer's time rail and copy files out of it (see [`docs/EXPLORER.md`](EXPLORER.md)).

**A dead or removed machine's archives** stay reachable once the survival kit is written. A machine Vaier can't reach keeps its time rail; a machine you removed is opened from its entry under the backup server: click an archive. Copy what you need onto a replacement machine; the paste asks before replacing anything there. Caveats:

- The machine that reads it needs the backup program and a way to the backup server, so it is the backup server's machine or one that backs up. Vaier tries up to three in turn.
- A backup run of the machine closes any archive of it that is open elsewhere.

---

## Survival kit

Your repository passphrases live inside Vaier, and Vaier's own backup is encrypted with one of them. Lose the Vaier server and nothing left can open your archives.

The **survival kit** fixes that: every repository's address and passphrase, the borg commands to read them, a **recovery key** that opens the backup server, and Vaier's **config key**, encrypted under **one passphrase you choose** (at least 16 characters, since copies sit on your machines). Set it in **Settings → Survival kit** and press **Write the kit now**.

- **Vaier picks the hosts and says why**: reachable servers, never itself, spread across sites. It tells you whether anything written now outlives this server.
- Each copy is `vaier-survival-kit.txt` (`0600`) in the SSH user's home.
- **Opening it needs no Vaier**: the `openssl enc -aes-256-cbc -pbkdf2 -d` command is printed at the top of every copy, with its date.
- **The recovery key** is Vaier's own key on the backup server. It can read every repository, and add archives, but never delete one. If Vaier could not place it there, the kit says so and gives the line to add by hand. Vaier uses it too: when a machine can't be reached or is gone, the backup server's machine or another machine that backs up reads its archives instead, for listing, browsing and restoring in Files. That machine keeps no copy of the key: it is wiped as soon as the listing ends or the archive is open.
- **Vaier keeps them current itself**: a new repository, passphrase, job or machine name rewrites every copy, as does changing the kit passphrase.

---

## Rebuilding Vaier after losing its server

This works only if Vaier backed up its own folder (tick it in the Explorer like any other) and you wrote the survival kit. Rehearse it once on a spare box before you need it.

1. **Open the kit** on any copy with the `openssl` command at its top. It names the backup server and the Vaier server's repository, with its passphrase.
2. **Reach the backup server.** Its address is usually on a home LAN, so work from a machine there; the tunnels went with the server. Save the kit's **recovery key** as `vaier-recovery-key` and `chmod 600` it.
3. **Extract the folder** as root, so owners and modes survive:
   ```bash
   export BORG_PASSPHRASE='the passphrase from the kit' BORG_RSH="ssh -i $PWD/vaier-recovery-key"
   sudo -E borg list 'the repository from the kit'
   sudo -E borg extract 'the repository from the kit'::ARCHIVE home/<user>/vaier
   sudo tar -czpf vaier.tgz home/<user>/vaier
   ```
4. **Start it on the new server.** Install Docker (`curl -fsSL https://get.docker.com | sudo sh`), copy `vaier.tgz` over, then:
   ```bash
   sudo tar -xzpf vaier.tgz -C / && cd ~/vaier && docker compose pull && docker compose up -d
   ```
   Keep the same user and path, or move the folder and keep its owners: Vaier's files must stay owned by uid 1000.
5. **Give it the old public address** if you can. On a new one, change your `*.<domain>` record. Servers find the new address by themselves within a few minutes. Phones, laptops and any machine whose setup is out of date keep the address they first looked up: restart their tunnel, or power-cycle one you can't reach.

The restored folder carries Vaier's own key. If `vaier/config/vault.key` is missing, put the kit's **config key** there (`0600`, owned by uid 1000), or set it as `VAIER_VAULT_KEY` in `.env` and run `docker compose up -d`; without it every stored password and passphrase stays unreadable.
