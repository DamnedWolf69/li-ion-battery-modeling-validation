MATLAB functions (base MATLAB, no Simulink or Optimization Toolbox required):

```matlab
cd matlab
capacity_benchmark   % works offline using included NASA capacity observations
run_project          % download raw B0005.mat first; produces voltage/SOC holdout RMSE

demo_synthetic       % synthetic illustration only, NEVER included in reported scores
```

The original `init.m` is superseded: NASA B0005 is rated around 2 Ah, not
2.5 Ah, and the illustrative linear OCV table and resistance values are **not**
empirical measurements. A physically unique parameter decomposition is NOT
claimed from near-constant-current discharge profiles.
