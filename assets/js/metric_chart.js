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
    datasets.map(this.datasetWithColor);

    this.chart.data.labels = labels;
    this.chart.data.datasets = datasets;
  }

  updateTwo(labels, datasets) {
    this.updateChartLabels(this.chart, labels);
    this.updateChartDatasets(this.chart, datasets);

    this.chart.update();
  }

  updateChartLabels(chart, labels) {
    labels.forEach(label => chart.data.labels.push(label));
  }

  updateChartDatasets(chart, datasets) {
    datasets.forEach(dataset => {
      this.updateChartDataset(chart, dataset.label, dataset.data)
    })
  }

  updateChartDataset(chart, label, datas) {
    datas.forEach(dataPoint => {
      chart.data.datasets[label].data.push(dataPoint);
    });
  }
    
  datasetWithColor(dataset) {
    dataset["borderColor"] = "#4c51bf"

    return dataset
  }
}

export default MetricChart;