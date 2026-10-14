%% C-scan 重读：只用文件里的 raw 重新算 MAP 和上升沿时间，再和运行时存的值逐点比较（docs/14 6.4）
%
%  不调用任何采集代码，不碰硬件，别的电脑上也能跑。
%  注意：cscan_data 不进 git（.gitignore），sync_pam 不会同步数据文件，要在别的电脑上看得自己拷过去。
%  用法：
%    1. 直接运行：读当前文件夹下 cscan_data 里最新的 cscan_*.mat（假数据文件叫 cscan_mock_*.mat，也会被找到）
%    2. 先在命令行设 REPLOT_FILE = '完整路径\cscan_xxx.mat'，再运行本脚本
%  通过：isequal(MAP)、isequal(nEdge)、isequaln(tEdge) 都是 1；MAP 图和运行时的一样。
%  computeMAP / quickCheckRow / toVolts 是从 cscan_test.m 原样抄过来的，改一边要同时改另一边。

%% 1. 选文件
if ~exist('REPLOT_FILE', 'var') || isempty(REPLOT_FILE)
    dataDir = fullfile(pwd, 'cscan_data');
    d = dir(fullfile(dataDir, 'cscan_*.mat'));
    assert(~isempty(d), '在 %s 里没找到 cscan_*.mat：先设 REPLOT_FILE，或者把当前文件夹换成 07_MATLAB。', dataDir);
    [~, i] = max([d.datenum]);                 % 最新的文件
    REPLOT_FILE = fullfile(d(i).folder, d(i).name);
end
f = REPLOT_FILE;
clear REPLOT_FILE                % 用完就清掉，下次运行不会误读这次的文件

%% 2. 读文件
S = load(f);                     % 文件里每个变量就是 cscan 的一个字段
n = S.rowsDone;
P = S.params;
ATS = P.ATS;
fprintf('文件：%s\n', f);
fprintf('%s；%s；%d x %d 像素，完成 %d/%d 行；DX %.2f um，DY %.2f um（Y 已标定：%d）；CH A %s，TRIG IN %s\n', ...
    S.note, char(S.time), P.NX, P.NY, n, P.NY, P.DX_UM, P.DY_UM, P.Y_CALIBRATED, ...
    ATS.inputImpedanceName, ATS.extTrigRangeName);
if strlength(S.errorMessage) > 0
    fprintf('这次运行出过错：第 %d 行（%s）：%s\n', S.failedRow, S.failedPhase, S.errorMessage);
end
if n == 0
    fprintf('没有完成的行（rowsDone = 0），没有东西可以画。\n');
    return
end
if ~P.ATS_ENABLE && ~(isfield(S, 'mock') && S.mock)
    fprintf('ATS 关（只动电机），文件里没有采集数据。每行 ctr1：%s（应为 %d）\n', mat2str(S.trigCount(1:n)), P.NX);
    return
end
raw = S.raw_u16(:, :, 1:n);      % 只用做完的行

%% 3. 只用 raw 重新算，和文件里存的比较
MAP = computeMAP(raw, ATS.inputRange_V);
nEdge = zeros(n, P.NX);
tEdge = nan(n, P.NX);
for iy = 1:n
    qc = quickCheckRow(raw(:, :, iy), ATS, S.edgeTh_V);    % 用运行时同一个阈值
    nEdge(iy, :) = qc.nEdge;
    tEdge(iy, :) = qc.tEdge;
end
if isfield(S, 'MAP')
    fprintf('isequal(MAP) = %d（重算 vs 文件里存的）\n', isequal(MAP, S.MAP));
else
    fprintf('文件里没有存 MAP（运行没有走到最后），只显示重算的结果。\n');
end
fprintf('isequal(nEdge) = %d，isequaln(tEdge) = %d\n', isequal(nEdge, S.nEdge(1:n, :)), isequaln(tEdge, S.tEdge(1:n, :)));
fprintf('每条正好 1 个沿：%d/%d；上升沿 %.4f ~ %.4f us，标准差 %.2f ns；MAP %.4f ~ %.4f V\n', ...
    nnz(nEdge == 1), numel(nEdge), min(tEdge(:)) * 1e6, max(tEdge(:)) * 1e6, std(tEdge(:), 'omitnan') * 1e9, ...
    min(MAP(:)), max(MAP(:)));
fprintf('每行 ctr1：%s（应为 %d）\n', mat2str(S.trigCount(1:n)), P.NX);
tm = S.timing;
if any(~isnan(tm.row))                                    % 每段的平均用时（docs/14 6.10）；假数据没有计时
    fprintf('每行平均：arm %.3f / 扫描 %.3f / 取数 %.3f / 存 %.3f / 回程+Y %.3f / 整行 %.3f s\n', ...
        mean(tm.arm, 'omitnan'), mean(tm.scan, 'omitnan'), mean(tm.collect, 'omitnan'), ...
        mean(tm.save, 'omitnan'), mean(tm.move, 'omitnan'), mean(tm.row, 'omitnan'));
end
if isfield(S, 'mock') && S.mock
    decoded  = MAP / S.mockVPerUnit;                      % 假数据：第 iy 行第 ix 列应为 iy + ix/100
    expected = (1:n)' + (1:P.NX) / 100;
    iyS = min(3, n);  ixS = min(7, P.NX);
    fprintf('假数据：%d/%d 个像素对得上；MAP(%d,%d) = %.2f（应为 %.2f）\n', ...
        nnz(abs(decoded - expected) < 0.005), numel(expected), iyS, ixS, decoded(iyS, ixS), expected(iyS, ixS));
end

%% 4. 画图：行 = Y，列 = X；axis xy 让 Y 朝上增加。只有一行时画曲线
x = S.x_um;
y = S.y_um(1:n);
figure('Name', 'C-scan replot', 'Color', 'w');
subplot(1, 2, 1);
if n == 1
    plot(x, MAP, '.-'); grid on; ylabel('MAP (V)');
else
    imagesc(x, y, MAP); axis image; axis xy; colorbar; ylabel('Y (um)');
end
xlabel('X (um)');
title({'MAP（V，由 raw 重算）', sprintf('%d x %d', P.NX, n)});
subplot(1, 2, 2);
if n == 1
    plot(x, tEdge * 1e6, '.-'); grid on; ylabel('上升沿 (us)');
else
    imagesc(x, y, tEdge * 1e6); axis image; axis xy; colorbar; ylabel('Y (um)');
end
xlabel('X (um)'); title('上升沿时间（us）');

%% ===== 本地函数（和 cscan_test.m 里的相同）=====
function v = toVolts(raw, inputRange_V)
% uint16 编码 → 电压（同 bscan_test 第 176 行）
    v = (double(raw) / 65535 * 2 - 1) * inputRange_V;
end

function qc = quickCheckRow(rawRow, ATS, th)
% 一行的快速检查：每条越过阈值的上升沿个数、第一个上升沿的时刻（线性插值）
    v  = toVolts(rawRow, ATS.inputRange_V);
    dt = 1 / ATS.sampleRate_Hz;
    nx = size(v, 2);
    qc.nEdge = zeros(1, nx);
    qc.tEdge = nan(1, nx);
    for k = 1:nx
        above = v(:, k) > th;
        up = find(diff(above) == 1);
        qc.nEdge(k) = numel(up);
        if ~isempty(up)
            i = up(1);                                           % v(i) <= th < v(i+1)
            frac = (th - v(i, k)) / (v(i+1, k) - v(i, k));
            qc.tEdge(k) = (ATS.triggerDelay + i - 1 + frac) * dt;
        end
    end
    qc.vMax = max(v, [], 1);
    qc.rail = nnz(rawRow == 0 | rawRow == 65535);
end

function MAP = computeMAP(raw, inputRange_V)
% MAP(iy, ix) = 第 iy 行第 ix 条 A-line 的 max(v − median(v))，一行一行算
    [~, nx, ny] = size(raw);
    MAP = zeros(ny, nx);
    for iy = 1:ny
        v = toVolts(raw(:, :, iy), inputRange_V);
        MAP(iy, :) = max(v - median(v, 1), [], 1);
    end
end
