# Pozadine, vizuelni manifest i sat animacije — 3. novembar 2026.

Implementirano na grani `codex/rope-rendering-platform-markers`.

## Pozadine i parallax

`CaveBackdrop.addLayer` sada proporcionalno skalira teksturu prema širini prikaza. Zadržana je cela širina ilustracije, uključujući bočne obale; ponavljanje popunjava visinu. Broj kopija zavisi od veličine prikaza i wrap perioda. Više nema nezavisnog razvlačenja širine i visine.

`update` koristi period od dve visine za naizmenično preslikanu pećinu Depths, a jednu visinu za uspravne biome i ponovljene dekor ćelije. Time ponavljanje odgovara stvarnom rasporedu i orijentaciji kopija. Položaji dekoracija sada se računaju u koordinatama centriranim na kameru, umesto od nule udesno.

Izvorne gornje i donje ivice 16 uspravnih pozadina nisu bile identične. `Tools/export_backdrop_tiles.py` priprema ponovljive verzije: uklapa po 96 redova na oba kraja u premultiplied-alpha prostoru, uz neizmenjenu sredinu. Krajnji redovi su identični. Originali su u `ArtSources/BackdropOriginals`, van aplikacionog targeta. Obrada ne dodaje runtime shader, teksture ili blend slojeve. Dimenzije tekstura ostaju iste. Ovo uklanja prekid na ivici, ali ne skriva ponavljanje velikih naslikanih motiva.

## Manifest

`VisualManifest.dataset/manifest.json` obuhvata svih 56 runtime tekstura: originalne i runtime PNG dimenzije, normalizovane cropove, pivote pojasa likova, pivote i landing linije platformi i imenovane dekor/foreground UV regione. `VisualManifest.swift` je zajednički dekoder; podatke koriste `ClimberNode`, `PlatformArtwork` i `CaveBackdrop`.

Crop/pivot koordinatni početak je gore levo; dekor UV početak je dole levo, kao u SpriteKit-u. `GameTextureStore` proverava runtime dimenzije pre pravljenja SKTexture. `Tools/validate_visual_manifest.py` proverava inventar, PNG dimenzije, granice cropova/UV-a, pivote, landing linije, bleed margine platformi i identičnost ivica ponovljivih tekstura. Export gameplay tekstura poziva isti validator.

Ranije Volcanic platform metadata dimenzije 1792×1024 nisu odgovarale originalnom PNG-u 1774×887. Manifest koristi stvarne dimenzije i zadržava postojeće normalizovane granice i pivot, čime ispravlja i pogrešan odnos stranica cropa. Detaljna pravila su u `ArtSources/VISUAL_MANIFEST.md`.

## Redosled i vreme animacije

`GameScene.didFinishUpdate` je jedino mesto gde se uže crta. Krajevi se čitaju posle SpriteKit akcija, fizike i ograničenja; landing squash i exit pomeranje više ne ostavljaju krajeve užeta na transformacijama prethodnog frejma. Tu se osvežava i pozadina, posle eventualnog pomeranja kamere kroz akciju. Uklonjen je poseban `exitRope` customAction i dodatno crtanje u izlaznom callback-u.

Gameplay simulacija, personality/breathing, happy pose, trail, oscilacija užeta i SpriteKit akcije sada koriste isti Turbo/Endless množilac. `scene.speed` ubrzava akcije, a eksplicitni vizuelni sat koristi isti faktor za proceduralnu animaciju. Uže više ne koristi `CACurrentMediaTime()`. Pause zaustavlja sat; reset vraća sat na nulu i brzinu na 1. Izlazna koreografija eksplicitno koristi brzinu 1. Rok za spasavanje i vreme rezultata ostaju u realnom vremenu.

Postojeće ograničenje delta vremena na 1/15 s ostaje: duga zaustavljanja aplikacije nisu snimak preciznog vremena svih SpriteKit akcija. Normalan gameplay i Turbo ne koriste odvojene namerne brzine animacije.

## Provere

- Validator: svih 56 tekstura i 16 ponovljivih ivica.
- 40 testova: uključuju svih devet pećina na 390×844 i 768×1024, proporcionalno skaliranje, pokrivenost bez rupa, velike visine kamere, tačnu wrap granicu i orijentaciju preslikanih kopija.
- Provera užeta: posle promene squash skale i položaja likova oba kraja odgovaraju stvarnim transformisanim pojasevima; ponovljeno crtanje sa zamrznutim satom ne menja geometriju.
- SpriteKit slikovni prilozi za svih devet pećina, u obe veličine prikaza.
- Dve UI provere: pauza/povratak iz pozadine i izlaz → Endless → mapa → nova igra, obe uspešne.
- Release build za iOS bez potpisivanja: uspešan.

UI provera povratka sa izlaza sada obrađuje i prvo uputstvo na čistom simulatoru; ranije je pretpostavljala da je onboarding već završen. Proizvodni onboarding nije menjan radi testa.

Nova CPU/GPU/FPS merenja na fizičkom uređaju nisu rađena u ovoj iteraciji. Prethodne brojke ostaju rezultati prethodne verzije. Promena geometrije pozadine i ubrzavanje vizuelnih akcija zahtevaju novu sesiju ako se žele uporedive performanse.

Rezultati završne sesije: `40` testova logike + `2` UI testa, bez grešaka. Pregledano je svih 18 SpriteKit snimaka pozadina i snimak izlaza.
