#pragma once

#define FOLDER_RECORD ""

// Signal Processing
#define SIGNAL_BW_KHZ 400  // 400, 200, 40, 12, 0(no)
#define SMOOTH_FACTOR 12   // 12, 0
#define CORR_TYPE 'dphase' //  'abs' or 'dphase'
#define INTERPOL_FACTOR 0  //

// Additional processing of ref signal
// (set to > 0 only when other signals than the ref signal falls into the full RX bandwidth)
#define REF_BW_KHZ 40        // 400, 200, 40, 12, 0(no)
#define SMOOTH_FACTOR_REF 12 //

// 0: no plots
// 1: show correlation plots
// 2: show also input spcetrograms and spectra of input meas
// 3: show also before and after filtering
#define REPORT_LVL = 0;

// Map output
// 'open_street_map' (default) or 'google_maps'
#define MAP_MODE 'open_street_map'

// Heatmap (only with google maps)
#define HEATMAP_RESOLUTION 400 // resolution for heatmap points
#define HEATMAP_THRESHOLD 0.1  // heatmap point with lower mag are suppressed for html output
