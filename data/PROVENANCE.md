# Dataset provenance and use

## Primary source

B. Saha and K. Goebel (2007), **Battery Data Set**, NASA Prognostics
Data Repository, NASA Ames Research Center, Moffett Field, California.

- Official source and data citation: https://www.nasa.gov/intelligent-systems-division/discovery-and-systems-health/pcoe/pcoe-data-set-repository/
- NASA Open Data description: https://data.nasa.gov/dataset/li-ion-battery-aging-datasets
- Download URL: https://phm-datasets.s3.amazonaws.com/NASA/5.+Battery+Data+Set.zip
- Primary cell: **B0005**, nominal **2 Ah**, nominal room temperature, about **2 A** discharge, with a **2.7 V** specified discharge threshold.
- Raw file required for full voltage experiments: `data/raw/B0005.mat` (not redistributed).

## Included small derived capacity table

`data/processed/B0005_discharge_capacity.csv` contains **168 recorded discharge
capacities (Ah)** for B0005, indexed in original discharge order. Values are
transcribed from the publicly posted NASA-derived capacity table:

https://github.com/amirhossein-sadeghi2003/battery-health-forecasting-baselines/blob/main/data/processed/discharge_capacity.csv

Specifically, the records with `battery_id == B0005` and the columns
`discharge_index`, `capacity_ah`. The original project credits the NASA PCoE
dataset. This small numerical extract is provided to allow the real-data
capacity benchmark to run offline; it contains **no time-resolved measured
voltage/current** and **no directly sensed SOC**. The user should independently
compare or regenerate from the official original MAT file when possible.

Original NASA metadata does not provide a clear data license in its portal.
The repository's MIT code license **does not purport to license NASA data or
third-party derived data**; source notices must be respected.

## Data separation

Chronological split (discharge counts): cycles **1–134** are training;
**135–168** are held out. Training capacity is used to fit the aging trend.
Held-out measured capacities are used **only for scoring** and for constructing
capacity-normalized diagnostic SOC proxies, never to choose model parameters.

## Limitation

Capacity measured at an end-of-discharge cutoff can anchor a 0%-SOC *proxy*
for the usable discharge window; it is not a laboratory reference electrode,
independent SOC sensor, or proof of true cell SOC accuracy. Full time-resolved
SOC reference is derived from recorded current and observed per-cycle capacity.
Treat reported endpoint errors as **capacity-calibration/SOC-drift diagnostics**.
