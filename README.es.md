# ListaNegra — Lista negra de jugadores

Add-on para **World of Warcraft: Forever** que guarda listas negras de jugadores y te avisa cuando te los cruzas.

*[Read in English](README.md)*

- **Mundo abierto (PvP):** quien te campea, te gankea o te ataca mientras haces misiones. Al verlo cerca, le pone una calavera encima y te avisa en pantalla con los motivos y cuántas veces te ha matado.
- **Mazmorras / Bandas:** ninjas, gente tóxica, los que abandonan... Te avisa si entran en tu grupo o te invitan.

## Funciones

- Dos listas con **motivos predeterminados** (Ninja, Needea todo, Abandona el grupo, Campea tu cadáver, Mata a niveles bajos...) y una nota libre.
- **Avisos configurables por lista:** cuándo avisar (al verlo cerca; en Mazmorras / Bandas también si entra en tu grupo o te invita), cómo (aviso en pantalla, chat, icono sobre la placa, marca de banda), icono, sonido, color, duración y cada cuánto se repite.
- **Aviso en pantalla** que puedes mover y cambiar de tamaño.
- **Al morir**, te propone añadir al jugador enemigo que parece haberte matado y cuenta las muertes.
- **Clic derecho** en retratos y nombres del chat para añadir, editar o quitar.
- **Tooltip** con la lista y los motivos al pasar el ratón por encima de alguien listado.
- **Icono en el minimapa** (clic: listas · clic derecho: avisos · arrastrar: mover).
- **En español e inglés.** El idioma sigue al de tu cliente del juego.

## Instalación

**Desde CurseForge:** instálalo con la aplicación de CurseForge, o descarga el archivo y sigue el paso 3.

**Desde GitHub:**

1. Descarga el repositorio (**Code → Download ZIP**) y descomprímelo.
2. **Cambia el nombre de la carpeta a `ListaNegra`.** El juego solo carga el add-on si la carpeta se llama igual que el archivo `ListaNegra.toc`; al descargarlo de GitHub se llama `black-list` o `black-list-main`.
3. Muévela a `World of Warcraft\_forever_\Interface\AddOns\`.
4. Cierra y vuelve a abrir el juego, y activa **ListaNegra** en la lista de AddOns de la pantalla de personajes.

## Comandos

Valen `/ln`, `/listanegra` y `/blacklist`.

| Comando | Qué hace |
|---|---|
| `/ln` | Abre o cierra la ventana |
| `/ln avisos` | Ajustes de los avisos |
| `/ln pvp` · `/ln grupo` | Añade a tu objetivo a esa lista |
| `/ln grupo Nombre ninja toxico nota libre` | Añade por nombre con motivos y nota |
| `/ln grupo * ninja` | Igual, con tu objetivo |
| `/ln motivos` | Palabras de los motivos |
| `/ln quitar [pvp o grupo] Nombre` | Quita de una lista (o de las dos) |
| `/ln buscar Nombre` | Dice si alguien está en tus listas |
| `/ln minimapa` | Muestra u oculta el icono del minimapa |
| `/ln prueba [pvp o grupo]` | Enseña un aviso de ejemplo |
| `/ln reset` | Vuelve a centrar las ventanas y el aviso |
| `/ln ayuda` | Lista todos los comandos |

Los comandos en inglés (`alerts`, `reasons`, `remove`, `search`, `minimap`, `test`, `help`) también funcionan.

También aparece en **Opciones → AddOns → Lista Negra**, con accesos a las listas y a los ajustes.

## Limitaciones de WoW: Forever

WoW: Forever usa el motor de Midnight, con restricciones para los add-ons:

- **El registro de combate no está disponible.** "Quién te ha matado" se deduce del jugador enemigo que te tenía en el objetivo en los últimos segundos, por eso pregunta antes de añadirlo.
- **En instancias, campos de batalla y arenas** el juego puede ocultar la identidad de los jugadores; ahí no se les reconoce.
- **La detección cercana usa las placas de nombre:** actívalas para enemigos (tecla V). Sin ellas solo se detecta al seleccionar a alguien o pasarle el ratón por encima.
- Si el juego no deja poner **marcas de banda**, el add-on las desactiva solo y sigue usando su icono propio sobre la placa.

## Traducción

Todos los textos pasan por `L["..."]` y la clave es el texto en inglés. La traducción al español está en `Locales/esES.lua`.

## Licencia

[MIT](LICENSE)
