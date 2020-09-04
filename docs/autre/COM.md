<center>
<b>Attention!</b><br>Cet article est en cours d'écriture.
</center>

# Introduction
Un port COM était couramment utilisé comme un port de communication.
Même si aujourd'hui, l'USB a remplacé le port COM, il reste néanmoins très utile et toujours supporté dans nos machines.

Même s'ils sont obsolètes, les ports COM sont encore beaucoup utilisés pour le développement de systèmes d'exploitation.
Ils sont très simples à implémenter et sont très utiles pour le débogage, car, dans presque toutes les machines virtuelles, on peut avoir la sortie d'un port COM vers un fichier, un terminal ou autre.
Ils sont aussi très utiles car on peut les initialiser très tôt et donc avoir des informations de débogage efficacement.

Par exemple, les ports série peuvent envoyer des données et en recevoir, ce qui permettrait de faire un terminal externe en utilisant uniquement ce port. 

La norme RS-232 (qui a été révisée maintes et maintes fois) est une norme qui standardise les ports série.
Existant depuis 1981, elle standardise les noms (COM1, COM2, COM3, etc), limite la vitesse à 19200 Baud soit largement assez pour un petit terminal (donc potentiellement 19200 caractères par secondes).

la limite étant calculée en Baud, celui-ci s'exprimant en bit/s, 1 baud correspond donc à 1 bit par seconde.
La limite dépend également de la distence du raccord avec le fil, un fil long a une capacité moindre qu'un fil court. 

# Initialisation
Chaque port a besoin d'être initialisé avant son utilisation.

Pour commencer, il y a quelques valeurs constantes à connaître pour chaque port COM. 

| Le port Com | L'id du port  | Son IRQ       |
|-------------|---------------|---------------|
| COM1        | 0x3F8         | 4             |
| COM2        | 0x2F8         | 3             |
| COM3        | 0x3E8         | 4             |
| COM4        | 0x2E8         | 3             |

Puis, il y a l'offset.
Chaque offset a certaines particularités.
(= ID DU PORT + OFFSET)

| offset      | action                                                                                                                                                                                      |
|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0           | Le port Data du COM, il est utilisé pour envoyer et recevoir des données, si le bit DLAB = 1 alors c'est pour mettre le diviseur du Baud (les bits inférieurs)                              |
| 1           | Le port Interrupt du COM, il est utilisé pour activer les Interrupt du port, si le bit DLAB = 1 alors c'est pour mettre la valeur du diviseur (du Baud aussi mais pour les bits supérieurs) |
| 2           | L'identificateur d'Interrupt ou le controleur FIFO                                                                                                                                          | 
| 3           | le control de ligne (Le bit le plus haut est celui pour DLAB)                                                                                                                               |
| 4           | Le control de Modem                                                                                                                                                                         |
| 5           | Le status de la ligne                                                                                                                                                                       |
| 6           | Le status de Modem                                                                                                                                                                          |
| 7           | Le scratch register                                                                                                                                                                         |

Pour mettre DLAB il faut mettre le port comme indiqué :
`PORT + 3  = 0x80 = 128 = 0b10000000`

```cpp
outb(COM_PORT + 3, 0x80);
```

Pour le désactiver, il faut juste remettre le bit 8 à 0.


## Les Baud
Le port COM se met à jour 115200 fois par seconde.
Pour controller la vitesse, il faut mettre en place un diviseur, que l'on peut utiliser en activant le DLAB.

Ensuite, il faut passer la valeur par l'offset 0 (les bits inférieurs) et 1 (les bits supérieurs). 

Exemple permettant de mettre un diviseur de 5 (alors le port auras un 'rate' de 115200 / 5) :
```cpp
outb(COM_PORT + 3, 0x80); // activer le DLAB
outb(COM_PORT + 0, 5); // les bits les plus petits 
outb(COM_PORT + 1, 0); // les bits les plus hauts
```

## La taille des données
On peut mettre la taille des données envoyées au port COM par update.
Celle-ci peut aller de 5 bits à 8 bits

5bits = 0 0 (0x0)

6bits = 0 1 (0x1)

7bits = 1 0 (0x2)

8bits = 1 1 (0x3)

Pour définir la taille des données, vous devez l'écrire dans le port de contrôle de ligne (les bits les plus petits) avoir configuré le rate du port (et donc d'avoir activé le DLAB).
```cpp
outb(COM_PORT + 3, 0x3); // désactiver le DLAB + mettre la taille de donnée à 8 donc un char/unsigned char en c++
```

## Ressources
- https://www.sci.muni.cz/docs/pc/serport.txt

### Rédigé par @Supercip971, contribution par @busybox11
