defmodule Block do
  @moduledoc """ 
  Modulo encargado de la creación y validación de bloques en una blockchain.
  :data         - Infomación del bloque. 
  :timestamp    - Tiempo en el que el bloque fue creado 
  :prev_hash    - hash del bloque anterior en la blockchain. 
  :hash         - hash del bloque actual. 
  """
  defstruct [:data, :timestamp, :prev_hash, :hash]

  @doc """
  Función encargada de generar un nuevo bloque
  """
  def nuevo_bloque(data, prev_hash) do
    timestamp = :os.system_time(:millisecond)
    hash = Crypto.hash(%{data: data, timestamp: timestamp, prev_hash: prev_hash})
    %Block{
      data: data, 
      timestamp: timestamp, 
      prev_hash: prev_hash, 
      hash: hash}
  end

  @doc """
  Función encargada de ver si un bloque es válido.
  Este verá si es que el bloque es válido viendo que el hash esperado sea el correcto para poder validarlo.
  """
  def bloque_valido?(%Block{hash: hash} = bloque) do
    expected_hash = Crypto.hash(%{data: bloque.data, timestamp: bloque.timestamp, prev_hash: bloque.prev_hash})
    hash == expected_hash
  end

  @doc """
  Verifica que dos bloques consecutivos A y B sean validos para poder ser insertados de forma consecutiva
  """
  def bloque_valido?(%Block{} = bloqueA, %Block{} = bloqueB) do
    bloqueB.prev_hash == bloqueA.hash and bloque_valido?(bloqueB)
  end
end 