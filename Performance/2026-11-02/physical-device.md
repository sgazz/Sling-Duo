# Sling Duo — fizičko Release profilisanje

2. novembar 2026. Uređaj: **iPhone 11, A13, 4 GB**, iOS 27.0.1 (24A446). Alat: Xcode/Instruments 27.1. Ovo su rezultati fizičkog telefona; prethodni simulator podaci nisu korišćeni za zaključke.

## Rezultat

**Procesni footprint tokom igre smanjen je približno za dve trećine, a nakon oslobađanja za oko 79%.** CPU merenja ne pokazuju pouzdano ubrzanje. Uporediva GPU sesija po fazama još nije završena zbog ponovnog zaključavanja uređaja; postojeći GPU podaci su sačuvani sa jasno različitim obuhvatom.

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

## GPU — sačuvani podaci i ograničenje

Game Performance šablon je na ovom uređaju zadržavao samo GPU rep snimanja, čak i kada je produžen globalni retention prozor. Zbog toga se on ne koristi za poređenje svih pećina.

Namenski Metal System Trace zabeležio je kontinuiranu baznu sesiju: **3.076 SpriteKit frejmova**, GPU aktivna medijana **1,941 ms**, p95 **2,254 ms**. Obuhvat je približno prvih 60 sekundi, sa prolaskom kroz svih devet pećina. U tom zapisu nisu uključene Points of Interest oznake, pa se GPU rezultat ne razlaže pouzdano na pojedinačne aim/Turbo faze.

Optimizovani Game Performance rep ima **289 SpriteKit frejmova**, medijanu **1,671 ms**, p95 **2,014 ms**. To je završni deo scenarija, pretežno Daybreak Exit. **Ove brojke nisu direktno uporedive sa baznim prolaskom kroz sve pećine i iz njih se ne računa GPU dobitak.**

GPU metrika predstavlja uniju aktivnih Vertex/Fragment intervala za SpriteKit render komande po frejmu. CPU-to-GPU čekanje nije uračunato u aktivni GPU rad. Proces `backboardd` i drugi compositor događaji su isključeni; rezultat nije ukupna zauzetost GPU-a celog uređaja.

U optimizovanom repu dodatno je izmereno oko **53,91 MiB `MTLDevice.currentAllocatedSize`**, zatim **31,19 MiB nakon oslobađanja**. To je Metal alokaciona metrika, drugačija od procesnog footprint-a. Baza nema uporediv kompletan uzorak tog broja u istom tragu, pa se ne navodi procentualna GPU-memory ušteda.

Pokušaj uparenog kontinuiranog GPU testa sa Points of Interest oznakama prekinut je zato što se telefon ponovo zaključao. Ta proba nije korišćena kao rezultat. Profil build sada održava ekran uključenim, uz reset tog stanja pri uklanjanju scene; obični buildovi nemaju tu izmenu. Za dovršetak su spremne obe potpisane verzije i fazni GPU parser.

## Sačuvani fajlovi

- `physical-baseline.csv`, `physical-optimized.csv`: prvi fizički par.
- `physical-baseline-repeat.csv`, `physical-optimized-repeat.csv`: ponovljeni fizički par.
- `physical-cpu-memory-summary.csv`: objedinjene medijane.
- `physical-profiling-status.json`: poreklo i status merenja.
- `physical-gpu-traces.zip`: validan kontinuirani bazni GPU trag i ograničeni optimizovani rep, uz opis obuhvata. Ne sadrži nevalidnu zaključanu probu.

Za konačno GPU poređenje: Metal System Trace + Points of Interest, isti prvi prolazak kroz svih devet pećina za obe verzije, filtriranje na proces igre i validacija najmanje 27 faznih oznaka. Alat `Tools/profile_graphics.sh` i parser pripremljeni su za to snimanje nakon otključavanja.
