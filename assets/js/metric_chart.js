import { Chart, registerables } from "chart.js";

class MetricChart {
  constructor(ctx, labels, values) {
    Chart.register(...registerables);

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: "Hello",
            data: values,
            borderColor: "#4c51bf"
          }
        ],
      },
    })
  }

  update(labels, data) {
    this.chart.data.labels = labels;
    this.chart.data.datasets[0].data = data;
  }
}

export default MetricChart;