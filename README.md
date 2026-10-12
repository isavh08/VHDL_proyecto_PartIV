# Lab 7 – Parte IV: codificador morse con FSM

Codificador de morse para las letras **A–H** hecho con una máquina de estados en
VHDL. Está armado para la **DE2-115** (Cyclone IV E, EP4CE115F29C7).

| Letra | SW2..0 | Morse  |
|-------|--------|--------|
| A     | 000    | `.-`   |
| B     | 001    | `-...` |
| C     | 010    | `-.-.` |
| D     | 011    | `-..`  |
| E     | 100    | `.`    |
| F     | 101    | `..-.` |
| G     | 110    | `--.`  |
| H     | 111    | `....` |

## Cómo se usa

* Con `SW2..0` eliges la letra.
* Picas `KEY1` y se manda la letra por `LEDR0`.
* `KEY0` es el reset.
* El punto prende el LED medio segundo, la raya 1.5 s, y entre símbolos se
  apaga medio segundo.

## Carpetas

```
docs/     diagrama de la FSM y notas de prueba
src/      el VHDL
tb/       testbenches
sim/      scripts para ModelSim
quartus/  proyecto de Quartus 13.1 con los pines
```
