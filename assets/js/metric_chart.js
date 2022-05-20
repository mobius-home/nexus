import { Chart, registerables } from "chart.js";

class MetricChart {
  constructor(ctx, labels, datasets) {
    Chart.register(...registerables);

    const datasets_with_color = datasets.map(this.datasetWithColor);

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: datasets_with_color
      },
      options: {
        plugins:{   
          legend: {
            display: false
          }
        }
      }
    })
  }

  update(labels, datasets) {
    const datasets_with_color = datasets.map(this.datasetWithColor);
    this.chart.data.labels = labels;
    this.chart.data.datasets = datasets;
  }

  datasetWithColor(dataset) {
    dataset["borderColor"] = "#4c51bf"

    return dataset
  }
}

export default MetricChart;