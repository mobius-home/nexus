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
      // options: {
      //   scales: {
      //     y: {
      //       suggestedMin: 50,
      //       suggestedMax: 200,
      //     },
      //   },
      // }
    })
  }
}

export default MetricChart;