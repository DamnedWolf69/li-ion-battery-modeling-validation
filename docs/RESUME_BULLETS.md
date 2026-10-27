# CV — Harvard XYZ bullets (quantities verified on included NASA data)

**Project title:** Lithium-Ion Battery SOC & Randles-Circuit Modeling | MATLAB, Python

Select **two** bullets for a one-page A4 CV:

- **Built** a MATLAB one-RC Randles battery model with aging-aware coulomb counting, using NASA B0005 data and a chronological **134-train/34-test** validation protocol.
- **Reduced** end-of-discharge SOC **proxy** MAE by **92.1%** (**27.80 → 2.19 percentage points**) by forecasting capacity from historical discharges instead of assuming fixed battery capacity.

Optional **third** bullet (especially relevant for battery/BMS/data-science roles):

- **Forecasted** measured Li-ion discharge capacity at **2.12% MAPE** and **27.92 mAh MAE** across **34 unseen aging cycles** using a training-only 40-cycle linear fit.

## Accuracy of these claims

- This is a *capacity-based EOD SOC proxy*, **not** externally sensed SOC.
- The quoted 92.1%, 2.19 pp, 27.92 mAh and 2.12% are calculated from the
  included **168 experimental discharge-capacity values**, not made up.
- Avoid saying “SOC prediction accuracy 97.81%” — MAE is not classification
  accuracy and there is no direct SOC sensor ground truth.
- The MATLAB ECM voltage generalization will be separately scored after
  running `matlab/run_project.m` with the official source MAT file. Until then,
  **do not claim a voltage RMSE or identified physical resistance accuracy**.
- A4 line length depends on font/margins; bullets are intended as concise
  one- to two-line entries rather than a guaranteed edge-to-edge length.
