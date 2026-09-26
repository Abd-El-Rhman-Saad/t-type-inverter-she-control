
function SHE_Inverter_Task_Final
     %% 0. Shared Data Containers
    sim_t = []; 
    sim_Vao = []; sim_Van = []; sim_Ia = []; sim_Vab = [];
    sim_Gates = []; sim_Power = []; 
    
    %% 1. Create Main UI Figure
    fig = uifigure('Name', 'SHE Inverter Analysis Tool (Balanced THD)', ...
        'Position', [50, 50, 1350, 850], 'Color', [0.95 0.95 0.95]);
    gridMain = uigridlayout(fig, [1, 2]);
    gridMain.ColumnWidth = {360, '1x'}; 
    
    %% 2. Sidebar - Inputs & Controls
    pnlControl = uipanel(gridMain, 'Title', 'System Parameters', ...
        'FontSize', 12, 'FontWeight', 'bold');
    
    gridCtrl = uigridlayout(pnlControl, [16, 2]); 
    gridCtrl.RowHeight = {30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 45, 40, 40, '1x', 30};
    gridCtrl.ColumnWidth = {'1x', '1x'};
    
    % System Inputs
    uilabel(gridCtrl, 'Text', 'DC Link Voltage (V):', 'HorizontalAlignment', 'right');
    efVdc = uieditfield(gridCtrl, 'numeric', 'Value', 800);
    uilabel(gridCtrl, 'Text', 'Target V_fund (V):', 'HorizontalAlignment', 'right');
    efVref = uieditfield(gridCtrl, 'numeric', 'Value', 400); 
    uilabel(gridCtrl, 'Text', 'Frequency (Hz):', 'HorizontalAlignment', 'right');
    efFreq = uieditfield(gridCtrl, 'numeric', 'Value', 50);
    uilabel(gridCtrl, 'Text', 'Load R (Ohm):', 'HorizontalAlignment', 'right');
    efR = uieditfield(gridCtrl, 'numeric', 'Value', 7.07);
    uilabel(gridCtrl, 'Text', 'Load X (Ohm):', 'HorizontalAlignment', 'right');
    efX = uieditfield(gridCtrl, 'numeric', 'Value', 7.07);
    
    % Solver Initial Guesses
    lblSep = uilabel(gridCtrl, 'Text', '--- Solver Initial Guess ---', 'HorizontalAlignment', 'center');
    lblSep.Layout.Row = 6;            
    lblSep.Layout.Column = [1 2];     
    uilabel(gridCtrl, 'Text', 'Alpha 1 (deg):', 'HorizontalAlignment', 'right');
    efA1 = uieditfield(gridCtrl, 'numeric', 'Value', 20);
    uilabel(gridCtrl, 'Text', 'Alpha 2 (deg):', 'HorizontalAlignment', 'right');
    efA2 = uieditfield(gridCtrl, 'numeric', 'Value', 40);
    uilabel(gridCtrl, 'Text', 'Alpha 3 (deg):', 'HorizontalAlignment', 'right');
    efA3 = uieditfield(gridCtrl, 'numeric', 'Value', 60);
    
    % Controls
    btnRun = uibutton(gridCtrl, 'push', ...
        'Text', 'CALCULATE & SIMULATE', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0 0.45 0.74], ... 
        'FontColor', 'white', ...
        'ButtonPushedFcn', @runSimulation);
    btnRun.Layout.Column = [1 2];
    btnRun.Layout.Row = 11;
    
    btnExport = uibutton(gridCtrl, 'push', ...
        'Text', 'EXPORT DATA TO WORKSPACE', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.93 0.69 0.13], ... 
        'FontColor', 'black', ...
        'Enable', 'off', ... 
        'ButtonPushedFcn', @exportData);
    btnExport.Layout.Column = [1 2];
    btnExport.Layout.Row = 12;

    % SAVE PLOTS BUTTON
    btnSaveImg = uibutton(gridCtrl, 'push', ...
        'Text', 'SAVE ALL PLOTS & REPORT', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.47 0.67 0.19], ... 
        'FontColor', 'white', ...
        'Enable', 'off', ... 
        'ButtonPushedFcn', @saveImages);
    btnSaveImg.Layout.Column = [1 2];
    btnSaveImg.Layout.Row = 13;
    
    txtResults = uitextarea(gridCtrl, 'Editable', 'off', ...
        'FontSize', 10, 'FontName', 'Monospaced', ...
        'Value', {'Ready...'});
    txtResults.Layout.Column = [1 2];
    txtResults.Layout.Row = 14;
    
    %% 3. Visualization Tabs
    tabGroup = uitabgroup(gridMain);
    
    % Tab 1: Voltage Waveforms
    tabTime = uitab(tabGroup, 'Title', 'Voltages (Time)');
    gridTime = uigridlayout(tabTime, [3, 1]);
    axVao = uiaxes(gridTime); 
    title(axVao, 'Pole Voltage Vao'); xlabel(axVao, 'Time (ms)'); ylabel(axVao, 'Voltage (V)'); grid(axVao, 'on');
    
    axVan = uiaxes(gridTime); 
    title(axVan, 'Phase Voltage Van'); xlabel(axVan, 'Time (ms)'); ylabel(axVan, 'Voltage (V)'); grid(axVan, 'on');
    
    axVab = uiaxes(gridTime); 
    title(axVab, 'Line Voltage Vab'); xlabel(axVab, 'Time (ms)'); ylabel(axVab, 'Voltage (V)'); grid(axVab, 'on');
    
    % Tab 2: Voltage Spectrum (UPDATED to include Van)
    tabFreq = uitab(tabGroup, 'Title', 'Voltage Spectrum');
    gridFreq = uigridlayout(tabFreq, [3, 1]); % Changed to 3 rows
    
    axFFT_Vao = uiaxes(gridFreq); 
    title(axFFT_Vao, 'FFT: Pole Voltage'); xlabel(axFFT_Vao, 'Frequency (Hz)'); ylabel(axFFT_Vao, 'Mag (V)'); grid(axFFT_Vao, 'on');

    axFFT_Van = uiaxes(gridFreq); % ADDED THIS
    title(axFFT_Van, 'FFT: Phase Voltage (Van)'); xlabel(axFFT_Van, 'Frequency (Hz)'); ylabel(axFFT_Van, 'Mag (V)'); grid(axFFT_Van, 'on');
    
    axFFT_Vab = uiaxes(gridFreq); 
    title(axFFT_Vab, 'FFT: Line Voltage'); xlabel(axFFT_Vab, 'Frequency (Hz)'); ylabel(axFFT_Vab, 'Mag (V)'); grid(axFFT_Vab, 'on');
    
    % Tab 3: Currents & FFT
    tabCurr = uitab(tabGroup, 'Title', 'Phase Currents & FFT');
    gridCurr = uigridlayout(tabCurr, [2, 3]); 
    gridCurr.RowHeight = {'1x', '1x'};
    
    axIa  = uiaxes(gridCurr); 
    axIa.Layout.Row = 1; axIa.Layout.Column = [1 3]; 
    title(axIa, '3-Phase Currents'); xlabel(axIa, 'Time (ms)'); ylabel(axIa, 'Current (A)'); grid(axIa, 'on');
    
    axFFT_Ia = uiaxes(gridCurr); 
    axFFT_Ia.Layout.Row = 2; axFFT_Ia.Layout.Column = 1;
    title(axFFT_Ia, 'FFT Phase A'); xlabel(axFFT_Ia, 'Freq (Hz)'); ylabel(axFFT_Ia, 'Mag (A)'); grid(axFFT_Ia, 'on');
    
    axFFT_Ib = uiaxes(gridCurr); 
    axFFT_Ib.Layout.Row = 2; axFFT_Ib.Layout.Column = 2;
    title(axFFT_Ib, 'FFT Phase B'); xlabel(axFFT_Ib, 'Freq (Hz)'); ylabel(axFFT_Ib, 'Mag (A)'); grid(axFFT_Ib, 'on');
    
    axFFT_Ic = uiaxes(gridCurr); 
    axFFT_Ic.Layout.Row = 2; axFFT_Ic.Layout.Column = 3;
    title(axFFT_Ic, 'FFT Phase C'); xlabel(axFFT_Ic, 'Freq (Hz)'); ylabel(axFFT_Ic, 'Mag (A)'); grid(axFFT_Ic, 'on');
    
    % Tab 4: Power Analysis
    tabPower = uitab(tabGroup, 'Title', 'Power Flow');
    gridPower = uigridlayout(tabPower, [1, 1]);
    axPower = uiaxes(gridPower); 
    title(axPower, 'Instantaneous Power'); 
    ylabel(axPower, 'Power (W)'); xlabel(axPower, 'Time (ms)'); grid(axPower, 'on');
    
    % Tab 5: Gate Signals
    tabGates = uitab(tabGroup, 'Title', 'Gate Signals');
    gridGates = uigridlayout(tabGates, [4, 1]); 
    axG1 = uiaxes(gridGates); title(axG1, 'T1 (Top - +Vdc)'); axG1.YTick = [0 1]; ylim(axG1, [-0.1 1.1]);
    axG2 = uiaxes(gridGates); title(axG2, 'T2 (Mid - Neutral)'); axG2.YTick = [0 1]; ylim(axG2, [-0.1 1.1]);
    axG3 = uiaxes(gridGates); title(axG3, 'T3 (Mid - Neutral)'); axG3.YTick = [0 1]; ylim(axG3, [-0.1 1.1]);
    axG4 = uiaxes(gridGates); title(axG4, 'T4 (Bot - -Vdc)'); axG4.YTick = [0 1]; ylim(axG4, [-0.1 1.1]);
    
    % Tab 6: Trajectory
    tabTraj = uitab(tabGroup, 'Title', 'Trajectory');
    gridTraj = uigridlayout(tabTraj, [1, 1]);
    axTraj = uiaxes(gridTraj); title(axTraj, 'Switching Angles vs Modulation Index (Ma)'); grid(axTraj, 'on');
    
    %% 4. Main Computation Routine
    function runSimulation(~, ~)
        btnRun.Enable = 'off';
        btnRun.Text = 'Computing...';
        drawnow;
        
        try
            % -- A. Get Inputs
            Vdc_val = efVdc.Value;
            Vref_val = efVref.Value;
            F_fund = efFreq.Value;
            R_load = efR.Value;
            X_load = efX.Value;
            init_angles = [efA1.Value, efA2.Value, efA3.Value];
            
            w = 2*pi*F_fund;
            L_load = X_load / w;
            Ma_target = Vref_val / (Vdc_val/2);
            
            if Ma_target > 1.15
                 uialert(fig, 'Modulation Index > 1.15 exceeds limits.', 'Parameter Error');
                 btnRun.Enable = 'on'; btnRun.Text = 'CALCULATE & SIMULATE'; return;
            end
            
            % -- B. Solve SHE Equations
            opt = optimoptions('fsolve', 'Display', 'off', 'TolFun', 1e-9);
            fun = @(a) she_equations(a, Vdc_val, Vref_val);
            [angles_rad, ~, exitflag] = fsolve(fun, deg2rad(init_angles), opt);
            
            if exitflag <= 0
                uialert(fig, 'Solver failed to converge.', 'Solver Error');
                btnRun.Enable = 'on'; btnRun.Text = 'CALCULATE & SIMULATE';
                return;
            end
            angles_deg = sort(mod(rad2deg(angles_rad), 90)); 
            angles_rad = deg2rad(angles_deg); 
            
            % -- C. Simulation
            btnRun.Text = 'Simulating...'; drawnow;
            Ts = 1e-5; T_end = 0.04; t = 0:Ts:T_end;
            
            Vao = generate_pwm(t, angles_rad, Vdc_val, 0, F_fund);
            Vbo = generate_pwm(t, angles_rad, Vdc_val, -2*pi/3, F_fund);
            Vco = generate_pwm(t, angles_rad, Vdc_val, 2*pi/3, F_fund);
            
            Vab = Vao - Vbo;
            Vno = (Vao + Vbo + Vco) / 3; 
            Van = Vao - Vno; Vbn = Vbo - Vno; Vcn = Vco - Vno;
            
            % Current Calculation
            Ia = zeros(size(t)); Ib = zeros(size(t)); Ic = zeros(size(t));
            k_const = Ts/L_load; 
            for k = 2:length(t)
                Ia(k) = Ia(k-1) + k_const * (Van(k-1) - R_load*Ia(k-1));
                Ib(k) = Ib(k-1) + k_const * (Vbn(k-1) - R_load*Ib(k-1));
                Ic(k) = Ic(k-1) + k_const * (Vcn(k-1) - R_load*Ic(k-1));
            end
            Ia = Ia - mean(Ia); Ib = Ib - mean(Ib); Ic = Ic - mean(Ic);
            
            % -- Power Analysis
            P_inst = Van.*Ia + Vbn.*Ib + Vcn.*Ic;
            
            % >>> STEADY STATE SLICING (CRITICAL FOR EQUAL THD) <<<
            % We only use the last fundamental cycle for FFT and RMS
            idx_cycle = t > (T_end - 1/F_fund);
            
            Van_ss = Van(idx_cycle); Vab_ss = Vab(idx_cycle); Vao_ss = Vao(idx_cycle);
            Ia_ss = Ia(idx_cycle);   Ib_ss = Ib(idx_cycle);   Ic_ss = Ic(idx_cycle);
            
            V_rms_phase = rms(Van_ss);
            I_rms_phase = rms(Ia_ss);
            V_rms_line  = rms(Vab_ss);
            
            S_total = 3 * V_rms_phase * I_rms_phase;
            P_total = mean(P_inst(idx_cycle));      
            Q_total = sqrt(S_total^2 - P_total^2);  
            PF = P_total / S_total;                 
            
            % Efficiency Est
            P_conduction_loss = 3 * I_rms_phase * 1.7; 
            P_switching_loss  = P_total * 0.015;       
            P_loss_total = P_conduction_loss + P_switching_loss;
            Eff_est = (P_total / (P_total + P_loss_total)) * 100;

            % -- FFT Analysis (USING STEADY STATE SIGNALS)
            [f, magVab] = get_fft(Vab_ss, Ts, F_fund);
            [~, magIa]  = get_fft(Ia_ss,  Ts, F_fund);
            [~, magVan] = get_fft(Van_ss, Ts, F_fund);
            [~, magVao] = get_fft(Vao_ss, Ts, F_fund);
            
            [~, magIb]  = get_fft(Ib_ss,  Ts, F_fund);
            [~, magIc]  = get_fft(Ic_ss,  Ts, F_fund);
            
            % Fundamental Values
            Fund_Vab = magVab(1); Fund_Van = magVan(1); Fund_Vao = magVao(1);
            Fund_Ia  = magIa(1);  Fund_Ib  = magIb(1);  Fund_Ic  = magIc(1);
            
            % THD Calculation
            THD_Vab = (sqrt(sum(magVab(2:end).^2)) / Fund_Vab) * 100;
            THD_Van = (sqrt(sum(magVan(2:end).^2)) / Fund_Van) * 100;
            THD_Vao = (sqrt(sum(magVao(2:end).^2)) / Fund_Vao) * 100;
            THD_Ia  = (sqrt(sum(magIa(2:end).^2)) / Fund_Ia) * 100;
            THD_Ib  = (sqrt(sum(magIb(2:end).^2)) / Fund_Ib) * 100;
            THD_Ic  = (sqrt(sum(magIc(2:end).^2)) / Fund_Ic) * 100;
            
            % Weighted THD
            wthd_sum = 0;
            for n = 2:20, wthd_sum = wthd_sum + (magVab(n)/n)^2; end
            WTHD_V = (sqrt(wthd_sum) / Fund_Vab) * 100;
            
            % -- Gate Logic (T-Type Mapped)
            threshold = Vdc_val / 4; 
            isP = Vao > threshold; 
            isN = Vao < -threshold; 
            isO = ~isP & ~isN;
            
            T1 = double(isP);      
            T4 = double(isN);      
            T2 = double(isO);      
            T3 = double(isO);      
            
            % Store Data
            sim_t = t; sim_Vao = Vao; sim_Van = Van; sim_Ia = [Ia; Ib; Ic]; sim_Vab = Vab; 
            sim_Gates = [T1; T2; T3; T4]; sim_Power = P_inst;
            btnExport.Enable = 'on';
            btnSaveImg.Enable = 'on';
            
            % -- H. Generate Report --
            resStr = sprintf('=== SIMULATION RESULTS ===\n');
            resStr = [resStr, sprintf('Angles: %.2f, %.2f, %.2f deg\n', angles_deg(1), angles_deg(2), angles_deg(3))];
            resStr = [resStr, sprintf('Modulation Index: %.4f\n\n', Ma_target)];
            
            resStr = [resStr, sprintf('--- POWER METRICS ---\n')];
            resStr = [resStr, sprintf('Real Power (P):   %.3f kW\n', P_total/1000)];
            resStr = [resStr, sprintf('Reactive (Q):     %.3f kVAR\n', Q_total/1000)];
            resStr = [resStr, sprintf('Apparent (S):     %.3f kVA\n', S_total/1000)];
            resStr = [resStr, sprintf('Power Factor:     %.4f\n', PF)];
            resStr = [resStr, sprintf('Est. Efficiency:  %.2f %%\n\n', Eff_est)];
            
            resStr = [resStr, sprintf('--- QUALITY METRICS ---\n')];
            resStr = [resStr, sprintf('V_line RMS:       %.1f V\n', V_rms_line)];
            
            if THD_Ia < 5.0, pass_str = '(PASS)'; else, pass_str = '(FAIL)'; end
            % Show ALL THD to prove symmetry
            resStr = [resStr, sprintf('THD Ia:           %.4f %%\n', THD_Ia)];
            resStr = [resStr, sprintf('THD Ib:           %.4f %%\n', THD_Ib)];
            resStr = [resStr, sprintf('THD Ic:           %.4f %% %s\n', THD_Ic, pass_str)];
            resStr = [resStr, sprintf('Voltage THD:      %.4f %%\n', THD_Vab)];
            
            txtResults.Value = resStr;
            
            % -- Visualization --
            
            % Colors
            colA = [0 0.4470 0.7410]; colB = [0.8500 0.3250 0.0980]; colC = [0.9290 0.6940 0.1250];
            
            % Tab 1: Voltages (Updated Titles with Fund + THD)
            plot(axVao, t*1000, Vao, 'LineWidth', 1.5, 'Color', colA); 
            xlim(axVao, [0 40]); ylim(axVao, [-Vdc_val/2*1.1, Vdc_val/2*1.1]);
            title(axVao, sprintf('Pole Voltage Vao (Fund: %.1fV, THD: %.2f%%)', Fund_Vao, THD_Vao));
            
            plot(axVan, t*1000, Van, 'LineWidth', 1.5, 'Color', colA); 
            xlim(axVan, [0 40]); ylim(axVan, [-max(abs(Van))*1.1, max(abs(Van))*1.1]);
            title(axVan, sprintf('Phase Voltage Van (Fund: %.1fV, THD: %.2f%%)', Fund_Van, THD_Van));
            
            plot(axVab, t*1000, Vab, 'LineWidth', 1.5, 'Color', colA); xlim(axVab, [0 40]);
            ylim(axVab, [-max(abs(Vab))*1.1, max(abs(Vab))*1.1]);
            title(axVab, sprintf('Line Voltage Vab (Fund: %.1fV, THD: %.2f%%)', Fund_Vab, THD_Vab));
            
            % Tab 2: Voltage Spectrum (Updated Titles + Limits)
            b1 = bar(axFFT_Vao, f(1:25)/F_fund, magVao(1:25)); b1.FaceColor = 'flat'; 
            b1.CData(5,:) = [1 0 0]; b1.CData(7,:) = [1 0 0];
            yline(axFFT_Vao, 0.03*Fund_Vao, '--r', '3% Limit'); % Limit Line Added
            title(axFFT_Vao, sprintf('FFT Pole Voltage (Fund: %.1fV, THD: %.2f%%)', Fund_Vao, THD_Vao));
            xlim(axFFT_Vao, [0 25]);
            
            % NEW: Phase Voltage FFT
            cla(axFFT_Van); hold(axFFT_Van, 'on');
            bar(axFFT_Van, f(1:25)/F_fund, magVan(1:25), 'FaceColor', colA);
            yline(axFFT_Van, 0.03*Fund_Van, '--r'); 
            hold(axFFT_Van, 'off'); 
            title(axFFT_Van, sprintf('FFT Phase Voltage (Fund: %.1fV, THD: %.2f%%)', Fund_Van, THD_Van));
            xlim(axFFT_Van, [0 25]);

            cla(axFFT_Vab); hold(axFFT_Vab, 'on');
            bar(axFFT_Vab, f(1:25)/F_fund, magVab(1:25));
            yline(axFFT_Vab, 0.03*Fund_Vab, '--r', '3% Limit', 'LineWidth', 1.5); % Limit Line Added
            hold(axFFT_Vab, 'off'); 
            title(axFFT_Vab, sprintf('FFT Line Voltage (Fund: %.1fV, THD: %.2f%%)', Fund_Vab, THD_Vab));
            xlim(axFFT_Vab, [0 25]);
            
            % Tab 3: Currents & FFT (Updated Titles + Limits for ALL)
            cla(axIa); hold(axIa, 'on');
            plot(axIa, t*1000, Ia, 'LineWidth', 1.5, 'Color', colA); 
            plot(axIa, t*1000, Ib, 'LineWidth', 1.5, 'Color', colB); 
            plot(axIa, t*1000, Ic, 'LineWidth', 1.5, 'Color', colC);
            hold(axIa, 'off'); legend(axIa, 'Ia','Ib','Ic'); xlim(axIa, [0 40]);
            title(axIa, sprintf('3-Phase Currents (Fund: %.1fA, THD: %.2f%%)', Fund_Ia, THD_Ia));
            
            % FFT Phase A
            cla(axFFT_Ia); hold(axFFT_Ia, 'on');
            bar(axFFT_Ia, f(1:25)/F_fund, magIa(1:25), 'FaceColor', colA);
            yline(axFFT_Ia, 0.03*Fund_Ia, '--r', '3% Limit'); % Limit Line Added
            hold(axFFT_Ia, 'off'); xlim(axFFT_Ia, [0 25]);
            title(axFFT_Ia, sprintf('FFT Phase A (Fund: %.1fA, THD: %.2f%%)', Fund_Ia, THD_Ia));
            
            % FFT Phase B
            cla(axFFT_Ib); hold(axFFT_Ib, 'on');
            bar(axFFT_Ib, f(1:25)/F_fund, magIb(1:25), 'FaceColor', colB); 
            yline(axFFT_Ib, 0.03*Fund_Ib, '--r'); % Limit Line Added
            hold(axFFT_Ib, 'off'); xlim(axFFT_Ib, [0 25]);
            title(axFFT_Ib, sprintf('FFT Phase B (Fund: %.1fA, THD: %.2f%%)', Fund_Ib, THD_Ib));
            
            % FFT Phase C
            cla(axFFT_Ic); hold(axFFT_Ic, 'on');
            bar(axFFT_Ic, f(1:25)/F_fund, magIc(1:25), 'FaceColor', colC); 
            yline(axFFT_Ic, 0.03*Fund_Ic, '--r'); % Limit Line Added
            hold(axFFT_Ic, 'off'); xlim(axFFT_Ic, [0 25]);
            title(axFFT_Ic, sprintf('FFT Phase C (Fund: %.1fA, THD: %.2f%%)', Fund_Ic, THD_Ic));
            
            % Tab 4: Power
            plot(axPower, t*1000, P_inst, 'LineWidth', 1.5, 'Color', [0.5 0 0.5]); 
            yline(axPower, P_total, '--k', sprintf('Avg P: %.2fkW', P_total/1000));
            xlim(axPower, [0 40]); title(axPower, sprintf('Instantaneous Power (Eff: %.1f%%)', Eff_est));
            
            % Tab 5: Gates
            stairs(axG1, t*1000, T1, 'b'); stairs(axG2, t*1000, T2, 'g'); 
            stairs(axG3, t*1000, T3, 'Color',[0.8 0.4 0]); stairs(axG4, t*1000, T4, 'r');
            for ax = [axG1, axG2, axG3, axG4], xlim(ax, [0 40]); grid(ax,'on'); end
            
            % Tab 6: Trajectory
            btnRun.Text = 'Computing Trajectory...'; drawnow;
            computeTrajectory(Ma_target, Vdc_val, init_angles);
            
        catch ME
            uialert(fig, ME.message, 'Simulation Error');
        end
        
        btnRun.Enable = 'on'; btnRun.Text = 'CALCULATE & SIMULATE';
    end
    
    %% 5. Helper Functions
    function computeTrajectory(currentMa, Vdc, initialGuess)
        ma_range = 0.1:0.02:1.15; n_steps = length(ma_range);
        res_a = nan(3, n_steps);
        last_sol = deg2rad(initialGuess);
        opt = optimoptions('fsolve', 'Display', 'off', 'TolFun', 1e-6);
        for i = 1:n_steps
            fun = @(a) she_equations(a, Vdc, ma_range(i)*(Vdc/2));
            [sol, ~, flag] = fsolve(fun, last_sol, opt);
            if flag > 0
                sol_deg = sort(mod(rad2deg(sol), 90)); 
                res_a(:, i) = sol_deg; last_sol = sol; 
            end
        end
        cla(axTraj); hold(axTraj, 'on');
        plot(axTraj, ma_range, res_a(1,:), 'LineWidth', 2); 
        plot(axTraj, ma_range, res_a(2,:), 'LineWidth', 2); 
        plot(axTraj, ma_range, res_a(3,:), 'LineWidth', 2);
        
        % Enhanced Trajectory: Mark current point
        xline(axTraj, currentMa, '--k', 'LineWidth', 1.5);
        yline(axTraj, initialGuess, ':k', 'Alpha');
        
        legend(axTraj, '\alpha_1','\alpha_2','\alpha_3');
        ylim(axTraj, [0 95]); xlim(axTraj, [0 1.2]); hold(axTraj, 'off');
        xlabel(axTraj, 'Modulation Index (Ma)'); ylabel(axTraj, 'Angles (Deg)');
    end

    function saveImages(~, ~)
        try
            folder = uigetdir(pwd, 'Select Folder to Save Images');
            if folder == 0, return; end
            
            % 1. Save Text Report
            fid = fopen(fullfile(folder, 'Simulation_Results_Report.txt'), 'w');
            if iscell(txtResults.Value)
                fprintf(fid, '%s\n', txtResults.Value{:});
            else
                fprintf(fid, '%s', txtResults.Value);
            end
            fclose(fid);
            
            % 2. Save Plots
            % Tab 1: Voltages
            exportgraphics(axVao, fullfile(folder, '1_Pole_Voltage_Vao.png'), 'Resolution', 300);
            exportgraphics(axVan, fullfile(folder, '2_Phase_Voltage_Van.png'), 'Resolution', 300);
            exportgraphics(axVab, fullfile(folder, '3_Line_Voltage_Vab.png'), 'Resolution', 300);
            
            % Tab 2: FFTs
            exportgraphics(axFFT_Vao, fullfile(folder, '4_FFT_Pole_Voltage.png'), 'Resolution', 300);
            exportgraphics(axFFT_Van, fullfile(folder, '5_FFT_Phase_Voltage.png'), 'Resolution', 300); % New
            exportgraphics(axFFT_Vab, fullfile(folder, '6_FFT_Line_Voltage.png'), 'Resolution', 300);
            
            % Tab 3: Currents
            exportgraphics(axIa, fullfile(folder, '7_Current_Waveforms_Time.png'), 'Resolution', 300);
            exportgraphics(axFFT_Ia, fullfile(folder, '8_FFT_Current_PhaseA.png'), 'Resolution', 300);
            exportgraphics(axFFT_Ib, fullfile(folder, '9_FFT_Current_PhaseB.png'), 'Resolution', 300);
            exportgraphics(axFFT_Ic, fullfile(folder, '10_FFT_Current_PhaseC.png'), 'Resolution', 300);
            
            % Tab 4: Power
            exportgraphics(axPower, fullfile(folder, '11_Power_Flow.png'), 'Resolution', 300);
            
            % Tab 5: Gates
            exportgraphics(axG1, fullfile(folder, '12_Gate_T1.png'), 'Resolution', 300);
            exportgraphics(axG2, fullfile(folder, '13_Gate_T2.png'), 'Resolution', 300);
            exportgraphics(axG3, fullfile(folder, '14_Gate_T3.png'), 'Resolution', 300);
            exportgraphics(axG4, fullfile(folder, '15_Gate_T4.png'), 'Resolution', 300);
            
            % Tab 6: Trajectory
            exportgraphics(axTraj, fullfile(folder, '16_Trajectory_Plot.png'), 'Resolution', 300);
            
            uialert(fig, 'All Plots and Report Saved Successfully!', 'Export Done');
        catch ME
            uialert(fig, ME.message, 'Export Error');
        end
    end

    function exportData(~, ~)
        assignin('base', 'sim_time', sim_t); 
        assignin('base', 'sim_V_pole', sim_Vao);
        assignin('base', 'sim_V_phase', sim_Van); 
        assignin('base', 'sim_V_line', sim_Vab);
        assignin('base', 'sim_Currents_3Ph', sim_Ia); 
        assignin('base', 'sim_Gate_Signals', sim_Gates);
        assignin('base', 'sim_Inst_Power', sim_Power);
        uialert(fig, 'Variables exported to MATLAB Workspace.', 'Export Complete');
    end

    function F = she_equations(alpha, Vdc, Vref)
        a = alpha;
        F = [(2*Vdc/pi)*(cos(a(1)) - cos(a(2)) + cos(a(3))) - Vref;
             cos(5*a(1)) - cos(5*a(2)) + cos(5*a(3));
             cos(7*a(1)) - cos(7*a(2)) + cos(7*a(3))];
    end

    function v = generate_pwm(t, alpha, Vdc, ph, Freq)
        v = zeros(size(t)); 
        w_t = mod(2*pi*Freq*t + ph, 2*pi);
        a = alpha;
        
        mask_pos = (w_t < pi); 
        theta = w_t;
        
        v(mask_pos & (theta < pi/2) & ((theta >= a(1) & theta < a(2)) | theta >= a(3))) = Vdc/2;
        tm = pi - theta;
        v(mask_pos & (theta >= pi/2) & ((tm >= a(1) & tm < a(2)) | tm >= a(3))) = Vdc/2;
        
        mask_neg = ~mask_pos; 
        tn = w_t - pi;
        v(mask_neg & (tn < pi/2) & ((tn >= a(1) & tn < a(2)) | tn >= a(3))) = -Vdc/2;
        tnm = pi - tn;
        v(mask_neg & (tn >= pi/2) & ((tnm >= a(1) & tnm < a(2)) | tnm >= a(3))) = -Vdc/2;
    end

    function [freqs, mag] = get_fft(signal, Ts, F_fund)
        L = length(signal); Y = fft(signal); P2 = abs(Y/L);
        P1 = P2(1:floor(L/2)+1); P1(2:end-1) = 2*P1(2:end-1);
        harm_orders = 1:25; mag = zeros(size(harm_orders)); freqs = harm_orders * F_fund;
        freq_axis = (0:(L/2))/L * (1/Ts);
        for k = 1:length(harm_orders)
            [~, idx] = min(abs(freq_axis - freqs(k))); mag(k) = P1(idx);
        end
    end
end
