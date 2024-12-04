defmodule Main do
  @moduledoc """
  Módulo encargado de gestionar las funciones principales con las que trabajaremos en nuestra blockchain.
  Este módulo se encargará de generar el modelo de Watts y verificar que sea consistente, es decir, que
  el coeficiente de agrupamiento sea mayor que 0.4 para así poder comenzar con nuestra red, también simula ataques de 
  procesadores maliciosos los cuales intenten agregar un bloque malicioso a nuestra blockchain
  """

  @doc """
  Función encargada de darle vida a toda nuestra blockchain para que podamos trabajar con ella
  verifica que el número de procesos bizantinos sea menor para que podamos realizar nuestro consenso
  """
  def run(n,f) do  
    if n > 3 * f do
      blockchain = BlockChain.new() #Creamos nuestra blockchain
      procesadores = for i <- 1..n do
        spawn_link(fn -> BlockChain.inicio(i) end) #Spawn de todos los procesos que podamos requerir
      end
      construye_mundo(procesadores, n, 4, 0.5) 
      bloque_inicial(procesadores, "Bloque inicial") # Ejecutamos un bloque inicial para todos los procesadores
      {:ok, procesadores} # Devolvemos los procesadores para uso posterior en la terminal, esto es escencial para que observemos el comportamiento
    else
      IO.puts("El numero de procesadores debe ser mayor que el numero de nodos bizantinos")
    end
  end

  
  
  #Función que crea nuestro pequeño mundo con los procesadores, la cantidad de procesadores que tenemos y la probabilidad de 
  #enlace que queremos para crear nuestro mundo. 
  #Asingamos el coeficiente mínimo para la red, como sabemos, esta debe de ser mayor a 0.4 para que podamos trabajar en nuestra red
  defp construye_mundo(procesadores, n, k, p) do
    {:ok, proc_vecinos} = generar_red(n, k, p, 0.4) 
    asignar_vecinos(procesadores, proc_vecinos)
  end

  
  
  #Función que genera la red de procesadores, este se encarga de generar la red con el coeficiente mínimo que requerimos
  #Si el coeficiente no es mayor a 0.4 volvemos a generar la red, pues no nos sirve una inferior a este coeficiente
  defp generar_red(n, k, p, coef_min) do 
    proc_vecinos = Enum.map(1..n, fn id_procesador -> 
      vecinos = vecinos_iniciales(id_procesador, n, k) 
      re_enlace(vecinos, id_procesador, p, n) 
    end)

    coef_agrupamiento = calcular_coef_agrupamiento(proc_vecinos)
    IO.puts("Coeficiente de agrupamiento: #{coef_agrupamiento}")

    if coef_agrupamiento >= coef_min do 
      {:ok, proc_vecinos}
    else 
      IO.puts("El coeficiente es menor, generando una nueva red aleatoria.")
      generar_red(n, k, p, coef_min) 
    end
  end

  
  
  #Función encargada de asignar vecinos a nuestro procesadores
  defp asignar_vecinos(procesadores, proc_vecinos) do 
    pid_vecinos = Enum.map(proc_vecinos, fn vecinos ->
      Enum.map(vecinos, fn id_vecino -> Enum.at(procesadores, id_vecino - 1) end)
    end)
    
    Enum.each(Enum.zip(procesadores, pid_vecinos), fn {pid, pids_vecinos} ->
      send(pid, {:agrega_vecino, pids_vecinos}) 
    end)
  end 

  
  
  #Función encargada de calcular el coeficiente mínimo de los procesadores viendo sus agrupamientos, enlaces,
  #enlaces entre procesadores y calcula el coeficiente para después ver si es que este es válido o no.
  defp calcular_coef_agrupamiento(proc_vecinos) do 
    agrupamientos = Enum.map(proc_vecinos, fn vecinos -> 
      enlaces = for x <- vecinos, y <- vecinos, x < y, do: {x, y} 
      enlaces_encontrados = Enum.count(enlaces, fn {x, y} -> y in Enum.at(proc_vecinos, x - 1) end)
      total_enlaces = length(vecinos) * (length(vecinos) - 1) / 2
      if total_enlaces > 0 do 
        enlaces_encontrados / total_enlaces
      else 
        0.0 
      end 
    end) 
    Enum.sum(agrupamientos) / length(proc_vecinos) 
  end

  
  
  #Función que calcula la lista de vecinos de los procesadores, 
  #el número total de procesadores y el número máximo de vecinos que puede tener.
  #Regresamos la lista de vecinos de cada uno de los procesadores
  defp vecinos_iniciales(id_procesador, n, k) do
    inicio = rem(id_procesador - k - 1, n) + 1
    limite = rem(id_procesador + k - 1, n) + 1
    vecinos = Enum.to_list(inicio..limite)
    vecinos = Enum.filter(vecinos, fn x ->
        x > 0 and x <= n and x != id_procesador
    end)
    Enum.uniq(vecinos)
  end

  
  
  #Función que simula los enlaces aleatorios del mundo de Watts donde se enlaza cada procesador
  #con un vecino aleatorio para así, poder generar conexiones entre procesadores.
  defp re_enlace(vecinos, id_procesador, proba, n) do
    vecinos
    |> Enum.map(fn id_vecino ->
      if :rand.uniform() < proba do
        vecino_nuevo = rem(:rand.uniform(n), n) + 1
        if vecino_nuevo == id_procesador, do: vecino_nuevo + 1, else: vecino_nuevo
      else
        id_vecino
      end
    end)
  end

  
  #Función para insertar el bloque inicial en cada una de las blockchains para que estas no estén vacías pero que generen un hash
  #aleatorio el cual luego enlazaremos con algún bloque minado que hagamos.
  defp bloque_inicial(procesadores, data) do 
    bloque = Block.nuevo_bloque(data, "0000") 
    Enum.each(procesadores, fn pid ->
       send(pid, {:agrega_bloque, bloque}) 
    end) 
  end
end