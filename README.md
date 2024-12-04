# Proyecto

### Vidal Aguilar Diego Jesus - 319297591

### Pérez Evaristo Eris 320211162

Programa el cual simula un algoritmo de consenso basado en Proof Of Work, en este uno de los procesadores intentará minar un bloque y añadirlo a la blockchain.

## Instalación
**IMPORTANTE:**
Es necesario que antes de poder correr el programa, elixir cuente con las funciones de ssh, las cuales contiene en modulo de crypto y además, tener una versión estable de estas:
Para tener un referencia clara acerca de las versiones utilizadas:

**Erlang/OTP 26**
**Elixir (1.17.3)**

Una vez cubiertos los puntos anteriores, para poder correr el proyecto es necesario ubicarse en la siguiente carpeta:

```bash
.../proyecto/
```

Una vez ubicados en esta carpeta donde se tenga el archivo **mix.exs** se deberá ejecutar los siguientes comandos:

```bash
$ mix compile
```

```bash
$ iex -S mix
```

Una vez hecho esto, deberá de poderse ejecutar el programa, de modo que podemos usar las siguientes funciones para poder probarlo:

```bash
{:ok, procesadores} = Main.run(5,1)
```

Se recomienda probarlo con pocos procesadores, pues entre más se agregue es más probable que la computadora se sobrecargue de procesos. 

Ahora, para que visualicemos la blockchain que generamos haremos lo siguiente:

```bash
BlockChain.visualizar_blockchain(procesadores)
```

Ahora, seleccionaremos de entre todos los procesadores pondremos a uno el cual sea el encargado de minar. El minado se ha limitado a 4 dígitos de hash, pues entre más dígitos tratemos de encontrar más poder de cómputo se requiere.

```bash
BlockChain.minar(procesadores, "Transaccion 1")
```

Como podremos ver después el bloque minado es agregado al procesador y procede a compararse con las blockchains de los demás, se pondrán de acuerdo para aceptar esta blockchain más larga y así, validar el trabajo de esa transacción

Es posible que ver este proceso de manera detenida si es que **comentamos la linea 169** de **Blockchain.ex**, luego visulizamos la blockchain después del minado, notaremos que hay una con una transacción más y finalmente convocamos el consenso manualmente con:

```bash
BlockChain.comienza_consenso(procesadores)
```