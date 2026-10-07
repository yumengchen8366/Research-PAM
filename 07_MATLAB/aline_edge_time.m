function t_edge = aline_edge_time(v, t_axis, level)
%ALINE_EDGE_TIME  一条 A-line 里第一个上升沿穿过 level 的时刻（秒），在前后两个采样点之间线性插值。
%
%   t_edge = aline_edge_time(v, t_axis)          level 默认取 (max(v)+min(v))/2，也就是脉冲的 50% 处
%   t_edge = aline_edge_time(v, t_axis, level)   自己指定判断用的电压（V）
%
%   v      : 一条 A-line 的电压（V），一般用 aline.volts
%   t_axis : 和 v 一一对应的时间（s），一般用 aline.time_trigger_s
%            （它已经包含了 ATS 的 triggerDelay，所以这里不用再自己算 (n-1)/fs）
%   t_edge : 第一个"上升穿过 level"的时刻（s）。整条记录里找不到就返回 NaN。
%
%   "上升穿过"的定义：第 i 点 < level，并且第 i+1 点 >= level。
%   所以如果记录一开始就已经在高电平上（采集窗口的起点落在脉冲中间），
%   开头那一段不算，会继续往后找下一个真正从下往上穿过的地方。

    v      = double(v(:));        % 统一成列向量；double 避免整数运算出错
    t_axis = double(t_axis(:));
    assert(numel(v) == numel(t_axis), 'v 和 t_axis 的点数不一样。');

    if nargin < 3 || isempty(level)
        level = (max(v) + min(v)) / 2;   % 50% 处：最高点和最低点的正中间
    end

    % 第一个满足"这一点在 level 下面、下一点在 level 上面"的位置 i
    i = find(v(1:end-1) < level & v(2:end) >= level, 1);
    if isempty(i)
        t_edge = NaN;
        return
    end

    % 线性插值：真正穿过 level 的时刻在 t(i) 和 t(i+1) 之间，
    % 按电压从 v(i) 走到 level 占整段 v(i)→v(i+1) 的比例来定位。
    frac   = (level - v(i)) / (v(i+1) - v(i));     % 0 < frac <= 1
    t_edge = t_axis(i) + frac * (t_axis(i+1) - t_axis(i));
end
