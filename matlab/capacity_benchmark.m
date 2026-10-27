function capacity_benchmark()
% MATLAB reproduction of the included empirical capacity benchmark.
root=fileparts(fileparts(mfilename('fullpath')));
x=readmatrix(fullfile(root,'data','processed','B0005_discharge_capacity.csv'));
assert(size(x,1)==168);
cap=x(:,2); nTrain=134;
Qfresh=median(cap(1:10));
[Qpredict,slope]=forecast_capacity(cap(1:nTrain),(nTrain+1:168)');
heldout=cap(nTrain+1:end);
% EOD SOC proxy residual = 1 - measured capacity / estimated capacity.
maeCapacity=1000*mean(abs(Qpredict-heldout));
mapeCapacity=100*mean(abs(Qpredict-heldout)./heldout);
maeSoc=100*mean(abs(1-heldout./Qpredict));
maeFresh=100*mean(abs(1-heldout./Qfresh));
fprintf('NASA B0005 measured capacity: 134 train / 34 held out\n');
fprintf('Train-only trend slope: %.6f Ah/discharge cycle\n',slope);
fprintf('Holdout capacity MAE: %.3f mAh, MAPE: %.3f %%\n',maeCapacity,mapeCapacity);
fprintf('EOD SOC proxy MAE: %.3f pp (trend), %.3f pp (fixed fresh Q)\n',maeSoc,maeFresh);
end
