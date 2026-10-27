#!/usr/bin/env python3
"""Reproducible empirical B0005 capacity / endpoint-SOC-proxy benchmark.

No voltage simulation or SOC sensor is involved. Fixed chronologic 134/34 split.
This is a *capacity-based endpoint proxy*, not an independently sensed SOC.
"""
from __future__ import annotations
import csv
import json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/processed/B0005_discharge_capacity.csv'
OUT = ROOT / 'results'


def forecast_capacities(index, capacities, n_train=134, trailing=40):
    """Fit simple capacity-vs-cycle linear trend on trailing training cycles ONLY."""
    assert len(index) == len(capacities) and 0 < trailing <= n_train < len(index)
    coef = np.polyfit(index[n_train - trailing:n_train],
                      capacities[n_train - trailing:n_train], 1)
    pred = np.polyval(coef, index[n_train:])
    return np.maximum(pred, 0.3), coef


def compute():
    with DATA.open(newline='') as f:
        rows = list(csv.DictReader(f))
    index = np.array([int(r['discharge_index']) for r in rows], dtype=int)
    cap = np.array([float(r['capacity_ah']) for r in rows])
    assert len(index) == 168 and np.array_equal(index, np.arange(1, 169))
    assert np.isfinite(cap).all() and (cap > 0).all()
    n_train = 134
    train = cap[:n_train]
    test = cap[n_train:]
    baseline_q = float(np.median(train[:10]))
    pred_linear, coeffs = forecast_capacities(index, cap, n_train)
    pred_fixed = np.full_like(test, baseline_q)

    # At measured end of the discharge to NASA's cutoff, SOC reference is
    # defined as zero. A capacity-calibrated coulomb counter predicts SOC_end
    # ~= 1 - measured_discharge_Ah / estimated_capacity_Ah. Use *unclipped*
    # residuals to avoid masking capacity-mismatch bias.
    eod_fixed = 100 * (1 - test / pred_fixed)
    eod_linear = 100 * (1 - test / pred_linear)
    metrics = {
        'source': 'NASA B0005 measured discharge capacities; see data/PROVENANCE.md',
        'split': 'first 134 train, final 34 test (chronological)',
        'total_discharge_cycles': len(index), 'train_cycles': n_train,
        'test_cycles': len(test),
        'capacity_initial_ah': float(cap[0]),
        'capacity_final_ah': float(cap[-1]),
        'observed_capacity_change_pct': float(100 * (cap[-1]/cap[0] - 1)),
        'baseline_capacity_ah': baseline_q,
        'trend_slope_ah_per_discharge_cycle': float(coeffs[0]),
        'test_capacity_mae_mah_fixed': float(1000*np.mean(np.abs(pred_fixed-test))),
        'test_capacity_mae_mah_trend': float(1000*np.mean(np.abs(pred_linear-test))),
        'test_capacity_rmse_mah_trend': float(1000*np.sqrt(np.mean((pred_linear-test)**2))),
        'test_capacity_mape_pct_trend': float(100*np.mean(np.abs(pred_linear-test)/test)),
        'test_eod_soc_proxy_mae_percentage_points_fixed': float(np.mean(np.abs(eod_fixed))),
        'test_eod_soc_proxy_mae_percentage_points_trend': float(np.mean(np.abs(eod_linear))),
        'test_eod_soc_proxy_rmse_percentage_points_trend': float(np.sqrt(np.mean(eod_linear**2))),
        'validation_kind': 'empirical capacity / EOD SOC proxy; NOT direct SOC or voltage validation',
    }
    OUT.mkdir(exist_ok=True, parents=True)
    (OUT / 'figures').mkdir(exist_ok=True)
    with (OUT / 'capacity_holdout_predictions.csv').open('w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['discharge_index','measured_capacity_ah','fixed_capacity_ah','predicted_capacity_ah',
                    'eod_soc_proxy_error_pp_fixed','eod_soc_proxy_error_pp_trend'])
        for vals in zip(index[n_train:], test, pred_fixed, pred_linear, eod_fixed, eod_linear):
            w.writerow([f'{v:.9f}' for v in vals])
    (OUT / 'capacity_metrics.json').write_text(json.dumps(metrics, indent=2) + '\n')

    plt.figure(figsize=(10, 5.5))
    plt.plot(index, cap, '-', linewidth=1.7, label='NASA measured capacity')
    plt.axvline(n_train + 0.5, ls='--', color='0.4', label='Chronological split')
    plt.plot(index[n_train:], pred_linear, ls='-', label='Train-only linear capacity forecast')
    plt.plot(index[n_train:], pred_fixed, ls=':', label='Fresh-cell fixed capacity')
    plt.xlabel('Discharge cycle index'); plt.ylabel('Discharge capacity (Ah)')
    plt.title('NASA B0005 | Measured capacity and held-out prediction')
    plt.grid(alpha=0.25); plt.legend(); plt.tight_layout()
    plt.savefig(OUT / 'figures/capacity_holdout.png', dpi=180)
    plt.close()

    plt.figure(figsize=(9, 4.5))
    plt.plot(index[n_train:], eod_fixed, label='Fixed fresh-cell capacity')
    plt.plot(index[n_train:], eod_linear, label='Train-only capacity forecast')
    plt.axhline(0, color='0.35', linewidth=1, ls='--')
    plt.ylabel('EOD SOC proxy residual (percentage points)')
    plt.xlabel('Held-out discharge cycle index')
    plt.title('Capacity-based SOC drift at measured end-of-discharge')
    plt.grid(alpha=0.25); plt.legend(); plt.tight_layout()
    plt.savefig(OUT / 'figures/eod_soc_proxy.png', dpi=180)
    plt.close()

    for k,v in metrics.items(): print(f'{k}: {v}')
    return metrics

if __name__ == '__main__':
    compute()
