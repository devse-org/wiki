# le framebuffer

Le framebuffer est fourni par le bootloader, le bootloader doit fournir aussi la taille de ce frambuffer, en largeur et en hauteur, il fournit aussi le nombre de bit par pixel. Ces framebuffers utilisent le VGA (ou le vbe).

Il y a deux *type* de framebuffers: 
- Les framebuffers de textes: l'écran est une grille de caractère, on peut seulement faire du texte, on le nomme aussi le vga en mode texte.
- Les framebuffers de pixels: l'écran est une grille de pixels, on peut éditer pixels par pixels.
  
C'est un moyen basique de dessiner l'écran dans un kernel, cependant pour faire certaines choses plus compliqués nous sommes obligé d'utiliser, soit un driver gpu, soit un driver de gpu virtuel (seulement utile dans une machine virtuelle, comme `qemu`). C'est donc au CPU de faire le rendu.

# Les framebuffers textes: 

Les framebuffers de textes utilisent 16bit pour chaque caractères: 8 pour la couleur, et 8 pour le caractère:

| bits  | significations   |
| ----- | ---------------- |
| 0-7   | caractère ASCII  |
| 8-11  | couleur du texte |
| 12-15 | couleur de fond  |

Les couleurs sont formées comme ceci:

| valeur |                                       couleur                                        |
| ------ | :----------------------------------------------------------------------------------: |
| 0      |            <div style="padding:1rem;background-color: black;">noir</div>             |
| 1      |             <div style="padding:1rem;background-color: blue;">bleu</div>             |
| 2      |      <div style="padding:1rem;background-color: green; color:black;">vert</div>      |
| 3      |       <div style="padding:1rem;background-color: cyan;color:black;">cyan</div>       |
| 4      |       <div style="padding:1rem;background-color: red;color:white;">rouge</div>       |
| 5      |    <div style="padding:1rem;background-color: magenta;color:white;">magenta</div>    |
| 6      |     <div style="padding:1rem;background-color: brown;color:white;">marron</div>      |
| 7      | <div style="padding:1rem;background-color: lightgrey;color:black;">gris clair</div>  |
| 8      |       <div style="padding:1rem;background-color: grey;color:black;">gris</div>       |
| 9      | <div style="padding:1rem;background-color: lightblue;color:black;">bleu clair</div>  |
| 10     | <div style="padding:1rem;background-color: lightgreen;color:black;">vert clair</div> |
| 11     | <div style="padding:1rem;background-color: lightcyan;color:black;">cyan clair</div>  |
| 12     | <div style="padding:1rem;background-color: pink;color:black;">rouge clair/rose</div> |
| 13     | <div style="padding:1rem;background-color: #ff80ff;color:black;">magenta clair</div> |
| 14     |      <div style="padding:1rem;background-color:yellow;color:black;">jaune</div>      |
| 15     |      <div style="padding:1rem;background-color:white;color:black;">blanc</div>       |

# Les framebuffers de pixels

Les framebuffers de pixels sont généralement plus simple, cependant ici nous prenons en compte que si le nombre de bit par pixels sont à 24 ou a 32, car les autres valeurs ne sont plus utilisés.
Il est plus facile d'utiliser un framebuffer de 32 bit de pixels car l'alignement est automatique, mais il utilise 33% plus de mémoire, contre celui à 24 bit par pixels qui économise de la mémoire mais l'accès aux pixels est plus compliquée.

| byte |                          couleur                          |
| ---- | :-------------------------------------------------------: |
| 0    |                 valeur du bleu   (0-255)                  |
| 1    |                 valeur du vert   (0-255)                  |
| 2    |                 valeur du rouge  (0-255)                  |
| 3    | byte utilisé pour l'alignement (seulement quand bpp = 32) |


<img src="/x86_64/assets/frame_buffer_pixels_bpp.svg" style="margin:5rem;padding:1rem;width:64rem;background-color:white;">

L'utilisation d'un framebuffer 32bpp est plus rapide car nous pouvons utiliser le framebuffer comme une table de `uint32_t`, contre le 24bpp ou nous sommes obligé de le convertir en table de `uint8_t` pour ensuite accéder aux couleurs.