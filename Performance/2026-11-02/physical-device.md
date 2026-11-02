# Sling Duo — fizičko Release profilisanje

2. novembar 2026. Uređaj: **iPhone 11, A13, 4 GB**, iOS 27.0.1 (24A446). Alat: Xcode/Instruments 27.1. Ovo su rezultati fizičkog telefona; prethodni simulator podaci nisu korišćeni za zaključke.

## Rezultat

**Procesni footprint tokom igre smanjen je približno za dve trećine, a nakon oslobađanja za oko 79%.** CPU merenja ne pokazuju pouzdano ubrzanje. GPU poređenje je završeno za svih devet pećina: u ovoj uparenoj sesiji aktivno SpriteKit GPU vreme je približno 12% kraće u aim i 19% kraće u Turbo fazi. To nije dokaz porasta FPS-a.

## Metod

Baza je commit `2a73bfe` — već sadrži prethodno odvajanje rope fizike od renderinga. Optimizovana verzija je `db5c1be` — manji izvozi tekstura, scenski preload/lifecycle i uklonjene oznake platformi. Poređenje zato ne meri efekat ranije rope optimizacije.

Obe verzije izgrađene su kao Release, sa `-O`, bez code coverage-a, sa istim opt-in mernim hook-ovima. Poseban bundle ID `Gazza.SlingDuo.GraphicsProfile` odvaja profil aplikaciju od postojeće igre i njenih podataka.

Četiri kompletna CPU/memory zapisa: dva za bazu i dva za optimizovanu verziju. Svaki ima 55 zapisa: dva prolaska kroz devet pećina × idle 2 s / aim 2 s / 3× Turbo let 1 s, pa završno oslobađanje. Drugi par snimljen je obrnutim redosledom verzija. Ovo je kratko poređenje grafičkih faza i promena pećina, ne kompletiranje po 150 skokova u svakoj pećini. Rute ostaju proceduralne i nisu identične između sesija.

CPU je direktno procesno user+system vreme iz `getrusage`, izraženo kao procenat jednog logičkog jezgra. Memorija je `task_vm_info.phys_footprint` u MiB. Medijane ispod izvedene su iz 18 istovrsnih faza po snimanju. Framework i drajverske alokacije mogu ostati nakon uklanjanja aplikacionih referenci.

## CPU i memorija — prvi par

| Faza | CPU baza | CPU optimizovano | Footprint baza | Footprint optimizovano |
|---|---:|---:|---:|---:|
| Idle | 26,76% | 24,00% | 239,63 MiB | 72,63 MiB |
| Aim | 34,77% | 32,96% | 239,71 MiB | 72,75 MiB |
| Turbo | 35,16% | 33,85% | 239,85 MiB | 75,85 MiB |

Posle završnog oslobađanja: **241,53 → 50,96 MiB**, približno **79% manje**. Optimizovani loader ima **0 app-owned osnovnih tekstura** na ovom checkpoint-u.

## Ponovljeni par

| Faza | CPU baza | CPU optimizovano | Footprint baza | Footprint optimizovano |
|---|---:|---:|---:|---:|
| Idle | 22,57% | 24,02% | 223,47 MiB | 73,03 MiB |
| Aim | 30,75% | 33,96% | 223,55 MiB | 73,15 MiB |
| Turbo | 34,04% | 34,12% | 223,69 MiB | 76,17 MiB |

Posle oslobađanja: **225,00 → 47,64 MiB**, opet približno **79% manje**. Smer CPU razlike nije dosledan između parova; mala razlika u prvom paru ne predstavlja dokaz ubrzanja.

U prvom paru medijana footprint-a baze raste sa 211,71 MiB u prvom prolasku na 243,05 MiB u drugom. Kod optimizovane verzije odgovarajuće vrednosti su 73,41 i 73,31 MiB. To podržava nalaz da aktivni paketi nisu kumulativno zadržani u aplikacionom kešu. Ovo nije opšti dokaz odsustva svakog framework ili GPU cache-a.

Medijana scene callback intervala ostaje približno **16,666 ms** u obe verzije. To nije GPU trajanje ni potvrda presented FPS-a. Nije utvrđen merljiv porast FPS-a. Termalni intervali u produženim Game Performance tragovima označeni su kao **Nominal**; test nije dugotrajna termalna/autonomna studija.

## GPU — kompletno upareno poređenje

Obe verzije snimljene su sa **Metal System Trace**, po 60 sekundi, uz 75-sekundni retention prozor. Analiza koristi prvi kompletan prolazak: **9 pećina × 3 faze = 27 faza po verziji**. Drugi, nepotpun prolazak iz ovih kraćih GPU zapisa nije uključen u poređenje.

Faze su zabeležene direktno u CSV-u, sa UTC i monotonim satom, pa poravnate sa početkom Instruments traga. Najveće relativno odstupanje satova je 0,778 ms za bazu i 0,768 ms za optimizovanu verziju. Parser je zahtevao svih 27 faza i najmanje deset odgovarajućih GPU frejmova u svakoj. Oba snimka ispunjavaju uslov. Termalno stanje je **Nominal** tokom oba traga.

Analizirano je **2.558 baznih i 2.633 optimizovana SpriteKit frejma** iz tih faza.

| Faza | GPU aktivna medijana, baza | Optimizovano | Promena | GPU p95, baza → optimizovano |
|---|---:|---:|---:|---:|
| Idle | 1,923 ms | 1,681 ms | −12,6% | 2,215 → 1,975 ms |
| Aim | 1,994 ms | 1,758 ms | −11,8% | 2,280 → 2,025 ms |
| Turbo | 2,110 ms | 1,707 ms | −19,1% | 2,458 → 2,035 ms |

Metrika je unija aktivnih Vertex/Fragment intervala SpriteKit render komandi po frejmu. Istovremeni intervali se ne broje dvaput. CPU-to-GPU čekanje, compositor (`backboardd`) i drugi procesi su isključeni. To nije ukupna zauzetost GPU-a celog telefona niti ukupno trajanje prikaza frejma sa SwiftUI interfejsom.

Ovo je jedno upareno GPU snimanje sa proceduralnim rutama. Rezultat pokazuje smanjen GPU rad u ovoj sesiji, ali ne izdvaja doprinos manjih tekstura, uklonjenih markera i preloada. GPU frekvencija nije fiksirana, a dugotrajno zagrevanje i rad na drugim uređajima nisu obuhvaćeni. Za garantovane procente dobitka potrebni su dodatni ponovljeni, deterministički scenariji.

Prethodni Game Performance rep i zaključane/zaglavljene probe nisu korišćeni za ovo poređenje. Metal System Trace je obezbedio kontinuirane događaje; direktni CSV satovi zamenili su dodatni instrument za oznake koji je blokirao pripremu snimanja. Profil aplikacija održava ekran uključenim tokom snimanja i završila je rad nakon testa. Obični buildovi nemaju ovo ponašanje.

## Sačuvani fajlovi

- `physical-baseline.csv`, `physical-optimized.csv`: prvi fizički par.
- `physical-baseline-repeat.csv`, `physical-optimized-repeat.csv`: ponovljeni fizički par.
- `physical-cpu-memory-summary.csv`: objedinjene medijane.
- `physical-profiling-status.json`: poreklo i status merenja.
- `baseline-gpu-by-phase.csv`, `optimized-gpu-by-phase.csv`: rezultati svih 27 faza po verziji.
- `baseline-gpu-summary.json`, `optimized-gpu-summary.json`: agregati i validacija satova.
- `gpu-baseline-phases.csv`, `gpu-optimized-phases.csv`: izvorni fazni satovi GPU sesija.
- `physical-gpu-traces.zip`: oba uporediva sirova Metal traga, fazni CSV-i i GPU sažeci; sačuvano lokalno uz ovaj izveštaj, van Git repozitorijuma. Nevalidne probe nisu uključene.

Ponovljiv postupak je u `Tools/profile_graphics.sh`, uz `Tools/prepare_graphics_baseline.py` i `Tools/summarize_gpu_trace.py`. Podaci na grani sadrže app-specific CSV/JSON sažetke; veliki sirovi tragovi čuvaju se u lokalnom ZIP-u.
