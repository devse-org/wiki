<center>
<b>Attention!</b> Article est en cours d'écriture
</center>

# Introduction

un port com était utilisé comme un port de communication (comme l'est l'usb aujourd'hui).
les ports com même si ils sont obselètes sont encore énormément utilisé pour le dévelopement d'un système d'exploitation. Ils sont très simple à implémenter et sont très utile pour le débuggage, car dans presque toutes les machines virtuelles on peut avoir la sortie d'un port com dans un fichier, dans un terminal ou autre. Ils sont aussi très utiles car on peut les initialiser très tôt et donc avoir des informations de debuggage très utiles. 
Les ports série peuvent envoyer des données et en recevoir, et vous pouvez faire un terminal externe juste avec un ports série. 

les ports com ajourd'hui ont été remplacés par les ports usb mais sont toujours supportés nos machines

La norme RS-232 (qui a été révisé mainte et mainte fois) est une norme qui standardise les ports série, qui éxiste depuis 1981, elle standardise les noms (com1, com2, com3 etc)
elle limite la vitesse à 19200 baud soit largement assez pour un petit terminal (soit potentiellement 19200 caractères par secondes)
la limite est calculé en Baud, la conversion se fait ainsi :

1 Baud = (nombre de bit transmit par le com port) par seconde
soit généralement un byte 


la limite dépend aussi de la distence du racord avec le fil, un fil long à une capacité moindre qu'un fil court 

# Initialisation

chaque port à besoin d'être initialisé avant son utilisation


pour commencer il y a quelque valeurs constantes pour chaque port com 

| Le port Com | L'id du port  | Son IRQ       |
|-------------|---------------|---------------|
| COM1        | 0x3F8         | 4  
| COM2        | 0x2F8         | 3
| COM3        | 0x3E8         | 4
| COM4        | 0x2E8         | 3

puis il y a l'offset, chaque offset a certaines particularité 
(c'est L'ID DU PORT + OFFSET)

| offset      | action        |
|-------------|---------------|
| 0         | Le port data du com, il est utilisé pour envoyer  et recevoir des données, si le bit DLAB = 1 alors c'est pour mettre le diviseur du Baud   (les bits inférieurs)        |   
| 1        | Le port interrupt du com, il est utilisé pour activer les interrupt du port, si le bit DLAB = 1 alors c'est pour mettre la valeur du diviseur (du Baud aussi mais pour les bits supérieur)         |
| 2        | L'identificateur d'interrupt ou le controleur FIFO          | 
| 3        | le control de ligne (Le bit le plus haut est celui pour      DLAB)         |
| 4        | Le control de Modem  |
| 5        | Le status de la ligne |
| 6        | Le status de Modem |
| 7        | Le scratch register | 

Pour mettre DLAB il faut :
mettre le port comme ceci :
LE PORT + 3  = 0x80 = 128 = 0b10000000

```cpp
outb(COM_PORT + 3, 0x80);
```
pour le désaciver il faut juste remettre le bit 8 à 0


## Les baud

Le port com se met à jour 115200 fois par seconde, pour controller la vitesse il faut mettre en place un diviseur 
pour mettre le diviseur il faut alors déjà activer le DLAB

puis ensuite passer la valeur par l'offset 0 (les bits inférieurs) et 1 (les bits supérieurs) 

exemple pour mettre un diviseur de 5 (alors le port auras un 'rate' de 115200 / 5):
```cpp
outb(COM_PORT + 3, 0x80); // activer le DLAB
outb(COM_PORT + 0, 5); // les bits les plus petit 
outb(COM_PORT + 1, 0); // les bits les plus haut
```

## La taille de données

on peut mettre la taille des données envoyés au port com par update, 
elle peut aller de 5 bit à 8 bit

5bit = 0 0 (0x0)

6bit = 0 1 (0x1)

7bit = 1 0 (0x2)

8bit = 1 1 (0x3)

pour mettre la taille de données vous devez l'écrire dans le port de control de ligne (les bits les plus petit)
alors après avoir setup le rate du port (et donc d'avoir activé le dlab) on peut faire comme ceci : 
```cpp

outb(COM_PORT + 3, 0x3); // déactiver le DLAB + mettre la taille de donnée à 8 donc un char/unsigned char en c++


```

## Ressources

- https://www.sci.muni.cz/docs/pc/serport.txt

## Redacteurs

- Supercip971
