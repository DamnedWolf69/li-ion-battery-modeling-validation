function cycles = load_nasa_discharge(matPath)
% Parse original NASA B0005.mat. Do not fit/test on the same cycles.
raw = load(matPath);
[~, batteryId, ~] = fileparts(matPath);
if ~isfield(raw, batteryId)
    error('MAT file does not contain the expected field %s', batteryId);
end
ops = raw.(batteryId).cycle;
cycles = struct('index',{},'t',{},'i',{},'v',{},'capacity_ah',{});
for j = 1:numel(ops)
    if ~strcmpi(char(ops(j).type), 'discharge')
        continue;
    end
    d = ops(j).data;
    if ~isfield(d,'Capacity') || isempty(d.Capacity)
        continue;
    end
    t = double(d.Time(:));
    i = abs(double(d.Current_measured(:))); % discharge-positive convention
    v = double(d.Voltage_measured(:));
    cap = double(d.Capacity(1));
    keep = isfinite(t) & isfinite(i) & isfinite(v);
    t=t(keep); i=i(keep); v=v(keep);
    [t, order] = sort(t);
    i=i(order); v=v(order);
    [t, uniqueIdx] = unique(t,'stable');
    i=i(uniqueIdx); v=v(uniqueIdx);
    if numel(t) < 20 || ~(isfinite(cap) && cap > 0)
        continue;
    end
    t=t-t(1);
    c.index = numel(cycles)+1;
    c.t=t; c.i=i; c.v=v; c.capacity_ah=cap;
    cycles(end+1) = c; %#ok<AGROW>
end
if numel(cycles) < 10
    error('Only %d valid discharge cycles found in %s.', numel(cycles), matPath);
end
end
