meas_paths = {};

% ===================================================================
% User Settings
% ===================================================================

fn = 'D:\data\mcords\20120918\board0\seg_09\tek0007.csv'
csv_format = '%f %f %f %f %f';
oscilloscope_bin_rng = 100000:150000; % Plot 
adcs = [1 2 3 4 5];
meas_paths{1} = 'D:\data\mcords\20120918\board0\seg_09\';
meas_paths{2} = 'D:\data\mcords\20120918\board0\seg_10\';
meas_paths{3} = 'D:\data\mcords\20120918\board0\seg_11\';
meas_paths{4} = 'D:\data\mcords\20120918\board0\seg_12\';
meas_paths{5} = 'D:\data\mcords\20120918\board1\seg_13\';

adc_bits = 14;
Vpp_scale = [2.22 2.26 2.23 2.23 2.21];
test_gain = 10^((-(0))/20);
fc = 194e6;

% ===================================================================
% Automated Section
% ===================================================================
fid = fopen(fn,'r');
C = textscan(fid,csv_format,'HeaderLines',15,'Delimiter',',');
fclose(fid);
tx_signal_time = C{1};
tx_signal = C{2};
clear C;


figure(1); clf;
fig_pos = get(1,'Position');
set(1,'Position',[fig_pos(1:2) 827 362]);
plot(tx_signal_time*1e6,tx_signal);
grid on;
xlabel('DSO time (us)');
ylabel('volts (V)');

% Find the envelope of the signal
[B,A] = butter(4,0.1);
tx_baseband = filtfilt(B, A, 2*tx_signal .* exp(-j*2*pi*fc*tx_signal_time));

figure(2); clf;
fig_pos = get(2,'Position');
set(2,'Position',[fig_pos(1:2) 827 362]);
plot(tx_signal_time*1e6,abs(tx_baseband));
grid on;
xlabel('DSO time (us)');
ylabel('volts (V)');

Nt = length(tx_signal_time);
dt = tx_signal_time(2) - tx_signal_time(1);
T = Nt*dt;
df = 1/T;
freq = df*(0:Nt-1).';

figure(3); clf;
plot(freq/1e6, lp(fft(tx_signal)));
hold on;
plot(freq/1e6, lp(fft(tx_baseband)),'r');
hold off;
grid on;

% Find the mean and standard deviation power
mean_input_amp = mean(abs(tx_baseband(oscilloscope_bin_rng)))
std(abs(tx_baseband(oscilloscope_bin_rng)))


figure(4); clf;
fig_pos = get(4,'Position');
set(4,'Position',[fig_pos(1:2) 827 362]);
figure(5); clf;
fig_pos = get(5,'Position');
set(5,'Position',[fig_pos(1:2) 827 362]);


colors = {'k' 'r' 'y' 'g' 'c' 'b' 'm' 'k:'};
label_str = {};
rx_gain = {};
rx_gain_time = {};
rline = 1000;

for meas_idx = 1:length(meas_paths)
  
%   fn = get_filename(meas_paths{meas_idx},'mcords','','.0000.dat');
  fn = get_filename(meas_paths{meas_idx},'mcords','','_0002.bin');
  fprintf('%s\n', fn);
  [hdr,data] = basic_load_mcords2(fn,struct('clk',1e9/9));
    
  adc = adcs(meas_idx);
  board_adc = mod(adc-1,4)+1
  for wf = 1:2
    data{wf} = data{wf}(:,:,board_adc) - median(data{wf}(:,1,board_adc));
    data{wf} = data{wf}(1:end-1,:);
    data{wf} = data{wf} ...
      * Vpp_scale(meas_idx)/2^adc_bits ...
      * 2^hdr.wfs(wf).bit_shifts/hdr.wfs(wf).presums ...
      / test_gain / mean_input_amp;
    
    fs = 1e9/9;
    dt = 1/fs;
    Nt = size(data{wf},1);
    rx_time = dt*(0:Nt-1).';
    rx_baseband = filtfilt(B, A, 2*double(data{wf}(:,rline)) .* exp(-j*2*pi*fc*rx_time));
    
    figure(3+wf);
    plot(rx_time*1e6,lp(rx_baseband,2), colors{meas_idx});
    label_str{meas_idx} = sprintf('chan %d', meas_idx);
    hold on;
    grid on;
    xlabel('fast time (us)');
    ylabel('gain (dB)');
    ylim([-20 60]);
    xlim([0 40]);
    drawnow;
    
    rx_gain{wf,meas_idx} = lp(rx_baseband,2);
    rx_gain_time{wf,meas_idx} = rx_time;
  end
end

hold off;
figure(4);
legend(label_str,'Location','East')
figure(5);
legend(label_str,'Location','West')

save('rx_gain_2012_Antarctica_DC8.mat','rx_gain','rx_gain_time');

for wf = 1:size(rx_gain,1)
  fprintf('Approx steady-state gain for wf %d:\n', wf)
  for meas_idx = 1:size(rx_gain,2)
    fprintf('%.1f\t', round(mean(rx_gain{wf,meas_idx}(1500:2000))*100)/100)
  end
  fprintf('\n');
end

return;

