%% analyze_delay_1003.m —— 10/3 延时测试（07 第 1 周 1.2）的分析
% 做三件事：
%   1. 自检 aline_edge_time：人造脉冲 + 10/1 的旧数据（参考答案在 docs/09 的 C 段）
%   2. 读 aline_data 里 10/3 的文件，按 config.note 分成 1 µs 组和 3 µs 组，
%      找每条 A-line 里 CH2 脉冲的上升沿（50% 处，线性插值），算平均值、标准差，
%      再和示波器自动测量（Dly1→2，同样是 50% 处）的结果比较
%   3. 画图，存到 PAM_controlProgram\docs\figures\delay_test_1003.png（给导师看）
% 只读数据，不碰硬件，在家也能跑。需要 MATLAB R2020a 或更新的版本（用到 tiledlayout、exportgraphics）。

clear; close all;

%% [0] 路径：脚本、aline_data 都在 Matlab 文件夹里；图存到 PAM_controlProgram\docs\figures
% Matlab 文件夹真正在 PAM_controlProgram\Matlab，桌面上的 Desktop\Matlab 是指向它的 junction。
% 同一个文件有两个地址，'..'（上一层）按打开时用的地址算，所以两种都试：
%   从 PAM_controlProgram\Matlab 打开：上一层就是项目文件夹       -> cand1
%   从 Desktop\Matlab 打开：上一层是 Desktop，还要进 PAM_controlProgram -> cand2
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end             % 把代码粘到命令行里运行时，mfilename 是空的
dataDir = fullfile(here, 'aline_data');
cand1 = fullfile(here, '..', 'docs', 'figures');
cand2 = fullfile(here, '..', 'PAM_controlProgram', 'docs', 'figures');
if isfolder(cand1)
    figDir = cand1;
elseif isfolder(cand2)
    figDir = cand2;
else
    error('找不到 docs\\figures，试过：\n  %s\n  %s', cand1, cand2);
end
assert(isfolder(dataDir), '找不到 %s', dataDir);

%% [1] 自检 1：人造脉冲，答案是精确已知的
fs = 180e6;                                   % 180 MS/s，每个点 5.556 ns
t  = (0:1023)' / fs;                          % 第 n 个点的时刻是 (n-1)/fs
v1 = zeros(1024, 1);  v1(200:235) = 1;        % 第 200～235 个点是 1 V 的脉冲
v2 = circshift(v1, 180);                      % 整体往后挪 180 个点 = 180/fs = 1.000 µs
e1 = aline_edge_time(v1, t);
e2 = aline_edge_time(v2, t);
% 第 199 点（0 V，时刻 198/fs）和第 200 点（1 V，时刻 199/fs）的正中间穿过 0.5 V，所以应得 198.5/fs
fprintf('Self-test (synthetic): edge %.5f us (expect %.5f), shifted %.5f us, difference %.6f us (expect 1.000000)\n', ...
    e1*1e6, 198.5/fs*1e6, e2*1e6, (e2-e1)*1e6);
assert(abs(e1 - 198.5/fs) < 1e-15 && abs((e2 - e1) - 180/fs) < 1e-15, '人造脉冲自检没通过');

%% [2] 自检 2：10/1 的旧数据（1 MHz 连续方波），和 docs/09 里的参考答案比
ref = {'aline_20261001_191418_617.mat', 0.977;
       'aline_20261001_191508_775.mat', 0.976;
       'aline_20261001_191534_374.mat', 0.137;
       'aline_20261001_191706_901.mat', 0.136;
       'aline_20261001_191827_663.mat', 0.127};
% （10/1 的第一个文件 185441_561 没放进来：它的采集窗口一开始就落在边沿上，结果不可信）
for k = 1:size(ref, 1)
    f = fullfile(dataDir, ref{k, 1});
    if ~isfile(f), fprintf('  (missing %s, skipped)\n', ref{k, 1}); continue; end
    s = load(f, 'aline');
    e = aline_edge_time(s.aline.volts, s.aline.time_trigger_s) * 1e6;
    fprintf('Self-test (10/1): %s  edge %.3f us  (reference %.3f)\n', ref{k, 1}, e, ref{k, 2});
    assert(abs(e - ref{k, 2}) < 0.0015, '和 10/1 的参考答案对不上：%s', ref{k, 1});
end

%% [3] 10/3 的延时测试：按 note 分组
G(1) = struct('label', 'dt = 1 us', 'prefix', '1.2 dt=1us', 'scope_us', 0.9969, 'files', {{}}, 'edge_us', [], 'v', {{}}, 't', {{}});
G(2) = struct('label', 'dt = 3 us', 'prefix', '1.2 dt=3us', 'scope_us', 2.987,  'files', {{}}, 'edge_us', [], 'v', {{}}, 't', {{}});
% scope_us：示波器自动测量 Dly1→2 的平均值（统计清零后），见 docs/09 表 1

d = dir(fullfile(dataDir, 'aline_20261003_*.mat'));
for k = 1:numel(d)
    s = load(fullfile(d(k).folder, d(k).name), 'aline');
    a = s.aline;
    if ~isfield(a.config, 'note'), continue; end          % 没有 note 的文件不知道是什么设定，不用
    for g = 1:numel(G)
        if startsWith(a.config.note, G(g).prefix)          % 按 note 分组，不按文件名猜
            G(g).files{end+1}   = d(k).name;
            G(g).edge_us(end+1) = aline_edge_time(a.volts, a.time_trigger_s) * 1e6;
            G(g).v{end+1}       = a.volts * 1e3;           % mV
            G(g).t{end+1}       = a.time_trigger_s * 1e6;  % µs
        end
    end
end

fprintf('\n10/3 delay test (rising edge at 50%%, linear interpolation)\n');
for g = 1:numel(G)
    assert(~isempty(G(g).edge_us), '没有找到 note 以 "%s" 开头的文件', G(g).prefix);
    assert(~any(isnan(G(g).edge_us)), '%s 组里有文件找不到上升沿', G(g).label);
    fprintf('\n%s  (%d files)\n', G(g).label, numel(G(g).edge_us));
    for k = 1:numel(G(g).files)
        fprintf('  %s   %.4f us\n', G(g).files{k}, G(g).edge_us(k));
    end
end

m  = arrayfun(@(x) mean(x.edge_us), G);
sd = arrayfun(@(x) std(x.edge_us), G) * 1e3;              % ns
sc = [G.scope_us];
fprintf('\n%-10s %4s %14s %12s %14s %18s\n', 'group', 'N', 'ATS mean (us)', 'std (ns)', 'scope (us)', 'ATS - scope (us)');
for g = 1:numel(G)
    fprintf('%-10s %4d %14.4f %12.2f %14.4f %18.4f\n', G(g).label, numel(G(g).edge_us), m(g), sd(g), sc(g), m(g) - sc(g));
end
fprintf('%-10s %4s %14.4f %12s %14.4f %18.4f\n', '3us - 1us', '', m(2) - m(1), '', sc(2) - sc(1), (m(2) - m(1)) - (sc(2) - sc(1)));
fprintf('Difference in samples: %.2f (2 us x 180 MS/s = 360)\n', (m(2) - m(1)) * 1e-6 * fs);

%% [4] 图：上面是两组各一条完整的 A-line；下面放大两个上升沿，同组所有记录叠在一起看重复性
fig = figure('Name', 'Delay test 10/3', 'Color', 'w', 'Position', [100 100 1000 700]);
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'A-line delay test 10/3: function generator CH2 delayed vs CH1 (trigger), ATS9462 CH A, 180 MS/s');

ax = nexttile(tl, [1 2]); hold(ax, 'on'); grid(ax, 'on');
cols = lines(numel(G));
for g = 1:numel(G)
    plot(ax, G(g).t{1}, G(g).v{1}, 'Color', cols(g, :), 'LineWidth', 1.2, ...
        'DisplayName', sprintf('%s: one record', G(g).label));
end
for g = 1:numel(G)
    xline(ax, m(g), '--', sprintf('%.4f us', m(g)), 'Color', cols(g, :), 'HandleVisibility', 'off', ...
        'LabelVerticalAlignment', 'middle');
end
xlabel(ax, 'Time relative to ATS trigger (us)'); ylabel(ax, 'CH A (mV)');
legend(ax, 'Location', 'northeast');
xlim(ax, [0, G(1).t{1}(end)]);

for g = 1:numel(G)
    ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
    for k = 1:numel(G(g).v)
        plot(ax, G(g).t{k}, G(g).v{k}, '.-', 'Color', [cols(g, :) 0.5], 'MarkerSize', 8);
    end
    xline(ax, m(g), 'k--');
    xlim(ax, m(g) + [-0.03 0.03]);                       % 边沿前后各 30 ns
    xlabel(ax, 'Time (us)'); ylabel(ax, 'CH A (mV)');
    title(ax, {sprintf('%s: all %d records overlaid', G(g).label, numel(G(g).v)), ...
               sprintf('edge %.4f us, std %.1f ns (scope %.4f us)', m(g), sd(g), sc(g))}, 'FontWeight', 'normal');
end

set(findall(fig, 'Type', 'axes'), 'Toolbar', []);   % 不把坐标轴右上角的工具栏图标导出到图片里
outPng = fullfile(figDir, 'delay_test_1003.png');
exportgraphics(fig, outPng, 'Resolution', 150);
fprintf('\nFigure saved: %s\n', outPng);
