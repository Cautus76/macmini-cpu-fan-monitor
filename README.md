# Mac mini CPU & fan monitor

Wingpanel indikátor pro elementary OS, který zobrazuje teplotu CPU, celkové
vytížení procesoru a otáčky ventilátoru. Repozitář také obsahuje konzervativní
profil `mbpfan` určený pro dlouhodobý provoz Macu mini jako serveru.

Konfigurace byla ověřena na Mac mini 2014 s procesorem Intel Core i5-4278U,
jedním ventilátorem Apple SMC a rozsahem 1800–4800 RPM. Na jiném modelu nejdřív
ověř hodnoty `fan1_min` a `fan1_max` v `/sys/devices/platform/applesmc.*`.

## Chování profilu ventilátoru

Použitý profil:

```ini
low_temp = 50
high_temp = 55
max_temp = 70
```

- Do 50 °C běží ventilátor na minimu 1800 RPM.
- Mezi 50 a 55 °C funguje hystereze a zůstávají předchozí otáčky.
- Nad 55 °C při růstu teploty `mbpfan` postupně zvyšuje otáčky.
- Od 70 °C požaduje maximum 4800 RPM.
- Při ochlazování otáčky klesají pomaleji, aby regulace nekolísala.

`max_temp` není tvrdý limit teploty. Je to bod, od kterého ventilátor běží
naplno; při náhlé zátěži může CPU krátkodobě tuto teplotu překročit.

## Instalace monitoru

Nainstaluj Python 3, Vala, vývojové balíčky Wingpanelu a GTK 3. Potom spusť:

```bash
./install-monitor.sh
```

Po instalaci se odhlaš a znovu přihlaš, aby Wingpanel načetl nový modul.

## Instalace profilu ventilátoru

Nejdřív nainstaluj `mbpfan`, potom spusť:

```bash
./install-fan-profile.sh
```

Skript zazálohuje existující `/etc/mbpfan.conf`, nainstaluje profil a restartuje
službu. Vyžádá si oprávnění správce.

Aktuální stav lze ověřit pomocí:

```bash
systemctl status mbpfan.service
sensors
cat /sys/devices/platform/applesmc.*/fan1_input
```

Nepoužívej současně jinou službu, která zapisuje do `fan1_min`, `fan1_output`
nebo `fan1_manual`. Více regulátorů by se mohlo vzájemně přepisovat.

