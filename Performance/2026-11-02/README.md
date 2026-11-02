# Sling Duo — teksture i životni ciklus resursa

Datum: 2. novembar 2026. Radna grana: `codex/rope-rendering-platform-markers`.

## Završene izmene

- Uklonjeni su target obrub, precision dijamant i moving „↔ 2×“ oznaka, zajedno sa njihovim stanjem i izradom čvorova. `setTarget` sada upravlja samo aktivacijom kretanja platforme. Mehanike precision/moving platformi i postojeća umetnost ostaju funkcionalne.
- Gameplay teksture likova imaju najdužu stranicu 384 px, platforme 768 px, fragment 256 px. Hero ilustracije za uvod i UI imaju zasebne 640 px izvoze.
- Sačuvan je ceo canvas i postojeće normalizovane UV koordinate. Point dimenzije, pivot, belt attachment i landing geometrija nisu promenjeni. Nema trimovanja niti ponovnog centriranja. Vizuelni pregled 28 hero/platform resursa je u `texture-comparison.jpg`; runtime kadar je `gameplay-optimized.png`.
- Originali 29 smanjenih tekstura čuvaju se u `ArtSources`, van aplikacionog targeta. `Tools/export_game_textures.py` ponavlja izvoz. Pozadine i dekor zadržavaju originalnu rezoluciju.
- `GameTextureStore` je vlasništvo scene, zamenjuje statičke hero/platform keševe i učitava PNG data resurse kroz `NSDataAsset` i `UIImage(data:)`. Time loader ne koristi globalni `UIImage(named:)` cache za gameplay slike.
- Izbor pećine prvo pauzira igru i oslobađa prethodne čvorove/reference, preloaduje samo novi paket, pa pokreće partiju. Zajednički resursi su 12 hero poza i fragment; paket dodaje tri background/decor teksture i platforme odgovarajuće pećine. Ukupno 17–22 osnovne teksture.
- Povratak na mapu prazni scene-owned texture i crop keševe, reference platformi i teksture na hero spriteovima. GPU alokacije SpriteKit/Metal mogu biti oslobođene kasnije; nula aplikacionih referenci nije obećanje trenutnog nula GPU/RAM zauzeća.
- Preload ima generacijski token: završetak zastarelog preloada ne može ponovo upisati prethodni paket nakon oslobađanja ili nove selekcije.

## Veličine izvoza

Ovo su izračunate RGBA8 veličine iz dimenzija slika, ne izmeren RAM aplikacije.

| Gameplay grupa | Pre | Posle |
|---|---:|---:|
| 12 hero poza | 72,01 MiB | 6,32 MiB |
| 16 platformi | 96,01 MiB | 15,90 MiB |
| Fragment | 6,00 MiB | 0,25 MiB |
| Ukupno | 174,02 MiB | 22,47 MiB |

Smanjenje gameplay RGBA piksela: približno 87,1%. Zasebnih 12 većih UI ilustracija zajedno ima dodatnih 17,56 MiB RGBA8 potencijala; to nije deo gameplay zbira. Nisu sve teksture istovremeno rezidentne. Potpuni izvozni podaci su u `texture-export.csv`.

Jedna ranija nesaglasnost je namerno sačuvana radi identičnog pivota/prikaza: `VolcanicPlatformNormal01` ima logičke master koordinate 1792×1024 u kodu, dok je postojeći PNG 1774×887. Optimizacija zadržava iste normalizovane UV regione i point geometriju; zasebna korekcija tog artwork metapodatka menjala bi prikaz.

## Provere

- Prošlo je 38 unit testova: putanja užeta, artwork geometrija, kretanje/hvatanje platformi, odsustvo markera i lifecycle/preload svih devet pećina.
- Prošao je UI test povlačenja/lansiranja lika.
- Prošao je UI test Escape → Endless → Cave Map → izbor pećine → nova partija. Njegovo prethodno očekivanje neposrednog restarta nakon dugmeta za mapu bilo je zastarelo; test sada prati postojeći tok.
- Uspešno su izgrađeni bazni i optimizovani Release profil buildovi za fizički iPhone, kao i Release simulator build.
- Pregledani su stvarni runtime kadar i original/optimizovano poređenje, a asset migracija proverena buildom i preload testovima pre uklanjanja zamenjenih imageset-ova.

## Merenje performansi — fizički uređaj još blokiran

Bazna CPU/GPU/memory sesija na fizičkom uređaju **nije izmerena**. iPhone 11 je uparen i dostupan za instalaciju preko mreže, ali je zaključan. Instalirana je odvojena profil aplikacija `Gazza.SlingDuo.GraphicsProfile`; postojeća igra i njeni podaci nisu menjani. Pokretanje je odbijeno sa razlogom Locked, a Instruments je istekao čekajući spreman uređaj. Dokazi su sačuvani u dva `physical-device-…attempt.log` fajla.

Za nastavak su potrebni otključan telefon, uključen ekran i dostupna Instruments veza (USB preporučen). U repozitorijumu su `Tools/profile_graphics.sh`, `Tools/prepare_graphics_baseline.py` i `Tools/GRAPHICS_PROFILING.md`: isti opt-in scenario radi na sačuvanoj osnovi `2a73bfe` i novoj verziji, sa posebnim bundle ID-jem. Profil kod je isključen iz običnih Debug i Release buildova.

## Dopunska provera u Release simulatoru

Ovo **nisu rezultati fizičkog uređaja**, niti GPU merenje. `simulator-release-profile.csv` sadrži 55 zapisa: dva prolaska kroz devet pećina × idle/aim/3× Turbo, pa završno oslobađanje. Svaka pećina počinje novom proceduralnom rutom; ovo ne predstavlja kompletiranje 150 skokova u svakoj pećini.

| Medijana po devet pećina | Prvi prolaz | Drugi prolaz |
|---|---:|---:|
| Footprint, idle | 27,94 MiB | 28,41 MiB |
| Footprint, aim | 27,49 MiB | 27,96 MiB |
| Footprint, Turbo | 26,63 MiB | 26,55 MiB |
| CPU aim, % jednog jezgra domaćina | 13,69% | 14,22% |
| CPU Turbo, % jednog jezgra domaćina | 18,65% | 21,68% |

Posle oslobađanja: **0 app-owned osnovnih tekstura**, procesni footprint **25,86 MiB**. Drugi prolaz nije pokazao kumulativno zadržavanje svih paketa u aplikacionom kešu. To nije dokaz odsustva svakog framework/GPU zadržavanja.

Medijana scene update intervala bila je 16,667 ms u ovim kratkim fazama; to nije izmereno vreme završetka GPU rada niti dokaz stvarnog presented FPS-a na telefonu. CPU u simulatoru zavisi od domaćina; pri delu scenarija izvršavane su i završne build provere, pa brojke služe proveri rada alata i lifecycle-a, ne proceni optimizacije CPU-a. Za konačne zaključke potrebni su fizički tragovi sa ponovljenim, dužim sesijama i kontrolisanim termalnim uslovima.
