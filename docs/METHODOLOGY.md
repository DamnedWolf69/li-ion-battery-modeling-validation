# Methods and statistical claims

## 1. Physics model

Discharge-positive current, with initial `SOC(0)=1` per independently
recorded full-charge/discharge protocol:

\[
  z(t) = \operatorname{clip}_{[0,1]}\left(1-\frac{1}{3600Q_\mathrm{est}}
                            \int_0^t I(u)\,du\right)
\]

\[
 \frac{dv_1}{dt}=-\frac{v_1}{R_1 C_1}+\frac{I}{C_1},\qquad
 V_\mathrm{pred}(t)=\mathrm{OCV}(z(t))-I(t)R_0-v_1(t).
\]

The RC update is an exponential (exact for constant input per interval) with
trapezoid-averaged current in each nonuniform interval. The OCV mapping is a
piecewise-linear, 11-knot lookup interpolated from **training data only**.
Values in the user's original 2.5 Ah demo were illustrative. NASA B0005 is a
different nominal-capacity cell, so the original calibration is **not reused
as if it were real cell data**.

### Identifiability warning

Constant-current discharge alone does not uniquely separate physical
open-circuit voltage, ohmic resistance, charge-transfer resistance and
capacitance. A regularized fit seeded at R0=0.05 ohm, R1=0.02 ohm and
R1*C1=20 s estimates an **effective one-RC representation**, not a
manufacturer-grade independently identified electrochemical parameter set.
The OCV knots are also *effective* (voltage-derived under load), not a truly
rested OCV-SOC measurement. Do not put physical resistance-accuracy claims on a
resume from this experiment. Stronger parameter identification requires pulse
or relaxation profiles and actual rest measurements.

## 2. Capacity aging forecast

- Dataset: B0005 measured discharge capacities (Ah), chronological order.
- Train first 134/168 discharges; test final 34/168 (no shuffled split).
- Calibrate baseline capacity with **median of first 10 training capacities**.
- Fit a degree-1 curve to training discharge indices **95–134** only.
- Extrapolate predicted capacity at 135–168, lower bounded at 0.3 Ah.
- Compare to held-out measured NASA discharge capacities with mAh MAE, RMSE
  and percent MAPE. No test labels used during forecast fitting.

## 3. SOC validation with available measurements

A full charge begins each recorded discharge. Under the capacity-referenced
usable SOC convention, the **end-of-discharge reference is defined as zero**.
A capacity-calibrated coulomb counter ending after measured removed charge
`Q_meas` predicts

\[
 z_\mathrm{end,pred}=1-Q_\mathrm{meas}/Q_\mathrm{pred}.
\]

For a *fixed* fresh-cell capacity, substitute the fixed training-only
baseline. Report **unclipped** endpoint errors in percentage points, because
clipping at 0 can conceal overshoot. The actual EOD charge amount is based on
measured NASA discharge capacity, **not** the Randles simulation.

This is *not* directly measured ground-truth SOC; the reference is an
experimental discharge-capacity-based proxy (dependent on temperature,
cutoff and charge history). The simple endpoint equation uses the measured
capacity summary without reconstructing a synthetic current trace.

### Full `.mat` time series mode

`matlab/run_project.m` also predicts held-out time-resolved terminal voltage.
It uses measured held-out current as a known external input, applies the
training-only ECM+capacity calibration and measures voltage error against
**held-out NASA measured terminal voltage**. This is a genuine external
voltage comparison, not model-to-model circular validation.

For SOC in this mode, the *reference proxy* is `1 - \int I dt/(3600 Q_cycle)`,
where `Q_cycle` is the held-out discharge's *measured* capacity, used for
scoring only. Scoring this derived SOC is useful for capacity mismatch/drift
but cannot be presented as independent SOC sensor ground truth.

## 4. Data leakage and caveats

- Source `Current_measured` may use signed convention; data loader uses `abs`
  **only for known discharge operations**.
- A full-charge `SOC(0)=1` assumption is made for each discharge cycle.
- The NASA discharge is predominantly constant-current: dynamic RC parameters
  are weakly identifiable; no claims for arbitrary EV drive cycles.
- Training curves are permitted to use measured training discharge capacities
  to create calibration coordinates; test discharge capacities are **never**
  inputs to predictions.
- No thermal, hysteresis, reversible aging or charge-efficiency dynamics.
- Only B0005 at approximately room temperature; no cross-cell generalization.
- MATLAB raw-data pipeline has not been executed here because a MATLAB
  runtime and the official raw MAT bytes were not available in the build
  environment. Therefore **no measured voltage RMSE is claimed here**.
- The checked-in capacity metrics come from an actually executed Python
  benchmark over the included capacity records.
