function model = fit_randles(train)
% Fit effective ECM parameters from TRAINING current/voltage/capacity.
% Crucial: NASA constant-current curves alone cannot uniquely identify
% the physical OCV-R0-R1-C1 decomposition. A regularizing prior is used.
% NEVER claim uniquely measured resistances or a resting OCV curve.
knots = (0:0.1:1)';
priorOCV = [3.00;3.28;3.41;3.51;3.61;3.68;3.75;3.82;3.91;4.01;4.18];
A=[]; I=[]; V=[]; tBlocks={}; iBlocks={}; lengths=[];
for c = 1:numel(train)
    b=train(c);
    take=unique(round(linspace(1,numel(b.t),min(90,numel(b.t)))))';
    t=b.t(take); i=b.i(take); v=b.v(take);
    soc=max(0,min(1,1-cumtrapz(t,i)/(3600*b.capacity_ah)));
    % Linear interpolation of OCV knots is affine in their values.
    Ac=interp1(knots,eye(numel(knots)),soc,'linear','extrap');
    A=[A;Ac]; %#ok<AGROW>
    I=[I;i]; V=[V;v]; %#ok<AGROW>
    tBlocks{end+1}=t; iBlocks{end+1}=i; %#ok<AGROW>
    lengths(end+1)=numel(t); %#ok<AGROW>
end
D=diff(eye(numel(knots)),2);
H=A'*A + 30*(D'*D) + 1.5*eye(numel(knots));
prior=[0.05;0.02;20]; % user demo seeds; NOT claimed as fitted datasheet values
opts=optimset('Display','off','MaxFunEvals',400,'MaxIter',160,...
              'TolX',1e-4,'TolFun',1e-7);
pbest=fminsearch(@loss,log(prior),opts);
[~,ocv] = loss(pbest);
p=exp(pbest);
model.R0=p(1); model.R1=p(2); model.tau_s=p(3);
model.C1=model.tau_s/model.R1;
model.soc_knots=knots; model.ocv_v=ocv;
model.fit_note=['Regularized effective parameters under quasi-constant-current ' ...
    'discharge; NOT uniquely identifiable physical OCV or impedances.'];

    function [cost, ocvOut] = loss(z)
        pp=exp(z(:));
        if any(~isfinite(pp)) || pp(1)<0.002 || pp(1)>0.25 || ...
           pp(2)<0.002 || pp(2)>0.2 || pp(3)<1 || pp(3)>500
            cost=1e3; ocvOut=priorOCV; return
        end
        vrc=zeros(size(I)); startIndex=1;
        for m=1:numel(lengths)
            idx=startIndex:startIndex+lengths(m)-1;
            vrc(idx)=rc_voltage(tBlocks{m},iBlocks{m},pp(2),pp(3));
            startIndex=startIndex+lengths(m);
        end
        target=V + I*pp(1) + vrc;
        ocvOut=H\(A'*target + 1.5*priorOCV);
        % Encourage physical monotonic OCV without hidden holdout labels.
        ocvOut=cummax(ocvOut);
        predicted=A*ocvOut - I*pp(1) - vrc;
        residual=V-predicted;
        cost=mean(residual.^2) + 0.001*sum((z(:)-log(prior)).^2);
    end
end
