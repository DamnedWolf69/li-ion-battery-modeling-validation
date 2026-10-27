function vrc = rc_voltage(t, I, R1, tau)
% Exact 1-RC zero-order hold update for irregular time steps.
% dvrc/dt = -(1/tau)*vrc + (R1/tau)*I; tau=R1*C1
n = numel(t);
vrc = zeros(n,1);
for k = 2:n
    a = exp(-(t(k)-t(k-1))/tau);
    vrc(k) = a*vrc(k-1) + R1*(1-a)*0.5*(I(k-1)+I(k));
end
end
