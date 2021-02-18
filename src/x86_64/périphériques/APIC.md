# Advanced Programmable Interrupt Controller

# Local APIC

Le local apic est une entrée de la [MADT](documentation/x86_64/périphériques/MADT/), son type est 0.

Le nombre d'entrées locales apic dans la madt équivaut au nombre de CPUs, chaque CPU a son local apic.

La structure de l'entrée du local apic est:

| offset/taille (en byte)  | nom |
|-----|-----|
| 2 / 1   |identifiant ACPI  |
| 3 / 1   |identifiant APIC |
| 4 / 4   | flag du cpu |
