defmodule Nexus.ProductsTest do
  use Nexus.DataCase

  alias Nexus.{Products, Repo}
  alias Nexus.Products.{Device, Metric, Product}

  describe "creating a new product" do
    test "when everything is okay" do
      {:ok, %Product{} = product} = Products.create_product("best product ever")

      assert product.name == "best product ever"
      assert product.data_schema == "best_product_ever_data"
      assert product.slug == "best-product-ever"
    end

    test "with invalid name format" do
      assert {:error, changeset} = Products.create_product("SELECT * FROM")

      assert "special characters are not allowed in name" in errors_on(changeset).name
    end

    test "trying to create the same product twice" do
      name = "so many of this product"
      assert {:ok, %Product{}} = Products.create_product(name)
      assert {:error, changeset} = Products.create_product(name)

      assert "has already been taken" in errors_on(changeset).name
    end

    test "after creation the data schema is created" do
      {:ok, %Product{} = product} = Products.create_product("best product ever")

      schemas =
        Repo.query!("SELECT schema_name FROM information_schema.schemata")
        |> Map.get(:rows)
        |> Enum.flat_map(fn r -> r end)

      assert product.data_schema in schemas
    end
  end

  describe "querying products" do
    test "get existing product by slug" do
      {:ok, %Product{} = product} = Products.create_product("the product")

      assert Products.get_product_by_slug(product.slug) == product
    end

    test "get non-existing product by slug" do
      assert Products.get_product_by_slug("this-one-does-not-exists") == nil
    end

    test "list all products" do
      product_names = ["hello", "world"]

      for product_name <- product_names do
        assert {:ok, product} = Products.create_product(product_name)

        product
      end

      all_products = Products.all()

      for product <- all_products do
        assert product.name in product_names
      end
    end

    test "list all products empty" do
      assert [] == Products.all()
    end
  end

  describe "product device creation" do
    test "when everything is ok" do
      device_serial = "ABC123"
      {:ok, product} = Products.create_product("My Product")

      assert {:ok, %Device{} = device} =
               Products.create_device_for_product(product, device_serial)

      assert device.serial_number == device_serial
      assert device.slug == "abc123"
      assert device.product_id == product.id
    end

    test "many devices for a product" do
      {:ok, product} = Products.create_product("My Product")

      for serial <- ["ABC1234", "ABC1235"] do
        assert {:ok, %Device{} = device} = Products.create_device_for_product(product, serial)

        assert device.serial_number == serial
      end
    end

    test "when devices is already created for a product" do
      device_serial = "ABC123"
      {:ok, product} = Products.create_product("My Product")

      assert {:ok, %Device{}} = Products.create_device_for_product(product, device_serial)

      assert {:error, changeset} = Products.create_device_for_product(product, device_serial)
      assert "device for product already exists" in errors_on(changeset).product_id
    end
  end

  describe "create a metric" do
    test "when everything is okay" do
      {:ok, product} = Products.create_product("My Product With Metrics")

      assert {:ok, %Metric{} = metric} =
               Products.create_metric_for_product(product, "vm.memory.total", "last_value")

      assert metric.name == "vm.memory.total"
      assert metric.slug == "vm-memory-total-last-value"
      assert metric.table_name == "vm_memory_total"
      assert metric.type == "last_value"
      assert metric.product_id == product.id

      # Ensure the hyper table was created
      query = """
      SELECT concat(hypertable_schema, '.', hypertable_name) as hypertables
      FROM timescaledb_information.hypertables;
      """

      htables =
        query
        |> Repo.query!()
        |> Map.get(:rows)
        |> Enum.flat_map(fn r -> r end)

      expected_htable = "#{product.data_schema}.#{metric.table_name}"

      assert expected_htable in htables
    end

    test "allows many different types of metrics for a product" do
      {:ok, product} = Products.create_product("My Product With Metrics")

      assert {:ok, %Metric{} = metric} =
               Products.create_metric_for_product(product, "vm.memory.total", "last_value")

      assert {:ok, %Metric{} = metric2} =
               Products.create_metric_for_product(product, "vm.memory.total", "counter")

      metrics = Products.get_metrics_for_product(product)

      for m <- metrics do
        assert m in [metric, metric2]
      end
    end

    test "when the metric type for a metric already exists" do
      {:ok, product} = Products.create_product("My Product With Metrics")

      assert {:ok, %Metric{}} =
               Products.create_metric_for_product(product, "vm.memory.total", "last_value")

      assert {:error, changeset} =
               Products.create_metric_for_product(product, "vm.memory.total", "last_value")

      assert "metric already exists for product" in errors_on(changeset).product_id
    end
  end
end
