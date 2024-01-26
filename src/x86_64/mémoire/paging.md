# Le Paging

Le paging est une manière en 64bit de gérer la mémoire virtuelle à travers le MMU (memory management unit). Le paging permet de faire passer l'accès de la mémoire par un adressage virtuel. Pour cela en x86 on divise la mémoire par block que l'on appelle des **pages** elle font généralement 4096bytes mais on peut leur donner une taille de 2M ou voir plus. 

C'est comme si on avait un livre sauf qu'a chaque fois que l'on veut regarder une page, on devait regarder le sommaire pour transformer la page que l'on souhaiterais avoir en une vrai page du livre.
Par exemple pour le sommaire:

1 -> 56
2 -> 78
3 -> 90

Pour lire la page *virtuelle* 3 on devrait aller à la 90e vrai page du livre (la page physique).

On pourrait avoir différent sommaires situés dans le livre, par exemple:

Sommaire d'alice situé à la page 1 (physique):
1 -> 36
2 -> 78
3 -> 91
Sommaire de david situé à la page 2 (physique)
1 -> 48
2 -> 79
3 -> 10

C'est comme si david et alice avaient chacun un livre virtuel composé d'un seul vrai livre physique.

Si alice et david utilisent le livre seulement par se sommaire alors on a une sécurité garantie que david ne peux pas toucher les pages qu'il ne devrait pas toucher (ex: celles d'alice). 

Si david aimerait avoir une nouvelle page qui continue son livre virtuel, on est pas obligé de prendre une page qui continue dans le livre physique: 

1 -> 48
2 -> 78
3 -> 10
4 -> 11

ou bien

1 -> 48
2 -> 78
3 -> 10
4 -> 22

la 4e page virtuelle peut rediriger vers n'importe quel page physique non utilisé.

Si David et Alice aimeraient partager une page sur le développement d'un kernel open source. Ils le peuvent ! 

Ils doivent juste lier leurs page virtuelles vers cette page physique partagée: 

Alice:

1 -> 36
2 -> 78
3 -> **22** (ici la page partagée)
4 -> 91

1 -> 48
2 -> 79
3 -> 10
4 -> **22** (ici la page partagée)
