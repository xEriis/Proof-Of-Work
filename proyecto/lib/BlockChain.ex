defmodule BlockChain do
  @moduledoc """
    Modulo encargado de la gestión de la cadena de bloques y el consenso de nuestra red.
    Este módulo será la parte central de nuestro programa pues carga con la lógica de la insersión,
    actualización y manejo de nuestra blockchain.
    """
  defstruct bloques: [], prev_hash: nil

  @doc """
  Función que crea nuestra blockchain vacía con un hash previo el cual ocuparemos para insertar el bloque inicial
  """
  def new do
    %BlockChain{bloques: [], prev_hash: "0000"}
  end

  @doc """
  Función encargada de agregar un bloque a la blockchain verificando que este sea válido para así, enlazarlo en la blockchain
  y seguir construyendo la secuencia de esta.
  """
  def agregar(%BlockChain{bloques: []} = blockchain, bloque) do
    %BlockChain{blockchain | bloques: [bloque], prev_hash: bloque.hash}
  end

  def agregar(%BlockChain{bloques: bloques} = blockchain, bloque) do
      bloque_ant = List.last(bloques)
    if Block.bloque_valido?(bloque_ant, bloque) do
        %BlockChain{blockchain | bloques: bloques ++ [bloque], prev_hash: bloque.hash}
    else
      {:error, "Bloque no válido"}
    end
  end


  @doc """
  Función encargada de verficar  la validez de dos bloques, si es que son validos dará paso
  a insertar el bloque nuevo a la blockchain
  """
  def blockchain_valida?(%BlockChain{bloques: [_ | _] = bloques}) do
      Enum.chunk_every(bloques, 2, 1, :discard)
      |> Enum.all?(fn [a, b] -> Block.bloque_valido?(a, b) end)
  end

  @doc """
  Función encargada de inicializar las blockchains generando las nuevas blockchains y darnos el estado inicial de cada una.
  """
  def inicio(id) do
    estado = %{
      id: id,
      blockchain: BlockChain.new(),
      vecinos: []
    }
    IO.puts("Procesador #{estado.id} tiene la blockchain inicial: #{inspect(estado.blockchain)}")
    recibe_mensaje(estado)
  end

  @doc """
  Función que gestiona los mensajes entre los procesadores, durante las insersiones de nuevos bloques,
  agregar vecinos, responder con su propia blockchain, responder, proponer su propia blockchain, actualizar y notificar
  acerca de mensajes erroneos que puedan recibir
  """
  def recibe_mensaje(estado) do
    receive do
      {:agrega_bloque, bloque} ->
        IO.puts("¡Procesador #{estado.id} agregó un bloque!")
        estado = %{estado | blockchain: BlockChain.agregar(estado.blockchain, bloque)}
        recibe_mensaje(estado)
    
      {:agrega_vecino, vecinos} ->
        IO.puts("Procesador #{estado.id} ha delimitado sus vecinos")
        estado = %{estado | vecinos: vecinos}
        recibe_mensaje(estado)
      
      {:get_blockchain, caller} -> 
        send caller, {:blockchain, estado.blockchain} 
        recibe_mensaje(estado)
      
      {:propuesta_blockchain, blockchain_propuesta, caller} -> 
        bloques_a_comparar = List.delete_at(blockchain_propuesta.bloques, -1) 
        bloques_actuales = Enum.take(estado.blockchain.bloques, length(bloques_a_comparar)) 
        if comparaBloques(bloques_a_comparar, bloques_actuales) do
	 #if bloques_a_comparar == bloques_actuales do
          send(caller, {:voto, true}) 
          IO.puts("Procesador #{estado.id} está de acuerdo con la propuesta.") 
        else
	  send(caller, {:voto, false}) 
          IO.puts("Procesador #{estado.id} no está de acuerdo con la propuesta.") 
	end 
        recibe_mensaje(estado)
      
      {:actualiza_blockchain, nueva_blockchain} -> 
        IO.puts("Procesador #{estado.id} actualiza su blockchain.") 
        estado = %{estado | blockchain: nueva_blockchain} 
        recibe_mensaje(estado)
  
      msg ->
      IO.puts("Procesador #{estado.id} recibió algo extraño #{inspect(msg)}") 
      IO.inspect(msg) 
      recibe_mensaje(estado)
      end
  end

  #Funcion encargada de hacer comparaciones entre los bloques sin importar el tamaño de estos, si son iguales regresa True 
  def comparaBloques(bloqueA, bloqueB) do
      if bloqueA == bloqueB do
      	 true
      else
	if bloqueA == [] do
	   false
	else
	  comparaBloques(List.delete_at(bloqueA,-1),bloqueB)
	end
      end
  end
  
  #Función encargada de obtener el hash del bloque anterior para poder tener la consistencia entre los bloques de nuestra blockchain
  defp hash_bloque_prev(procesadores) do 
    pid = List.first(procesadores) 
    send(pid, {:get_blockchain, self()}) 
    receive do 
      {:blockchain, %BlockChain{prev_hash: prev_hash}} -> 
        prev_hash 
    end 
  end
  
  
  
  #Función encargada de agregar los bloques en nuestra blockchain
  defp agregar_bloque(procesadores, data) do
    hash_anterior = hash_bloque_prev(procesadores)
      bloque = Block.nuevo_bloque(data, hash_anterior) 
      Enum.each(procesadores, fn pid -> 
      send(pid, {:agrega_bloque, bloque}) 
    end) 
    :ok
  end
  
  @doc """
  Función encargada de mostrar la blockchain de cada uno de los procesadores
  de modo que generará la secuencia de los bloques en la blockchain
  """
  def visualizar_blockchain(procesadores) do 
    Enum.each(procesadores, fn pid -> 
      send(pid, {:get_blockchain, self()}) 
    end) 
    Enum.each(procesadores, fn _pid ->
      receive do 
        {:blockchain, blockchain} -> 
          IO.inspect(blockchain) 
        end 
    end) 
  end
  
  @doc """
  Función encargada del minado de bloques dentro de nuestra blockchain, por razones de 'seguridad' bajamos a que solo sea necesario
  adivinar 4 de los hashes, para que el proceso sea rápido de visualizar y además, no requiera de un poder de cómputo masivo
  pues entre más cantidad de hashes puede llegar a ser más difícil adivinarlo.
  """
  def minar(procesadores, data) do
    procesador = Enum.random(procesadores) 
    IO.puts("El procesador elegido para adivinar el hash del bloque generado es el #{inspect(procesador)}")
    send(procesador, {:get_blockchain, self()}) 
    receive do 
      {:blockchain, %BlockChain{prev_hash: prev_hash}} -> 
        bloque = Block.nuevo_bloque(data, prev_hash)
        minar_bloque(procesador, bloque) 
        send(procesador, {:agrega_bloque, bloque}) 
        IO.puts("He terminado de minar un bloque por lo que mi blockchain es más larga. Ahora conovocaré a un consenso para que validen mi trabajo.")
    end
    comienza_consenso(procesadores)
  end
  
  #Función encargada de minar un bloque, genera un bloque nuevo con el hash anterior de su blockchain
  #Dirá que el bloque ha sido minado cuando el hash que adivina sea igual al hash del bloque generado
  #Es decir, este hará una simulación de POW tratando de adivinar un bloque
  defp minar_bloque(procesador, bloque) do
    IO.puts("El bloque a deducir su hash es: #{inspect(bloque)}") 
    Enum.reduce_while(1..round(:math.pow(16, 4)), :ok, fn _, acc ->
      hash_adivinado = :crypto.strong_rand_bytes(2) |> Base.encode16(case: :upper) |> String.slice(0, 4)
      if hash_adivinado == bloque.hash do 
        IO.puts("Procesador #{inspect(procesador)} adivinó el hash: #{hash_adivinado}")  
        {:halt, acc} 
      else 
        {:cont, acc}
      end 
    end)
  end

  #Función encargada del consenso de nuestro procesadores
  #Todos ven sus blockchains y comparan si es que los bloques anteriores son iguales, porque de serlo así
  #Entonces podemos adaptar todas las blockchains, sino, entonces lo que haremos será poner estos en desacuerdo.
  #El objetivo es que todos los procesadores se pongan de acuerdo, validen la blockchain más larga comparandola con la suya
  #una vez estén de acuerdo, se actualizan.
  def comienza_consenso(procesadores) do

    Enum.each(procesadores, fn pid ->
      send(pid, {:get_blockchain, self()}) 
    end)

    blockchains = Enum.map(procesadores, fn _ ->
      receive do
        {:blockchain, blockchain} -> blockchain
      end
    end)
    
    #blockchain_mas_larga = Enum.max_by(blockchains, fn %BlockChain{bloques: bloques} -> length(bloques) end)

    blockchain_mas_larga = Enum.reduce(blockchains, fn bc1, bc2 ->
    	cond do
	  length(bc1.bloques) > length(bc2.bloques) -> bc1
	  length(bc1.bloques) < length(bc2.bloques) -> bc2
	  true ->
	       timestamp1 = List.last(bc1.bloques).timestamp
	       timestamp2 = List.last(bc2.bloques).timestamp
	       if timestamp1 <= timestamp2, do: bc1, else: bc2
	end	
    end)

    Enum.each(procesadores, fn pid ->
      send(pid, {:propuesta_blockchain, blockchain_mas_larga, self()})
    end)
  
    votos = Enum.map(procesadores, fn _ ->
      receive do
        {:voto, acuerdo} -> acuerdo
      end
    end)

    if Enum.count(votos, fn x -> x end) > div(length(procesadores), 2) do 
      Enum.each(procesadores, fn pid -> 
        send(pid, {:actualiza_blockchain, blockchain_mas_larga}) 
      end) 
      IO.puts("¡El consejo ha decidido validar tu trabajo!") 
    else 
      IO.puts("No fue posible que validaran tu trabajo ):") 
    end 
  end

end 