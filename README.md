# DJI Neo Charging Dock Monitor

Un outil de diagnostic en temps réel pour le hub de charge du **DJI Neo**, écrit en PowerShell. 
Ce script intercepte la télémétrie série brute (UART/USB VCP) émise par le dock pour surveiller l'état des cellules et émettre une alerte sonore (BIP) à **58%**, le seuil idéal pour le stockage de longue durée (*Storage Mode*).

## Découverte Technique
Lorsqu'il est branché sur un PC Windows, le hub de charge DJI Neo est reconnu comme un périphérique série virtuel (`USB\VID_2CA3&PID_5740`). Bien que DJI Assistant 2 refuse de communiquer avec lui, le dock crache en continu un flux de télémétrie textuelle à **9600 bauds**.

## Fonctionnalités
- Affichage ASCII en colonnes respectant la disposition physique du dock (`[SLOT 2] [SLOT 1] [SLOT 0]`).
- Lecture asynchrone ultra-rapide pour éviter l'engorgement du buffer série de Windows.
- Suivi en temps réel de l'état de charge (SOC %), de la tension (V), de la température (°C) et du courant (mA).
- Indicateur de fraîcheur du signal (Heartbeat) par slot avec nettoyage automatique sous 5 secondes en cas de déconnexion à chaud.
- Alerte sonore (BIP système) dès qu'une batterie atteint 58% en charge.

## Utilisation
1. Branchez votre dock DJI Neo à votre PC via son port USB-C.
2. Identifiez son port COM dans le Gestionnaire de périphériques (ex: `COM3`).
3. Modifiez la variable `$portName = "COM3"` au début du script si nécessaire.
4. Exécutez le script dans PowerShell.
