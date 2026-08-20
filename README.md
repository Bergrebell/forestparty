# forestparty

Die alte [Forestparty Fribourg](https://forestparty.ch)-Seite (statischer
HTML-Export von ~2013), wiederbelebt und auf dem planet10-X1 via **Kamal**
deployt — gleiches Muster wie `atelier_zukunft`: Kamal baut ein schlankes
nginx-Image aus dem [Dockerfile](Dockerfile), kamal-proxy routet per
Host-Header, nginx auf dem Pi terminiert TLS.

- **Inhalt:** die HTML-Dateien im Repo-Root plus `images/`,
  `images_slideshow/` und `Spry-UI-1.7/` (~51 MB, wandern verbatim ins Image)
- **Laeuft auf:** X1 `51.154.22.115`, hinter dem gemeinsamen kamal-proxy (Port 80)
- **URL (Staging):** https://forestparty.planet10.ch — die Originaldomains
  (forestparty.ch, www.forestparty.ch) uebernehmen, sobald deren DNS hierher
  zeigt; siehe [Notizen](#notizen).
- **Keine Secrets:** nichts in 1Password, kein `.kamal/secrets` — es gibt nichts zu konfigurieren

## Voraussetzungen

- Kamal lokal installiert (`gem install kamal`), Docker laeuft.
- SSH-Zugang zum X1 als `serverman`.
- DNS: `forestparty.planet10.ch` → Router.

Kamal wird als blankes `kamal` aufgerufen (kein `bin/kamal`-Binstub — hier gibt
es weder Rails noch Bundler).

## Erster Deploy

```bash
cd ~/Projects/11_forestparty

# 1. Image bauen, pushen, Container hinter kamal-proxy hochfahren
kamal deploy

# 2. Auf dem Pi: nginx-vhost + HTTPS-Zertifikat anlegen (einmal pro Host).
#    Kein Upstream-Argument — der Default ist der kamal-proxy des X1,
#    der per Host-Header routet.
sudo ~/add-site.sh forestparty.planet10.ch
```

Fehlt das Skript auf dem Pi, liegt eine Kopie in
[deploy/nginx/add-site.sh](deploy/nginx/add-site.sh).

## Seite aktualisieren

HTML/Bilder aendern, committen, dann:

```bash
kamal deploy
```

Kamal baut aus einem sauberen Git-Clone, **uncommittete Aenderungen werden
also nicht deployt** — vorher committen.

## Weitere Operationen

```bash
kamal app logs -f                            # nginx-Logs (Alias: kamal logs)
kamal app exec --interactive --reuse "sh"    # Shell im Container (Alias: kamal shell)
kamal rollback <version>                     # aeltere Images bleiben auf dem X1
```

## Notizen

- Der Container liefert Klartext-HTTP auf Port 80; `proxy.ssl: false` in
  [config/deploy.yml](config/deploy.yml), weil TLS auf dem Pi liegt.
- kamal-proxy health-checkt `GET /up` (direkt von [nginx.conf](nginx.conf)
  beantwortet), bevor es Traffic auf einen neuen Container schwenkt.
- `try_files $uri $uri.html` — endungslose URLs wie `/faq` funktionieren
  zusaetzlich zu `/faq.html`.
- Caching: Bildarchiv 30 Tage, Spry-UI-Assets 1 Stunde, HTML/CSS `no-cache`,
  damit ein Deploy sofort sichtbar ist.
- **Beim Wiederbeleben entfernt** (alles tot und teils HTTPS-blockierend):
  Universal Analytics `UA-40680325-1` (Google hat UA 2023 abgeschaltet), das
  alte Facebook-JS-SDK `all.js` samt leerer Like-Box (ersetzt durch einen
  schlichten Link auf die FB-Seite) und `http://use.edgefonts.net/lobster.js`
  (Adobe Edge Web Fonts abgeschaltet, und `http://` waere auf einer
  HTTPS-Seite als Mixed Content blockiert worden). Die Lobster-Schrift kommt
  jetzt von Google Fonts — `check_cs6.css` bleibt dafuer unveraendert.
- Live-Schaltung: `proxy.hosts` in [config/deploy.yml](config/deploy.yml) um
  `forestparty.ch` + `www.forestparty.ch` ergaenzen, neu deployen und
  `add-site.sh` auf dem Pi je Domain laufen lassen.
