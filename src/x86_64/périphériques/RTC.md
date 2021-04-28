<center>
<b>Attention!</b><br>Cet article est en cours de rédaction.
</center>

# Introduction

RTC ou Real-Time Clock, est une puce qui mesure le passage du temps.
Elle peut être utilisée pour avoir la date et heure précise. (voir ACPI pour le siècle)

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Dallas-Semiconductor-DS1287-Real-Time-IC.jpg/1920px-Dallas-Semiconductor-DS1287-Real-Time-IC.jpg" width="400">


# Lire le temps
Il est possible de lire depuis la RTC en utilisant les fonctions suivantes:
```c

enum 
{
    CMOS_ADDRESS = 0x70,
    CMOS_DATA = 0x71,
    STATUS_REGISTER_A = 0x0A
};

/* Vérifier si la RTC est en train de se mettre à jour */
int rtc_is_updating()
{
    outb(CMOS_ADDRESS, STATUS_REGISTER_A);
    return inb(CMOS_DATA) & 0x80;
}

unsigned char rtc_read(int reg)
{
    while (rtc_is_updating()); /* Attendre que l'update finisse */
    outb(CMOS_ADDRESS, reg);

    return inb(CMOS_DATA);
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
    unsigned char second = (seconds & 0x0F) + ((seconds / 16) * 10); /* Convertir au décimal */
    return second;
}
```

# Ressources
- [Wikipedia](https://en.wikipedia.org/wiki/Real-time_clock)
- [OSDev.org - CMOS](https://wiki.osdev.org/CMOS)
- [OSDev.org - RTC](https://wiki.osdev.org/RTC)
