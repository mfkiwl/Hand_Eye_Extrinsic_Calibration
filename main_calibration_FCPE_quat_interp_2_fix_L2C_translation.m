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
% filename_1 = "./data/LO_FCPE.mat"; % LiDAR Odometry
% filename_2 = "./data/VO_FCPE.mat"; % Visual Odometry
% filename_3 = "./data/INS_FCPE.mat"; % INS
% filename_1_out_13 = "./results/LO2INS_FCPE.txt"; % LiDAR Odometry
% filename_3_out_13 = "./results/INS_LO_FCPE.txt"; % INS for LiDAR
% filename_2_out_23 = "./results/VO2INS_FCPE.txt"; % Visual Odometry
% filename_3_out_23 = "./results/INS_VO_FCPE.txt"; % INS for Camera
% filename_1_out_12 = "./results/LO2VO_FCPE.txt"; % LiDAR Odometry
% filename_2_out_12 = "./results/VO_LO_FCPE.txt"; % Visual Odometry for LiDAR
filename_1 = "./data/2021-11-10/bag1/LO_FCPE.mat"; % LiDAR Odometry
filename_2 = "./data/2021-11-10/bag1/VO_FCPE.mat"; % Visual Odometry
filename_3 = "./data/2021-11-10/bag1/INS_FCPE.mat"; % INS
filename_1_out_13 = "./results/2021-11-10/bag1/LO2INS_FCPE_update.txt"; % Updated LiDAR Odometry
filename_3_out_13 = "./results/2021-11-10/bag1/INS_LO_FCPE_update.txt"; % Updated INS for LiDAR
filename_2_out_23 = "./results/2021-11-10/bag1/VO2INS_FCPE_update.txt"; % Updated Visual Odometry
filename_3_out_23 = "./results/2021-11-10/bag1/INS_VO_FCPE_update.txt"; % Updated INS for Camera
filename_1_out_12 = "./results/2021-11-10/bag1/LO2VO_FCPE_update.txt"; % Updated LiDAR Odometry
filename_2_out_12 = "./results/2021-11-10/bag1/VO_LO_FCPE_update.txt"; % Updated Visual Odometry for LiDAR
filename_x_13 = "./results/2021-11-10/bag1/x_LI_FCPE_update.mat"; % Updated LiDAR to INS Extrinsic
filename_x_23 = "./results/2021-11-10/bag1/x_CI_FCPE_update.mat"; % Updated Camera to INS Extrinsic
filename_x_12 = "./results/2021-11-10/bag1/x_LC_FCPE_update.mat"; % Updated LiDAR to Camera Extrinsic
%% Fix LiDAR to Camera Extrinsic (Translation Only)
t_12 = [-0.5, 0.06, 0.0]; % x y z
%% Read Pose Data
interval_13 = 5;
interval_23 = 5;
interval_12 = 5;
data_1 = load(filename_1, '-ascii');
data_2 = load(filename_2, '-ascii');
data_3 = load(filename_3, '-ascii');
timestamp_1 = data_1(:, 1);
timestamp_2 = data_2(:, 1);
timestamp_3 = data_3(:, 1);
pose_1 = data_1(:, 2 : 8);
pose_2 = data_2(:, 2 : 8);
pose_3 = data_3(:, 2 : 8);
%% Coordinate Transformation
% LiDAR Odometry
R0_1 = quat2rotm(pose_1(1, 4 : 7)); % qw qx qy qz
t0_1 = pose_1(1, 1 : 3);
[m, ~] = size(pose_1);
for i = 1 : m
    pose_1(i, 1 : 3) = R0_1 \ (pose_1(i, 1 : 3)' - t0_1');
    R = R0_1 \ quat2rotm(pose_1(i, 4 : 7)); % qw qx qy qz
    quat = rotm2quat(R); % qw qx qy qz
    pose_1(i, 4 : 7) = quat; % qw qx qy qz
end
% Visual Odometry
R0_2 = quat2rotm(pose_2(1, 4 : 7)); % qw qx qy qz
t0_2 = pose_2(1, 1 : 3);
[n, ~] = size(pose_2);
for i = 1 : n
    pose_2(i, 1 : 3) = R0_2 \ (pose_2(i, 1 : 3)' - t0_2');
    R = R0_2 \ quat2rotm(pose_2(i, 4 : 7)); % qw qx qy qz
    quat = rotm2quat(R); % qw qx qy qz
    pose_2(i, 4 : 7) = quat; % qw qx qy qz
end
% INS
R0_3 = quat2rotm(pose_3(1, 4 : 7)); % qw qx qy qz
t0_3 = pose_3(1, 1 : 3);
[p, ~] = size(pose_3);
for i = 1 : p
    pose_3(i, 1 : 3) = R0_3 \ (pose_3(i, 1 : 3)' - t0_3');
    R = R0_3 \ quat2rotm(pose_3(i, 4 : 7)); % qw qx qy qz
    quat = rotm2quat(R); % qw qx qy qz
    pose_3(i, 4 : 7) = quat; % qw qx qy qz
end
%% Pose Interpolation
[pose_1_interp_13, timestamp_1_interp_13, pose_3_interp_13, timestamp_3_interp_13] = poseInterp(pose_1(1 : interval_13 : end, :), timestamp_1(1 : interval_13 : end, :), pose_3, timestamp_3);
[pose_2_interp_23, timestamp_2_interp_23, pose_3_interp_23, timestamp_3_interp_23] = poseInterp(pose_2(1 : interval_23 : end, :), timestamp_2(1 : interval_23 : end, :), pose_3, timestamp_3);
[pose_1_interp_12, timestamp_1_interp_12, pose_2_interp_12, timestamp_2_interp_12] = poseInterp(pose_1(1 : interval_12 : end, :), timestamp_1(1 : interval_12 : end, :), pose_2, timestamp_2);
%% Plot to Check Data
figure
subplot(1, 3, 1)
hold on
grid on
axis equal
plot3(pose_1_interp_13(:, 1), pose_1_interp_13(:, 2), pose_1_interp_13(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_3_interp_13(:, 1), pose_3_interp_13(:, 2), pose_3_interp_13(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('Before Calibration')
legend('LiDAR Odometry', 'INS')
view(3)
subplot(1, 3, 2)
hold on
grid on
axis equal
plot3(pose_2_interp_23(:, 1), pose_2_interp_23(:, 2), pose_2_interp_23(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_3_interp_23(:, 1), pose_3_interp_23(:, 2), pose_3_interp_23(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('Before Calibration')
legend('Visual Odometry', 'INS')
view(3)
subplot(1, 3, 3)
hold on
grid on
axis equal
plot3(pose_1_interp_12(:, 1), pose_1_interp_12(:, 2), pose_1_interp_12(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_2_interp_12(:, 1), pose_2_interp_12(:, 2), pose_2_interp_12(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('Before Calibration')
legend('LiDAR Odometry', 'Visual Odometry')
view(3)
%% Optimization
fun = @(x)costFunction_FCPE_quat_interp_2_fix_L2C_translation(pose_1_interp_13, pose_3_interp_13, pose_2_interp_23, pose_3_interp_23, pose_1_interp_12, pose_2_interp_12, t_12, x);
% options = optimset( 'Display', 'iter', 'MaxFunEvals', 1e6, 'MaxIter', 1e6);
options = optimset('PlotFcns', 'optimplotfval', 'MaxFunEvals', 1e6, 'MaxIter', 1e6); % OK
% options = optimset('PlotFcns', 'optimplotfval'); % OK
% Constrained
A = [];
b = [];
Aeq = [];
beq = [];
lb = [-1, -1, -1, -2, -2, -2, -2, ...
    -1, -1, -1, -2, -2, -2, -2, 0, ...
    -2, -2, -2, -2, 0];
ub = [1, 1, 1, 2, 2, 2, 2, ...
    1, 1, 1, 2, 2, 2, 2, 10, ...
    2, 2, 2, 2, 10];
x0 = (lb + ub)/2; % x y z (m) qw qx qy qz
x0(1, 4 : 7) = [1, 0, 0, 0]; % qw qx qy qz
x0(1, 11 : 14) = [1, 0, 0, 0]; % qw qx qy qz
x0(1, 16 : 19) = [1, 0, 0, 0]; % qw qx qy qz
[x, fval, exitflag, output] = fmincon(fun, x0, A, b, Aeq, beq, lb, ub, [], options); % Constrained
% Do not use normalize()!!!
x(1, 4 : 7) = x(1, 4 : 7) / sqrt(sum(x(1, 4 : 7).^2));
x(1, 11 : 14) = x(1, 11 : 14) / sqrt(sum(x(1, 11 : 14).^2));
x(1, 16 : 19) = x(1, 16 : 19) / sqrt(sum(x(1, 16 : 19).^2));
%% Print Results
x_13 = x(1, 1 : 7);
x_23 = x(1, 8 : 15);
x_12 = [t_12, x(1, 16 : 20)];
scale_23 = x(1, 15);
scale_12 = x(1, 20);
fprintf("------------------------------ Results ------------------------------\n")
fprintf("LiDAR -> INS Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tqw\t\t|\tqx\t\t|\tqy\t\t|\tqz\t\t|\n")
fprintf("LiDAR -> INS Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x_13)
fprintf("LiDAR -> INS Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tYaw\t\t|\tPitch\t|\tRoll\t|\n")
fprintf("LiDAR -> INS Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x_13(1, 1 : 3), quat2eul(x_13(1, 4 : 7), 'ZYX'))
T13 = quat2tform(x_13(1, 4 : 7));
T13(1 : 3, 4) = x_13(1, 1 : 3)';
fprintf("T13 = \n")
disp(T13)
fprintf("---------------------------------------------------------------------\n")
fprintf("Camera -> INS Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tqw\t\t|\tqx\t\t|\tqy\t\t|\tqz\t\t|\tScale\t|\n")
fprintf("Camera -> INS Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x_23)
fprintf("Camera -> INS Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tYaw\t\t|\tPitch\t|\tRoll\t|\tScale\t|\n")
fprintf("Camera -> INS Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x_23(1, 1 : 3), quat2eul(x_23(1, 4 : 7), 'ZYX'), scale_23)
T23 = quat2tform(x_23(1, 4 : 7));
T23(1 : 3, 4) = x_23(1, 1 : 3)';
fprintf("T23 = \n")
disp(T23)
fprintf("---------------------------------------------------------------------\n")
fprintf("LiDAR -> Camera Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tqw\t\t|\tqx\t\t|\tqy\t\t|\tqz\t\t|\tScale\t|\n")
fprintf("LiDAR -> Camera Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x_12)
fprintf("LiDAR -> Camera Extrinsic: |\tX\t\t|\tY\t\t|\tZ\t\t|\tYaw\t\t|\tPitch\t|\tRoll\t|\tScale\t|\n")
fprintf("LiDAR -> Camera Extrinsic: |\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\t%.4f\t|\n", x_12(1, 1 : 3), quat2eul(x_12(1, 4 : 7), 'ZYX'), scale_12)
T12 = quat2tform(x_12(1, 4 : 7));
T12(1 : 3, 4) = x_12(1, 1 : 3)';
fprintf("T12 = \n")
disp(T12)
%% Save Extrinsic
save(filename_x_13, 'x_13', '-ascii', '-double');
save(filename_x_23, 'x_23', '-ascii', '-double');
save(filename_x_12, 'x_12', '-ascii', '-double');
%% Transform
% LiDAR to INS
[m, ~] = size(pose_1_interp_13);
pose_L2I = zeros(m, 7);
for i = 1 : m
    pose_1_temp = quat2tform(pose_1_interp_13(i, 4 : 7));
    pose_1_temp(1 : 3, 4) = pose_1_interp_13(i, 1 : 3)';
    pose_L2I_temp = T13 \ pose_1_temp * T13; % Correct!!!
    pose_L2I(i, :) = [pose_L2I_temp(1 : 3, 4)', tform2quat(pose_L2I_temp)];
end
% Camera to INS
[n, ~] = size(pose_2_interp_23);
pose_C2I = zeros(n, 7);
for i = 1 : n
    pose_2_temp = quat2tform(pose_2_interp_23(i, 4 : 7));
    pose_2_temp(1 : 3, 4) = pose_2_interp_23(i, 1 : 3)' * scale_23;
    pose_C2I_temp = T23 \ pose_2_temp * T23; % Correct!!!
    pose_C2I(i, :) = [pose_C2I_temp(1 : 3, 4)', tform2quat(pose_C2I_temp)];
end
% LiDAR to Camera
[p, ~] = size(pose_1_interp_12);
pose_L2C = zeros(p, 7);
for i = 1 : p
    pose_1_temp = quat2tform(pose_1_interp_12(i, 4 : 7));
    pose_1_temp(1 : 3, 4) = pose_1_interp_12(i, 1 : 3)';
    pose_L2C_temp = T12 \ pose_1_temp * T12; % Correct!!!
    pose_L2C(i, :) = [pose_L2C_temp(1 : 3, 4)', tform2quat(pose_L2C_temp)];
end
%% Plot to Check Data
figure
subplot(1, 3, 1)
hold on
grid on
axis equal
plot3(pose_1_interp_13(:, 1), pose_1_interp_13(:, 2), pose_1_interp_13(:, 3), 'k^-.', 'LineWidth', 1)
plot3(pose_L2I(:, 1), pose_L2I(:, 2), pose_L2I(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_3_interp_13(:, 1), pose_3_interp_13(:, 2), pose_3_interp_13(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('After Calibration')
legend('LiDAR Pose Original', 'LiDAR Pose Transformed', 'INS')
view(3)
subplot(1, 3, 2)
hold on
grid on
axis equal
plot3(pose_2_interp_23(:, 1), pose_2_interp_23(:, 2), pose_2_interp_23(:, 3), 'k^-.', 'LineWidth', 1)
plot3(pose_C2I(:, 1), pose_C2I(:, 2), pose_C2I(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_3_interp_23(:, 1), pose_3_interp_23(:, 2), pose_3_interp_23(:, 3), 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('After Calibration')
legend('Camera Pose Original', 'Camera Pose Transformed', 'INS')
view(3)
subplot(1, 3, 3)
hold on
grid on
axis equal
plot3(pose_1_interp_12(:, 1), pose_1_interp_12(:, 2), pose_1_interp_12(:, 3), 'k^-.', 'LineWidth', 1)
plot3(pose_L2C(:, 1), pose_L2C(:, 2), pose_L2C(:, 3), 'bo-', 'LineWidth', 2)
plot3(pose_2_interp_12(:, 1) * scale_12, pose_2_interp_12(:, 2) * scale_12, pose_2_interp_12(:, 3) * scale_12, 'rs-', 'LineWidth', 2)
xlabel('X / m')
ylabel('Y / m')
zlabel('Z / m')
title('After Calibration')
legend('LiDAR Pose Original', 'LiDAR Pose Transformed', 'Camera Pose with Scale')
view(3)
%% Export Poses for Evaluation
writematrix([timestamp_1_interp_13, pose_L2I], filename_1_out_13, 'Delimiter', ' ')
writematrix([timestamp_3_interp_13, pose_3_interp_13], filename_3_out_13, 'Delimiter', ' ')
writematrix([timestamp_2_interp_23, pose_C2I], filename_2_out_23, 'Delimiter', ' ')
writematrix([timestamp_3_interp_23, pose_3_interp_23], filename_3_out_23, 'Delimiter', ' ')
writematrix([timestamp_1_interp_12, pose_L2C], filename_1_out_12, 'Delimiter', ' ')
writematrix([timestamp_2_interp_12, pose_2_interp_12 * scale_12], filename_2_out_12, 'Delimiter', ' ')