import csv
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from benchmark_capacity import compute, forecast_capacities
import numpy as np

class CapacityBenchTests(unittest.TestCase):
    def test_measured_observation_count(self):
        with (ROOT/'data/processed/B0005_discharge_capacity.csv').open() as f:
            rows=list(csv.DictReader(f))
        self.assertEqual(len(rows), 168)
        self.assertEqual([int(r['discharge_index']) for r in rows],list(range(1,169)))
        self.assertAlmostEqual(float(rows[0]['capacity_ah']), 1.8564874208181574)
        self.assertAlmostEqual(float(rows[-1]['capacity_ah']), 1.3250793286429356)

    def test_no_future_labels_in_capacity_forecast(self):
        x=np.arange(1,169)
        q=1.9-0.003*x.astype(float)
        q2=q.copy(); q2[134:]=999.0
        pred1,_=forecast_capacities(x,q)
        pred2,_=forecast_capacities(x,q2)
        np.testing.assert_array_equal(pred1,pred2)

    def test_regression_against_measured_records(self):
        metrics=compute()
        self.assertEqual(metrics['train_cycles'],134)
        self.assertEqual(metrics['test_cycles'],34)
        self.assertAlmostEqual(metrics['test_capacity_mape_pct_trend'],2.1195385814098024,places=8)
        self.assertAlmostEqual(metrics['test_eod_soc_proxy_mae_percentage_points_trend'],2.1925912841894397,places=8)
        self.assertLess(metrics['test_eod_soc_proxy_mae_percentage_points_trend'],
                        metrics['test_eod_soc_proxy_mae_percentage_points_fixed'])

if __name__=='__main__':
    unittest.main()
