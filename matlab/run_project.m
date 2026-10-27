function run_project()
% Main REAL NASA voltage validation (requires downloaded B0005.mat).
% From MATLAB: >> cd matlab; run_project
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab'));
source=fullfile(root,'data','raw','B0005.mat');
if ~isfile(source)
    error(['Raw B0005.mat not found. First run: ' newline ...
           'python scripts/download_nasa.py' newline ...
           'See README.md; no voltage-validation figures are fabricated.']);
end
cyc=load_nasa_discharge(source);
n=numel(cyc);
nTrain=floor(0.8*n);
nTest=n-nTrain;
if n<100; error('Unexpected number of discharge cycles: %d',n); end
assert(nTrain>40 && nTest>0);
train=cyc(1:nTrain); test=cyc(nTrain+1:end);
trainingCapacity=[train.capacity_ah]';
freshQ=median(trainingCapacity(1:10));
[futureQ,slope] = forecast_capacity(trainingCapacity,(nTrain+1:n)');
fprintf('Loaded %d genuine NASA discharge cycles: %d train, %d test.\n', n,nTrain,nTest);
model=fit_randles(train);

vErr=[]; socErr=[]; socFixedErr=[];
rows=zeros(nTest,9);
for j=1:nTest
    b=test(j);
    inputOnly=struct('t',b.t,'i',b.i); % no target voltage/capacity passed
    y=simulate_randles(inputOnly,futureQ(j),model);
    yFixed=simulate_randles(inputOnly,freshQ,model);
    % Held-out SOC *reference proxy* from measured NASA current + that
    % held-out discharge cycle's measured capacity. Not a SOC sensor.
    socRef = max(0,min(1,1-cumtrapz(b.t,b.i)/(3600*b.capacity_ah)));
    eV=y.voltage_v-b.v;
    eSOC=100*(y.soc-socRef); eSOCfixed=100*(yFixed.soc-socRef);
    vErr=[vErr;eV]; socErr=[socErr;eSOC]; %#ok<AGROW>
    socFixedErr=[socFixedErr;eSOCfixed]; %#ok<AGROW>
    rows(j,:)=[b.index,b.capacity_ah,futureQ(j),...
        sqrt(mean(eV.^2)),mean(abs(eV)),...
        mean(abs(eSOC)),mean(abs(eSOCfixed)),...
        eSOC(end),eSOCfixed(end)];
    if j==1 || j==round(nTest/2) || j==nTest
        fig=figure('Visible','off','Color','w','Position',[0 0 980 680]);
        subplot(2,1,1);
        plot(b.t,b.v,'k-',b.t,y.voltage_v,'b--','LineWidth',1.2);
        legend('NASA measured V','Predicted V','Location','best');
        ylabel('Terminal voltage (V)'); grid on;
        title(sprintf('NASA B0005: held-out discharge cycle %d',b.index));
        subplot(2,1,2);
        plot(b.t,100*socRef,'k-',b.t,100*y.soc,'b--','LineWidth',1.2);
        legend('Measured-capacity SOC reference (not sensed)','Estimated SOC','Location','best');
        xlabel('Elapsed time (s)'); ylabel('SOC (%)'); grid on;
        outFig=fullfile(root,'results','figures',sprintf('holdout_%03d.png',b.index));
        exportgraphics(fig,outFig,'Resolution',160); close(fig);
    end
end
T=array2table(rows,'VariableNames',{'discharge_index','capacity_measured_ah',...
    'capacity_predicted_ah','voltage_rmse_v','voltage_mae_v',...
    'soc_mae_pp','soc_fixed_mae_pp','soc_eod_error_pp','soc_fixed_eod_error_pp'});
writetable(T,fullfile(root,'results','voltage_soc_holdout.csv'));

summary=struct();
summary.dataset='NASA PCoE B0005';
summary.train_discharge_cycles=nTrain;
summary.test_discharge_cycles=nTest;
summary.capacity_forecast_slope_ah_per_cycle=slope;
summary.heldout_voltage_rmse_mv=1000*sqrt(mean(vErr.^2));
summary.heldout_voltage_mae_mv=1000*mean(abs(vErr));
summary.heldout_soc_proxy_mae_pp=mean(abs(socErr));
summary.heldout_soc_proxy_rmse_pp=sqrt(mean(socErr.^2));
summary.heldout_fixed_capacity_soc_proxy_mae_pp=mean(abs(socFixedErr));
summary.heldout_capacity_mae_mah=1000*mean(abs([test.capacity_ah]'-futureQ));
summary.reference_caveat=['SOC uses capacity-normalized integration of measured current; ' ...
  'NASA has no independent directly sensed SOC. Test-cycle capacities are labels only.'];
summary.identifiability_caveat=model.fit_note;
write_json(fullfile(root,'results','nasa_voltage_soc_metrics.json'),summary);
write_json(fullfile(root,'results','regularized_ecm_params.json'),model);
writematrix([model.soc_knots(:),model.ocv_v(:)],fullfile(root,'results','fitted_ocv_curve.csv'));
disp(summary);
fprintf('Saved independent holdout measurements to results/\n');
end
function write_json(path,s)
fid=fopen(path,'w');
if fid<0; error('Cannot write %s',path); end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(s,'PrettyPrint',true));
end
