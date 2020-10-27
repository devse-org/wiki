# Local APIC

Le local apic est une entrée de la [MADT](documentation/x86_64/périphériques/MADT/), son type est 0

Le nombre d'entrée local apic dans la madt équivaut au nombre de cpu, chaque cpu à son local apic

la structure de l'entre  du local apic est

| offset/taille (en byte)  | nom |
|-----|-----|
| 2 / 1   |identifiant ACPI  |
| 3 / 1   |identifiant APIC |
| 4 / 4   | flag du cpu |


