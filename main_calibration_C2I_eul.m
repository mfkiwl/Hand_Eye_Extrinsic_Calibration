close all
clear
clc
format long
%% Abstract
% LiDAR Coordinate in A-LOAM:
% x (back)
% y (right)
% z (up)
% Camera Coordinate
% x (right)
% y (down)
% z (front)
% INS Coordinate
% x (right)
% y (front)
% z (up)
%% Pose Filename Setup
filename_1 = "./data/VO.mat"; % Visual Odometry
filename_2 = "./data/INS.mat"; % INS
filename_3 = "./data/IMU.mat"; % IMU Time
%% Read LiDAR Odometry and INS Data
data_1 = load(filename_1, '-ascii');
data_2 = load(filename_2, '-ascii');
data_3 = load(filename_3, '-ascii');
timestamp_1 = data_1(:, 1);
timestamp_2 = data_3(:, 1);
pose_1 = data_1(:, 2 : 8);
pose_2 = data_2(:, 2 : 8);
%% Data Synchronization
threshold = 0.005;
flag = false; % Print Synchronized Timestamp
[pose_1_sync, timestamp_1_sync, pose_2_sync, timestamp_2_sync] = sync(pose_1, timestamp_1, pose_2, timestamp_2, threshold, flag);
%% Coordinate Transformation
R0_1 = quat2rotm(pose_1_sync(1, 4 : 7)); % qw qx qy qz
t0_1 = pose_1_sync(1, 1 : 3);
[m, ~] = size(pose_1_sync);
for i = 1 : m
    pose_1_sync(i, 1 : 3) = R0_1 \ (pose_1_sync(i, 1 : 3)' - t0_1');
    R = R0_1 \ quat2rotm(pose_1_sync(i, 4 : 7)); % qw qx qy qz
    eul = rotm2eul(R, 'ZYX'); % rad
    pose_1_sync(i, 4 : 6) = eul; % ZYX
end
pose_1_sync(:, 7) = [];
R0_2 = quat2rotm(pose_2_sync(1, 4 : 7)); % qw qx qy qz
t0_2 = pose_2_sync(1, 1 : 3);
[n, ~] = size(pose_2_sync);
for i = 1 : n
    pose_2_sync(i, 1 : 3) = R0_2 \ (pose_2_sync(i, 1 : 3)' - t0_2');
    R = R0_2 \ quat2rotm(pose_2_sync(i, 4 : 7)); % qw qx qy qz
    eul = rotm2eul(R, 'ZYX'); % rad
    pose_2_sync(i, 4 : 6) = eul; % ZYX
end
pose_2_sync(:, 7) = [];
%% Plot to Check Data
figure
hold on
grid on
axis equal
plot3(pose_1_sync(:, 1), pose_1_sync(:, 2), pose_1_sync(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_2_sync(:, 1), pose_2_sync(:, 2), pose_2_sync(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('Before Calibration')
legend('Visual Odometry', 'INS')
figure
hold on
grid on
colororder({'b','r'})
yyaxis left
plot(pose_1_sync(:, 4), '-s', 'LineWidth', 2)
plot(pose_1_sync(:, 5), '-o', 'LineWidth', 2)
yyaxis right
plot(pose_1_sync(:, 6), '-^', 'LineWidth', 2)
yyaxis left
plot(pose_2_sync(:, 4), '--s', 'LineWidth', 2)
plot(pose_2_sync(:, 5), '--o', 'LineWidth', 2)
ylabel('Euler Angle / rad')
yyaxis right
plot(pose_2_sync(:, 6), '--^', 'LineWidth', 2)
xlabel('Index')
ylabel('Euler Angle / rad')
title('Before Calibration')
legend('Camera     Roll', 'Camera     Pitch', 'INS Roll', 'INS Pitch', 'Camera     Yaw', 'INS Yaw', 'Location', 'SouthWest')
%% Optimization
fun = @(x)costFunction_C2I_eul(pose_1_sync, pose_2_sync, x);
% options = optimset( 'Display', 'iter', 'MaxFunEvals', 1e6, 'MaxIter', 1e6);
options = optimset('PlotFcns', 'optimplotfval', 'MaxFunEvals', 1e6, 'MaxIter', 1e6); % OK
% options = optimset('PlotFcns', 'optimplotfval'); % OK
% Constrained
A = [];
b = [];
Aeq = [];
beq = [];
lb = [-1, -1, -1, -pi, -pi, -pi, 0];
ub = [1, 1, 1, pi, pi, pi, 10];
x0 = (lb + ub) / 2;  % x y z (m) yaw pitch roll (rad) scale
% x0 = [0.3, 0.11, -0.85, 0, 0, pi / 2, 3.11]; % Measurement: x y z (m) yaw pitch roll (rad) scale
[x,fval,exitflag,output] = fmincon(fun, x0, A, b, Aeq, beq, lb, ub, [], options); % Constrained
% [x,fval,exitflag,output] = fminsearch(fun, x0, options); % Search
% [x,fval,exitflag,output] = fminunc(fun, x0, options); % Unconstrained
%% Transform
% R12 = eul2rotm(x(1, 4 : 6), 'ZYX');
% t12 = x(1, 1 : 3)';
fprintf("Camera -> INS Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tYaw\t\t|\tPitch\t|\tRoll\t|\tScale\t|\n")
fprintf("Camera -> INS Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x)
scale = x(1, 7);
T12 = eul2tform(x(1, 4 : 6), 'ZYX');
T12(1 : 3, 4) = x(1, 1 : 3)';
fprintf("T12 = \n")
disp(T12)
fprintf("T12^-1 = \n")
disp(inv(T12))
[m, ~] = size(pose_1_sync);
pose_C2I = zeros(m, 6);
for i = 1 : m
    pose_1_temp = eul2tform(pose_1_sync(i, 4 : 6), 'ZYX');
    pose_1_temp(1 : 3, 4) = pose_1_sync(i, 1 : 3)' * scale;
    pose_C2I_temp = T12 \ pose_1_temp * T12; % Correct
%     pose_C2I_temp = pose_1_temp * T12; % Wrong !!!
    pose_C2I(i, :) = [pose_C2I_temp(1 : 3, 4)', tform2eul(pose_C2I_temp, 'ZYX')];
end
%% Plot to Check Data
figure
hold on
grid on
axis equal
plot3(pose_1_sync(:, 1), pose_1_sync(:, 2), pose_1_sync(:, 3), 'k^-.', 'LineWidth', 1)
plot3(pose_C2I(:, 1), pose_C2I(:, 2), pose_C2I(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_2_sync(:, 1), pose_2_sync(:, 2), pose_2_sync(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('After Calibration')
legend('Camera Pose Original', 'Camera Pose Transformed', 'INS', 'Location', 'NorthEast')