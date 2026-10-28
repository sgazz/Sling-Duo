# Sling Duo — paket promptova za grafiku

Koristi master prompt zajedno sa **jednim** zadatkom iz nastavka. Generiši prvo odobren izgled jednog plavog i jednog narandžastog junaka, pa njihove poze iz tih istih referenci. Nemoj tražiti ceo paket na jednoj slici: tako nastaju neujednačeni likovi i neupotrebljivi sprite sheetovi.

Promptovi su na engleskom radi lakšeg prenošenja u različite generatore. Dimenzije su ciljne dimenzije fajlova; ako ih generator ne podržava, koristi najbližu veću rezoluciju, a završnu pripremu i proveru radimo naknadno. Sam tekst prompta ne garantuje pravi alpha kanal ili savršene animacione frejmove.

## Reference koje prilažeš

Iz postojećeg foldera `Two Jumpers`:

- **Designer (11).png**: glavni izgled malih junaka, boje, svetleće oči i energija. Koristi plavog iz gornjeg i narandžastog iz srednjeg reda. Ne mešaj različite narandžaste varijante između poza.
- **Designer (4).png**: oblik, materijal i osvetljenje kamenih platformi.
- **Designer (7).png** i **Designer (8).png**: dubina, magla i paleta pećine.
- **Near_Side_Foreground_1080x1920_transparent.png**: bočne stene i transparentan prolaz.
- **Designer (6).png**: boje i mekoća svetlosnih efekata.
- **Designer (5).png**: samo atmosfera i kompozicija; ne kopirati već nacrtane platforme i likove u gameplay pozadinu.

Ne prilaži sve reference za svaki zadatak. Za junaka su dovoljne odobrena slika junaka i referenca stila; za platforme platforme i ambijent. `Designer.png` i `(1)` predstavljaju drugi, obli stil likova i ne treba ih mešati sa izabranim svetlećim parom.

## 1. Master prompt — priloži uz svaki zadatak

```text
Create production game artwork for SLING DUO, a playful portrait mobile arcade game about two tiny climbing partners connected by a luminous elastic rope.

Follow the attached approved references consistently. The visual identity is stylized 2.5D cartoon artwork: compact dark navy characters, expressive luminous eyes, one cyan-blue energy crest and one orange energy crest, warm amber stone platforms, a deep desaturated indigo-violet canyon, soft atmospheric haze, and restrained golden light.

The tone is charming, slightly clumsy, cooperative and adventurous. The heroes are teammates, never enemies. Their personalities should remain readable through posture and eyes at only 32–40 screen points tall. Keep broad silhouettes and simple interior shapes. Use consistent soft upper-left lighting, clean anti-aliased edges, and controlled highlights.

This is a side-view 2D game. Keep camera angle, proportions, material rendering and light direction identical between assets. Characters must be brighter and more saturated than the background. Platforms need an unmistakable readable top landing edge. Small precision platforms use a subtle amber-gold accent without excessive glow.

Deliver ONLY the asset requested in the task below. Do not create a mockup, reference board, labeled asset collection, promotional layout or screenshot unless specifically requested.

For transparent assets: use a genuine RGBA alpha channel, alpha 0 outside the artwork. A painted checkerboard is NOT transparency. No white or dark background, matte fringe, watermark, labels, bounding box, ground plane or baked rectangular shadow. Preserve soft partially transparent glow at the silhouette edge. Do not bake interface text or score numbers into artwork.
```

## 2. Odobreni junaci — prvo ove dve slike

Generiši svaku zasebno, uz `Designer (11).png`.

```text
TASK: Create ONE isolated full-body CYAN hero, neutral idle key pose, using the cyan character from the top row of the attached character reference as the exact identity guide. Dark navy compact body, cyan luminous eyes, a small cyan energy crest swept backward, short limbs and friendly curious expression. No weapons, armor additions, extra accessories or rope attached to the body. Three-quarter side view suitable for a side-view mobile game. Entire character centered with at least 15% transparent padding; no cropped limbs or glow. Transparent RGBA PNG, target canvas 1024 x 1024. Keep the character visually simple and legible when reduced to 36 points tall.
```

Za narandžastog zameni `CYAN` sa `ORANGE`, `cyan` sa `orange` i `top row` sa `middle row`. Koristi isti ugao kamere i iste proporcije. Sačuvaj kao `hero_cyan_master.png` i `hero_orange_master.png`.

## 3. Poze i animacije — tek posle odobrenja mastera

Za prvi prolaz dovoljno je **po šest ključnih poza po junaku**. Uvek priloži odgovarajući master i generiši jednu pozu po slici:

```text
TASK: Use the attached approved hero master as a strict identity reference. Create ONE new key pose: [POSE]. Preserve the exact face, crest, body proportions, colors, lighting and camera angle. Keep the same 1024 x 1024 transparent canvas, identical character scale, and stable body-center pivot at the canvas center. Keep all limbs and glow inside the canvas. No rope, platform, scenery, text or ground shadow. Do not redesign the character.
```

Vrednosti za `[POSE]`:

1. `IDLE: relaxed friendly posture, eyes open, a slight playful lean`.
2. `ANCHORED: securely balanced on an invisible ledge, looking upward toward the partner; feet at the same baseline as the master`.
3. `PULL: stretched into a compact tense anticipation pose, worried but funny eyes, limbs tucked close, ready for elastic release`.
4. `FLIGHT: airborne upward pose, arms open, surprised joyful eyes, compact silhouette; no motion trail baked in`.
5. `CATCH: successful landing compression, happy relieved eyes, visibly squashed body without changing character identity`.
6. `MISS: dangling disappointed pose, comically worried eyes, intact healthy character; no injury imagery`.

Za prave animacije, odobrenu pozu zatim proširi zasebnim zadatkom:

```text
TASK: Animate only [STATE] for the attached approved hero. Deliver a horizontal sequence of SIX equally sized square frames, read left to right, on genuine transparent RGBA. Keep identical character identity, scale, camera, lighting and body-center pivot. Smooth consecutive motion, not six unrelated illustrations. Add a full frame of transparent padding around the body as needed to keep every limb and glow inside its cell. No frame borders, numbers, labels or background. Target frame size 256 x 256, target strip 1536 x 256. For idle and anchored states, frame six must transition naturally back to frame one. For pull, flight, catch and miss states, make a one-shot sequence that ends in a useful held pose.
```

Ako generator ne može uredno da napravi strip, traži frejmove pojedinačno iz iste reference. Stripove spajamo i proveravamo u pripremi; ne oslanjamo se na nacrtanu mrežu kao dokaz pravilnih frejmova.

## 4. Platforme — tri obične i tri male

Generiši po jednu varijantu po slici uz `(4)`:

```text
TASK: Create ONE isolated floating stone platform for Sling Duo, matching the attached platform material reference. Side-view game object with a shallow visible top surface and a clear nearly horizontal top landing edge. Warm amber sandstone, chunky beveled edges, simple restrained cracks, dark violet underside. No separate ground shadow. Not a complete scene or sheet.

Variant: [VARIANT]. Maintain the same top-plane camera angle and upper-left lighting across all variants. The collision surface must visually match the central usable top span; no deceptive long transparent margins or fragile-looking protrusions. Keep decorative thickness below the landing plane. Center the platform and leave transparent padding. Genuine transparent RGBA PNG, target canvas 1024 x 384. No checkerboard, labels, particles, arrows or characters.
```

Varijante:

- `NORMAL A/B/C: a broad stable ledge, readable silhouette, width-to-visible-height ratio around 5:1; vary only rock outline and cracks`.
- `PRECISION A/B/C: a compact stable ledge, about 55–60% of the normal platform's physical width at the same scale, ratio around 3:1, restrained gold rim; challenging but solid, not breaking`.

Obične platforme u igri su približno 94–136 poena široke, male 62–80. Tekstura i vidljiva gornja ivica moraju se uklopiti sa stvarnom zonom hvatanja. Strelicu cilja ostavljamo u kodu.

## 5. Pozadina i parallax — slojevi zasebno

```text
TASK: Create ONLY the FAR BACKGROUND layer of a portrait endless vertical canyon for Sling Duo. Use the attached canyon reference for palette and materials. Desaturated indigo-violet distant rock masses, soft haze, low contrast and broad quiet shapes. Leave the central 65–70% of the image calm and readable for moving characters, rope and platforms. No playable platforms, characters, rope, lettering, HUD, central bright sun, opening arch, ceiling, floor or end destination. Seamlessly tile from TOP to BOTTOM, with matching lighting and shapes at the joining edges. Opaque PNG, target 1536 x 3072.
```

```text
TASK: Create ONLY the MIDGROUND canyon walls layer, matching the approved far background. Warm violet-brown rock walls along the left and right edges, subdued amber edge light, moderately detailed shapes, open central passage covering at least 70% of image width. Genuine RGBA transparency through the passage and around the wall silhouettes. No fog rectangle or opaque center. No playable platforms, characters, rope, arch, ceiling or floor. Seamlessly tile vertically with matching top and bottom edges. Target PNG 1536 x 3072.
```

```text
TASK: Create ONLY the NEAR FOREGROUND side-wall layer for the same endless canyon. Use the attached transparent foreground reference for stone material. Stronger but controlled edge detail on the outermost 8–12% of each side. At least 76% of the center must be completely transparent. No rocks crossing the central play corridor, no arch, ceiling or floor. Genuine RGBA alpha, clean edges with no colored matte fringe. Seamlessly tile top to bottom, target 1536 x 3072. No platforms, characters, text or frame decoration.
```

Postojeće `(7)`, `(8)` i transparentni foreground već koristimo za prvi prolaz. Novi slojevi treba da zamene privremeno preslikavanje tekstura pravim vertikalnim tileovanjem.

## 6. Uže i efekti

Uže ostaje vođeno fizikom i crtano u kodu. Ne generiši ceo luk sa junacima: tako dobijamo jednu sliku koju ne možemo pravilno rastezati.

```text
TASK: Create ONE straight horizontal luminous elastic-rope texture strip, bright pale cyan-white core with a restrained warm gold edge glow, consistent thickness, genuine transparent RGBA. No endpoints, knots, characters, curved rope or background. Clean seamless LEFT-to-RIGHT repetition, target 1024 x 128. Glow must fade smoothly to alpha 0 above and below the strip. No rectangular haze.
```

Efekte traži pojedinačno, svaki na 512 × 512 transparentnom platnu:

```text
TASK: Create ONE isolated mobile-game effect element for Sling Duo: [EFFECT]. Match the attached effect reference, using cyan, warm gold and soft white only. Simple readable shape, restrained glow, smooth alpha falloff, centered with generous padding. Genuine transparent RGBA PNG, target 512 x 512. No environment, character, text or opaque haze. This is a reusable effect element, not a complete gameplay illustration.
```

Efekti: `small catch sparkle`, `soft round flight-trail particle`, `thin amber rescue-warning ring`, `small four-point record sparkle`.

Kretanje, trajanje i intenzitet ovih elemenata određuje kod. Nisu nam potrebne velike eksplozije koje zaklanjaju sledeću platformu.

## 7. UI i ikonica

Za dugmad i tekst zadržavamo native elemente: rezultat, rekord, mute ikonica i poruke ostaju oštri, pristupačni i prilagodljivi. Eventualno generiši jedan diskretan okvir panela:

```text
TASK: Create ONE empty rounded rectangular game-over panel background for Sling Duo. Deep navy-violet material, subtle warm stone accent at the outer edge, quiet flat central area for text placed later in code. Genuine transparent RGBA outside the panel. No text, numbers, icons, buttons, characters or baked shadows extending far from the panel. Target 1024 x 768, front-facing and symmetrical. The border should remain readable when scaled down.
```

Ikonica:

```text
TASK: Create an iOS app icon for SLING DUO using the TWO attached approved character masters. The cyan and orange teammates are connected by a short glowing elastic curve, one slightly above the other, both expressive and friendly. Bold compact silhouettes, dark indigo background, controlled warm gold accent, strong contrast and clear recognition at tiny sizes. Keep important faces safely inside the central 75% of the square. No text, lettering, UI, mockup, border, rounded-corner mask or transparent pixels. Final icon is a full-bleed opaque square, target 1024 x 1024.
```

## Redosled izrade

1. Dva odobrena master lika.
2. Po šest ključnih poza, sa istim pivotom i proporcijama.
3. Po jedna obična i mala platforma za proveru u igri, zatim dodatne varijante.
4. Slojevi pozadine sa pravim vertikalnim tileovanjem.
5. Animacione sekvence i kratki efekti.
6. App ikonica i eventualni okvir panela.

## Provera pre ubacivanja

- Stvarni alpha kanal: providna polja moraju imati alpha 0; šahovnica ne sme biti nacrtana u slici.
- Isti junak, ugao i veličina u svim pozama; stabilan pivot i bez odsečenih delova.
- Čitljivost likova na 32–40 poena i malih platformi na 62–80 poena.
- Teksture pozadine spojiti u najmanje tri vertikalne kopije i proveriti šavove.
- Vidljiva gornja ivica platforme mora odgovarati zoni hvatanja.
- Glow i čestice ne smeju sakriti sledeći cilj.

Nazivi za predaju: `hero_cyan_*`, `hero_orange_*`, `platform_normal_01..03`, `platform_precision_01..03`, `canyon_far`, `canyon_mid`, `canyon_near`, `rope_strip`, `fx_*`, `app_icon`. Sve predati kao zasebne PNG fajlove, a ne jedinu sliku sa svim elementima.
