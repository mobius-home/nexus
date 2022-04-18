defmodule Nexus.Products do
  @moduledoc """
  Context for working with data within products
  """
  import Ecto.Query

  alias Ecto.Changeset
  alias Nexus.Products.{Device, Tag, Metric, MetricImports, Product}
  alias Nexus.Products.Metric.{Measurement, Upload}
  alias Nexus.{Naming, Repo, Validations}

  @typedoc """
  Options to pass to the tag change set

  * `:key_value` - pass the key value change to the changeset, otherwise not
    changes will be in the changeset.
  """
  @type tag_changeset_opt() :: {:key_value, {Tag.key(), Tag.value()}}

  @typedoc """
  Fields for a measurement
  """
  @type measurement_fields() :: %{
          time: DateTime.t(),
          value: float(),
          tags: [Tag.t()]
        }

  @doc """
  Get a list of products
  """
  @spec all() :: [Product.t()]
  def all() do
    Repo.all(Product)
  end

  @doc """
  Create a new product
  """
  @spec create_product(binary()) :: {:ok, Product.t()} | {:error, Changeset.t()}
  def create_product(product_name) do
    %Product{}
    |> Changeset.change(%{name: product_name})
    |> Changeset.validate_length(:name, max: 50, min: 1)
    |> Changeset.put_change(:slug, Naming.make_slug_from_name(product_name))
    |> Changeset.put_change(
      :data_schema,
      Naming.make_database_identifier_from_name(product_name, postfix: "_data")
    )
    |> Validations.validate_database_identity_name(:data_schema)
    |> Changeset.validate_format(:data_schema, ~r/\w+_data$/)
    |> Changeset.unique_constraint([:name, :slug, :data_schema])
    |> Repo.insert()
  end

  @doc """
  Get a product by the product slug
  """
  @spec get_product_by_slug(Product.slug()) :: Product.t() | nil
  def get_product_by_slug(slug) do
    query = from p in Product, where: p.slug == ^slug

    Repo.one(query)
  end

  @doc """
  Load the metrics associations into the product
  """
  @spec load_product_metrics(Product.t()) :: Product.t()
  def load_product_metrics(product) do
    Repo.preload(product, :metrics)
  end

  @doc """
  Create an empty changeset for a product
  """
  @spec changeset_for_product() :: Changeset.t()
  def changeset_for_product(), do: Changeset.change(%Product{}, %{})

  @doc """
  Create a device for a product
  """
  @spec create_device_for_product(Product.t(), Device.serial_number()) ::
          {:ok, Device.t()} | {:error, Changeset.t()}
  def create_device_for_product(product, serial_number) do
    product
    |> Ecto.build_assoc(:devices)
    |> Changeset.change(%{serial_number: serial_number})
    |> Changeset.validate_length(:serial_number, min: 2, max: 100)
    |> Changeset.put_change(:slug, Naming.make_slug_from_name(serial_number))
    |> Changeset.unique_constraint([:product_id, :serial_number],
      name: :data_pkey,
      match: :suffix,
      message: "device for product already exists"
    )
    |> Repo.insert()
  end

  @doc """
  Get a device for a product using the device's serial number
  """
  @spec get_device_for_product_by_device_slug(Product.t(), Device.slug()) ::
          Device.t() | nil
  def get_device_for_product_by_device_slug(product, device_slug) do
    p_id = product.id

    query = from d in Device, where: d.slug == ^device_slug, where: d.product_id == ^p_id

    Repo.one(query)
  end

  @doc """
  Get all devices for product
  """
  @spec get_devices_for_product(Product.t()) :: [Device.t()]
  def get_devices_for_product(product) do
    p_id = product.id

    query = from d in Device, where: d.product_id == ^p_id

    Repo.all(query)
  end

  @doc """
  Create an empty changeset for a device
  """
  @spec device_changeset() :: Changeset.t()
  def device_changeset() do
    Changeset.change(%Device{}, %{})
  end

  @doc """
  Add a metric to a product

  Before we can record metric data we need to be able to add some data about the
  the measurements first.

  Also, by adding a metric we build a specialized time series time with the
  metric's to handle the massive ingest rate and special time series functions
  if that table does not exist.
  """
  @spec create_metric_for_product(Product.t(), Metric.name(), Metric.type()) ::
          {:ok, Metric.t()} | {:error, Changeset.t()}
  def create_metric_for_product(product, metric_name, metric_type) do
    product
    |> Ecto.build_assoc(:metrics)
    |> Changeset.change(%{name: metric_name, type: metric_type})
    |> Changeset.validate_length(:name, max: 100, min: 2)
    |> Changeset.validate_inclusion(:type, ["last_value", "counter"])
    |> Changeset.put_change(:slug, Naming.make_slug_from_name(metric_name, "", "-#{metric_type}"))
    |> Changeset.put_change(:table_name, Naming.make_database_identifier_from_name(metric_name))
    |> Validations.validate_database_identity_name(:table_name)
    |> Changeset.validate_required([:name, :slug, :type, :table_name])
    |> Changeset.unique_constraint([:product_id, :name, :type],
      name: :metrics_product_id_name_type_table_name_index,
      message: "metric already exists for product"
    )
    |> Repo.insert()
  end

  @doc """
  Get all the metrics for a product
  """
  @spec get_metrics_for_product(Product.t()) :: [Metric.t()]
  def get_metrics_for_product(product) do
    p_id = product.id
    query = from m in Metric, where: m.product_id == ^p_id

    Repo.all(query)
  end

  @doc """
  Get a metric by its slug for a product
  """
  @spec get_metric_for_product_by_slug(Product.t(), Metric.slug()) :: Metric.t() | nil
  def get_metric_for_product_by_slug(product, metric_slug) do
    p_id = product.id
    query = from m in Metric, where: m.product_id == ^p_id, where: m.slug == ^metric_slug
    Repo.one(query)
  end

  @spec get_metric_for_product_by_name_and_type(Product.t(), Metric.name(), Metric.type()) ::
          Metric.t() | nil
  def get_metric_for_product_by_name_and_type(product, metric_name, metric_type) do
    p_id = product.id

    query =
      from m in Metric,
        where: m.product_id == ^p_id,
        where: m.name == ^metric_name,
        where: m.type == ^metric_type

    Repo.one(query)
  end

  @doc """
  Query for a time series list of measurements for a metric for a device
  """
  @spec query_measurements_for_device(Product.t(), Metric.t(), Device.t()) :: [
          Measurement.t()
        ]
  def query_measurements_for_device(product, metric, device) do
    table_name = "#{product.data_schema}.#{metric.table_name}"

    query = """
    SELECT
      time_bucket_gapfill ('60 second',
        time,
        now() - INTERVAL '1 hour',
        now()) AS bucket,
      locf (ROUND(AVG(value))) AS value,
      jsonb(tags)
    FROM
      #{table_name}
    WHERE
      time > now() - INTERVAL '1 hour'
      AND metric_id = $1
      AND device_id = $2
    GROUP BY
      bucket,
      tags
    ORDER BY
      bucket DESC;
    """

    result = Repo.query!(query, [metric.id, device.id])

    Enum.map(result.rows, fn [bucket, value, tags] ->
      %Measurement{
        time: bucket,
        value: value,
        metric_id: metric.id,
        device_id: device.id,
        tags: tags || %{}
      }
    end)
  end

  @doc """
  Create a changeset for a metric
  """
  @spec metric_changeset() :: Changeset.t()
  def metric_changeset() do
    Changeset.change(%Metric{}, %{})
  end

  @doc """
  Create a tag changeset
  """
  @spec tag_changeset([tag_changeset_opt()]) :: Changeset.t()
  def tag_changeset(opts \\ []) do
    case opts[:key_value] do
      nil ->
        Changeset.change(%Tag{}, %{})

      {key, value} ->
        Changeset.change(%Tag{}, %{key: key, value: value})
    end
  end

  @doc """
  Create a tag for a product

  Will create the tag in the database and also provide a mapping record to the
  database for the product.
  """
  @spec create_tag_for_product(Product.t(), Tag.key(), Tag.value()) ::
          {:ok, Tag.t()} | {:error, Changeset.t()}
  def create_tag_for_product(product, key, value) do
    product_with_tags = Repo.preload(product, :tags)

    tag_changeset =
      [key_value: {key, value}]
      |> tag_changeset()
      |> Changeset.change()
      |> Changeset.validate_required([:key, :value])
      |> Changeset.unique_constraint([:key, :value])

    product_with_tags
    |> Changeset.change()
    |> Changeset.put_assoc(:tags, [tag_changeset | product_with_tags.tags])
    |> Repo.update()
  end

  @doc """
  Get a tag by the tag's id
  """
  @spec get_tag_by_id(non_neg_integer()) :: Tag.t() | nil
  def get_tag_by_id(tag_id) do
    query = from t in Tag, where: t.id == ^tag_id

    Repo.one(query)
  end

  @spec get_tag_by_key_value(Tag.key(), Tag.value()) :: Tag.t() | nil
  def get_tag_by_key_value(key, value) do
    query = from t in Tag, where: t.key == ^key, where: t.value == ^value

    Repo.one(query)
  end

  @doc """
  Create a measurement for a metric

  The measurement is tied to a product, device, and metric.
  """
  @spec create_measurement_for_metric(Product.t(), Device.t(), Metric.t(), measurement_fields()) ::
          {:ok, Measurement.t()} | {:error, Changeset.t()}
  def create_measurement_for_metric(product, device, metric, fields) do
    table_name = "#{product.data_schema}.#{metric.table_name}"

    case measurement_changeset(device, metric, fields) do
      {:ok, measurement} ->
        insert_measurement(table_name, measurement)

        {:ok, measurement}

      error ->
        error
    end
  end

  defp measurement_changeset(device, metric, fields) do
    required = [:time, :device_id, :metric_id, :value, :tag_set]

    %Measurement{}
    |> Changeset.change(%{
      time: fields.time,
      metric_id: metric.id,
      value: fields.value,
      device_id: device.id
    })
    |> Changeset.put_change(:tag_set, Enum.map(fields.tags, fn t -> t.id end))
    |> Changeset.validate_required(required)
    |> Changeset.apply_action(:insert)
  end

  defp insert_measurement(table_name, measurement) do
    query = """
    INSERT INTO #{table_name} (time, value, metric_id, device_id, tags)
    VALUES ($1, $2, $3, $4, $5)
    """

    Repo.query!(query, [
      measurement.time,
      measurement.value,
      measurement.metric_id,
      measurement.device_id,
      measurement.tag_set
    ])
  end

  @doc """
  Create a changeset for an upload
  """
  @spec upload_changeset() :: Changeset.t()
  def upload_changeset() do
    Changeset.change(%Upload{}, %{})
  end

  @doc """
  """
  def create_many_tags(tags) do
    Repo.insert_all(Tag, tags, on_conflict: :nothing)

    Enum.map(tags, fn tag ->
      get_tag_by_key_value(tag.key, tag.value)
    end)
  end

  @doc """
  """
  @spec import_upload(Product.t(), Device.t(), Path.t()) :: :ok | {:error, any()}
  def import_upload(product, device, upload_file) do
    MetricImports.run_import_for_device(product, device, upload_file)
  end
end
