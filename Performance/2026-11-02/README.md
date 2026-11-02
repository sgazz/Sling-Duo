# Fizički Release rezultati — Sling Duo

Uređaj: iPhone 11 / A13, iOS 27.0.1. Baza: `2a73bfe`; optimizovana igra: `db5c1be`, uz merne hook-ove isključene iz običnih buildova.

- Procesni footprint tokom igre približno je za dve trećine manji.
- Posle oslobađanja baza zadržava 225–242 MiB, optimizovana verzija 48–51 MiB: oko 79% manje.
- CPU ubrzanje nije dosledno potvrđeno između ponovljenih snimanja.
- U uparenom GPU prolasku kroz svih devet pećina aktivno SpriteKit GPU vreme je kraće približno 12% tokom aim i 19% tokom Turbo faze. Ovo nije dokaz porasta presented FPS-a.

[Kompletan metod, tabele i granice zaključaka](physical-device.md).

Četiri puna CPU/memory zapisa imaju po 55 faza. GPU poređenje ima svih 27 faza prvog prolaska po verziji, sa proverom UTC/monotonog sata i nominalnim termalnim stanjem. CSV/JSON rezultati su ovde; veliki sirovi Metal tragovi sačuvani su lokalno u `physical-gpu-traces.zip`. Simulator podaci su raniji, posebno označeni i nisu korišćeni za fizičke zaključke.

Ponovljivi alati su u `Tools/`: export tekstura, priprema baze, Release snimanje i GPU fazna analiza. Originali grafike i podaci izvoza su u `ArtSources/`.
