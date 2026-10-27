function demo_synthetic()
% Standalone illustration of original 2.5 Ah circuit. NEVER used as validation.
t=(0:600)'; i=ones(size(t));
model.R0=0.05; model.R1=0.02; model.tau_s=20;
model.soc_knots=(0:0.1:1)';
model.ocv_v=(3.0:0.12:4.2)';
c=struct('t',t,'i',i);
p=simulate_randles(c,2.5,model);
figure('Color','w');
plot(t,p.voltage_v,'LineWidth',1.6); grid on;
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Synthetic 2.5 Ah one-RC discharge demonstration (NOT validation)');
end
