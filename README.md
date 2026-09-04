# GNSS-CycleSlip — Cycle Slip Detection in GNSS Carrier Phase Observations

MATLAB implementation of cycle slip detection for dual-frequency GPS carrier
phase data, based on the **geometry-free (GF) linear combination** of L1 and L2
observations read directly from RINEX v2.10 files.

**Author:** Motahareh Esfandyari-Kaloukan

## Method

1. Read the RINEX observation file and extract the L1/L2 carrier phases of all
   visible satellites (`rnxheader.m`, `rnxobs.m`).
2. Convert phases from cycles to meters using the L1/L2 wavelengths.
3. Form the zero-mean geometry-free combination per satellite:
   GF = L1 − L2. This combination cancels the geometry, clocks, and
   troposphere, leaving the ionospheric delay and any cycle slips.
4. Difference GF between consecutive epochs. A jump larger than **0.05 m**
   flags a cycle slip; satellite rise and set events are flagged separately.
5. Plot the per-satellite status series and the differenced GF series against
   the ±0.05 m thresholds for all 32 PRNs.

Status codes: `1` cycle slip, `0` clean, `9` satellite rise, `-9` satellite
set, `NaN` satellite not visible.

The detected slips feed directly into **carrier-phase smoothing**
(`HatchSmoothing.m`): the C1 pseudorange is smoothed with the L1 phase using
the window-limited Hatch filter

```
Psm(k) = C1(k)/k + ((k-1)/k) * ( Psm(k-1) + L1(k) - L1(k-1) )
```

where the window k grows up to M = 100 epochs and resets at every satellite
rise, data gap, or detected cycle slip. The scripts compare the raw and
smoothed code-minus-carrier noise per satellite.

## Files

| File | Description |
|---|---|
| `CycleSlipDetection.m` | Main script: GF combination, epoch differencing, detection, plots |
| `HatchSmoothing.m` | Window-limited Hatch filter: code smoothing with carrier phase, reset on detected slips |
| `rnxheader.m` | RINEX v2.10 header reader (original: LaQ, MGP – TU Delft, 2002) |
| `rnxobs.m` | RINEX v2.10 epoch reader (original: LaQ, MGP – TU Delft, 2002) |
| `ade20030.10o` | Sample RINEX file — Adelaide (ADE2), day 003 of 2010, 30 s |
| `bill3150.17o` | Sample RINEX file — day 315 of 2017, 30 s |

## Usage

```matlab
% Run on the included Adelaide dataset
CycleSlipDetection
```

To use another station, change the filename in the `fopen` call and adjust the
`time` vector if the observation interval differs from 30 s.

## Notes and limitations

- The RINEX readers support version 2.10 GPS observation files only.
- The 0.05 m threshold on the differenced GF combination is empirical; under
  high ionospheric activity it may flag ionospheric variation as slips.
- The Hatch window is limited to 100 epochs (50 min at 30 s sampling) to keep
  code–carrier ionospheric divergence small; adjust `M` in `HatchSmoothing.m`
  for other intervals.

## Credits

`rnxheader.m` and `rnxobs.m` were originally implemented by LaQ, MGP – TU
Delft (2002); their full documentation and credit are preserved in the file
headers. All remaining code by **Motahareh Esfandyari-Kaloukan**.
