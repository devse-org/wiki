<center>
<b>Attention!</b><br>Cet article est en cours de rédaction.
</center>

# Introduction

RTC ou Real-Time Clock, est une puce qui mesure le passage du temps.
Elle peut être utilisée pour avoir la date et heure précise. (voir ACPI pour le siècle)

# Lire le temps
Il est possible de lire depuis la RTC en utilisant les fonctions suivantes:
```c
/* Check if RTC is updating */
int rtc_is_updating()
{
    outb(0x70, 0x0A);
    return inb(0x71) & 0x80;
}

unsigned char rtc_read(int reg)
{
    while (rtc_is_updating());
    outb(0x70, reg);

    return inb(0x71);
}
```
Voici la table des éléments à lire depuis la RTC et leur registre CMOS
| Élement de temps | Registre
|-------------|---------------|
| Secondes    | 0x0           |
| Minutes     | 0x02          |
| Heures      | 0x04         |
| Jour de la semaine      | 0x06         |
| Jour        | 0x07           |
| Année       | 0x09           |

**Note:** les valeurs retournées sont en BCD et non pas en décimal.
# Exemples
Voici un exemple d'une lecture des secondes

```c
unsigned char rtc_get_seconds()
{
    unsigned char seconds = rtc_read(0);
    unsigned char second = (seconds & 0x0F) + ((seconds / 16) * 10);
    return second;
}
```
