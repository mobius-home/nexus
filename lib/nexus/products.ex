defmodule Nexus.Products do
  @moduledoc """
  API for working with products
  """

  import Ecto.Query

  alias Ecto.{Changeset, Multi}
  alias InfluxEx.ConflictError
  alias Nexus.Devices.Device
  alias Nexus.{Influx, Repo, Slug}
  alias Nexus.Products.{Product, ProductSettings, ProductToken, Queries}

  @doc """
  Create a new product
  """
  @spec create_product(Product.name()) :: {:ok, Product.t()} | {:error, Changeset.t()}
  def create_product(name) do
    case Influx.create_bucket(name) do
      {:ok, bucket} ->
        create_product_transaction(name, bucket)

      {:error, %ConflictError{}} ->
        changeset =
          %Product{}
          |> Changeset.change(%{})
          |> Changeset.add_error(:name, "already exists")

        {:error, changeset}
    end
  end

  defp create_product_transaction(name, bucket) do
    result =
      Multi.new()
      |> Multi.insert(:product, create_product_changeset(name))
      |> Multi.insert(:product_settings, fn %{product: product} ->
        create_product_settings_changeset(product, bucket.name, bucket.id)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{product: product}} ->
        {:ok, product}

      {:error, _resource, %Changeset{} = changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp create_product_changeset(name) do
    %Product{}
    |> Changeset.change(%{name: name})
    |> Changeset.validate_length(:name, max: 50)
    |> Changeset.put_change(:slug, Slug.make_slug(name))
    |> Changeset.validate_required([:name, :slug])
    |> Changeset.unique_constraint([:name])
  end

  defp create_product_settings_changeset(product, bucket_name, bucket_id) do
    product
    |> Ecto.build_assoc(:product_settings)
    |> Changeset.change(%{bucket_name: bucket_name, bucket_id: bucket_id})
    |> Changeset.validate_required([:bucket_name, :bucket_id])
  end

  @doc """
  Get a product by its slug
  """
  @spec get_by_slug(binary()) :: Product.t() | nil
  def get_by_slug(product_slug) do
    query =
      Queries.from_products()
      |> Queries.join_product_settings()
      |> Queries.where_product_slug(product_slug)
      |> preload([product_settings: ps], product_settings: ps)

    Repo.one(query)
  end

  @doc """
  Delete the product by its id
  """
  @spec delete_product_by_id(integer()) :: :ok | {:error, :not_found | term()}
  def delete_product_by_id(product_id) do
    with %ProductSettings{} = settings <- get_product_settings_by_product_id(product_id),
         :ok <- Influx.delete_bucket(settings.bucket_id) do
      do_delete_product_by_id(product_id)
    else
      nil ->
        # formalize Nexus exceptions
        {:error, :not_found}

      {:error, %InfluxEx.NotFoundError{}} ->
        # if influx does not have the bucket that is okay, try to
        # delete device anyways
        do_delete_product_by_id(product_id)

      error ->
        # do better here
        error
    end
  end

  defp do_delete_product_by_id(product_id) do
    query = from p in Product, where: p.id == ^product_id

    {1, nil} = Repo.delete_all(query)

    :ok
  end

  @doc """
  Get the device settings for a product id
  """
  @spec get_product_settings_by_product_id(integer()) :: ProductSettings.t() | nil
  def get_product_settings_by_product_id(product_id) do
    Queries.from_product_settings()
    |> Queries.where_product_settings_for_product_id(product_id)
    |> Repo.one()
  end

  @doc """
  List all the products
  """
  @spec all() :: [Product]
  def all() do
    Repo.all(Product)
  end

  @doc """
  Create a new device for a product
  """
  @spec create_device(Product.t(), Device.serial_number()) ::
          {:ok, Device.t()} | {:error, Changeset.t()}
  def create_device(product, device_serial) do
    product
    |> Ecto.build_assoc(:devices)
    |> Changeset.change(%{serial_number: device_serial})
    |> Changeset.validate_length(:serial_number, max: 100)
    |> Repo.insert()
  end

  @doc """
  Get a device for a product by the device's serial number
  """
  @spec get_device(Product.t(), Device.serial_number()) :: Device.t() | nil
  def get_device(product, device_serial_number) do
    query =
      from d in Device,
        where: d.product_id == ^product.id,
        where: d.serial_number == ^device_serial_number

    Repo.one(query)
  end

  @doc """
  Get the measurements for a product
  """
  @spec get_measurements(Product.t()) :: {:ok, [binary()]} | {:error, term()}
  def get_measurements(product) do
    Influx.get_bucket_measurements(product.product_settings.bucket_name)
  end

  @doc """
  Get fields for a measurement
  """
  @spec get_measurement_fields(Product.t(), binary()) :: {:ok, [binary()]} | {:error, term()}
  def get_measurement_fields(product, measurement) do
    Influx.get_measurement_fields(product.product_settings.bucket_name, measurement)
  end

  @doc """
  Get the token for a product
  """
  @spec get_token(Product.t()) :: ProductToken.t() | nil
  def get_token(product) do
    query =
      from pt in ProductToken,
        where: pt.product_id == ^product.id,
        join: c in assoc(pt, :creator),
        preload: [creator: c]

    Repo.one(query)
  end

  @doc """
  Delete a product token
  """
  @spec delete_token(ProductToken.t()) :: {:ok, ProductToken.t()} | {:error, Changeset.t()}
  def delete_token(product_token) do
    Repo.delete(product_token)
  end

  @doc """
  Load the token creator association into `:creator` field
  """
  @spec load_token_creator(ProductToken.t()) :: ProductToken.t()
  def load_token_creator(product_token) do
    Repo.preload(product_token, [:creator])
  end

  @type product_token_verify_func() :: (binary() -> {:ok, Product.id()} | {:error, :invalid})

  @doc """
  """
  def verity_token_and_fetch_product(product_slug, token, verifer) do
    with {:ok, product_id} <- verifer.(token),
         %Product{} = product <- fetch_product_with_token(product_id, product_slug, token) do
      {:ok, product}
    else
      _error -> {:error, :invalid}
    end
  end

  defp fetch_product_with_token(product_id, product_slug, token) do
    Queries.from_products()
    |> Queries.join_product_settings()
    |> Queries.join_product_token()
    |> Queries.join_product_token_creator()
    |> Queries.where_product_id(product_id)
    |> Queries.where_product_slug(product_slug)
    |> Queries.where_product_token(token)
    |> preload([product_settings: ps, product_token: pt, product_token_creator: tc],
      product_settings: ps,
      product_token: {pt, [creator: tc]}
    )
    |> Repo.one()
  end
end
