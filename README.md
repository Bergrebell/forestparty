# forestparty

Die alte [Forestparty Fribourg](https://forestparty.ch)-Seite (statischer
HTML-Export von ~2013), wiederbelebt und auf dem planet10-X1 deployt.

## Domain

| | |
|---|---|
| **Staging** | https://forestparty.planet10.ch |
| **Live (spaeter)** | forestparty.ch + www.forestparty.ch |

Konfiguriert unter `proxy.hosts` in [config/deploy.yml](config/deploy.yml).
Zum Live-Schalten die Originaldomains dort ergaenzen, neu deployen und
`add-site.sh` auf dem Pi je Domain laufen lassen.

## Deployment

Kamal baut aus dem [Dockerfile](Dockerfile) ein nginx-Image mit dem
Seiteninhalt, kamal-proxy auf dem X1 (`51.154.22.115`) routet per Host-Header,
nginx auf dem Raspberry Pi terminiert TLS. Keine Secrets, kein
`.kamal/secrets` — es gibt nichts zu konfigurieren.

```bash
kamal deploy
```

Kamal wird als blankes `kamal` aufgerufen (kein `bin/kamal` — hier gibt es
weder Rails noch Bundler). **Kamal baut aus einem sauberen Git-Clone,
uncommittete Aenderungen werden also nicht deployt.**

Einmalig pro Domain, auf dem Pi (legt nginx-vhost + Let's-Encrypt-Zertifikat
an; braucht einen DNS-A-Record auf `51.154.22.115`):

```bash
sudo ~/add-site.sh forestparty.planet10.ch
```

Kopie des Skripts: [deploy/nginx/add-site.sh](deploy/nginx/add-site.sh).

```bash
kamal app logs -f                             # nginx-Logs
kamal app exec --interactive --reuse "sh"     # Shell im Container
kamal rollback <version>                      # aeltere Images bleiben auf dem X1
```

## Inhalt

Die HTML-Dateien im Repo-Root plus `images/`, `images_slideshow/` und
`Spry-UI-1.7/` — wandern verbatim ins Image. Seite aendern, committen,
`kamal deploy`.

Beim Wiederbeleben entfernt, weil tot und teils HTTPS-blockierend: Universal
Analytics, das alte Facebook-JS-SDK und `http://use.edgefonts.net/lobster.js`
(Adobe Edge Web Fonts abgeschaltet). Lobster kommt jetzt von Google Fonts,
`check_cs6.css` blieb dadurch unveraendert.
