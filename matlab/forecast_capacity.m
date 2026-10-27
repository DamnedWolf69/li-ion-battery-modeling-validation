function [Qpred, slope] = forecast_capacity(trainingCapacity, futureCycleIndex)
% Chronological causal regression: last 40 TRAINING cycles only.
if isempty(trainingCapacity) || numel(trainingCapacity) < 40
    error('Need at least 40 training capacities');
end
n = numel(trainingCapacity);
x = (n-39:n)';
p = polyfit(x,trainingCapacity(end-39:end),1);
Qpred = max(0.3,polyval(p,futureCycleIndex));
slope = p(1);
end
