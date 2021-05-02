# Advanced Programmable Interrupt Controller

## Local APIC

Le local apic est une entrée de la [MADT](documentation/x86_64/périphériques/MADT/), son type est 0.

Le nombre d'entrées locales APIC dans la MADT équivaut au nombre de CPUs, chaque CPU a son local APIC.

La structure de l'entrée du local APIC est:

| offset/taille (en byte) | nom              |
| ----------------------- | ---------------- |
| 2 / 1                   | identifiant ACPI |
| 3 / 1                   | identifiant APIC |
| 4 / 4                   | flag du cpu      |
