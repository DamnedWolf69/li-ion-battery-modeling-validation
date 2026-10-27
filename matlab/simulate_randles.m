function pred = simulate_randles(cycle, Qhat_Ah, model)
% One-RC Thevenin/Randles-style discharge ECM:
% SOC=1-int(I dt)/(3600*Q), Vt=OCV(SOC)-I*R0-vrc.
% INITIAL SOC=1 is a controlled full-charge assumption, not inferred online.
if ~(isscalar(Qhat_Ah) && Qhat_Ah > 0)
    error('Capacity estimate must be positive');
end
t=cycle.t; i=cycle.i;
q_used_ah = cumtrapz(t,i) / 3600;
pred.soc = max(0,min(1,1-q_used_ah/Qhat_Ah));
vrc = rc_voltage(t,i,model.R1,model.tau_s);
ocv = interp1(model.soc_knots,model.ocv_v,pred.soc,'linear','extrap');
pred.voltage_v = ocv - i*model.R0 - vrc;
pred.vrc_v = vrc;
end
