# Draft measures (US Quality Core 0.5.0)

A self-contained CQL project for draft measures written against the CMS0135/CMS0144 v1.0.002 stack. It is
separate from the repo's `input/cql`, which is still on US Quality Core 0.1.0-cibuild.

Open **this `drafts/` folder** as its own VS Code workspace so the CQL language server uses `ig.ini` and
`input/hf-draft-ig.xml` here.

## Dependencies

| Library / model | Version | Source |
| --- | --- | --- |
| USQualityCore ModelInfo, USQualityCoreCommon | 0.5.0 | `fhir.onc.us-quality-core#0.5.0` package (plus a local copy of the ModelInfo XML) |
| USCore ModelInfo, USCoreCommon, USCoreElements | 6.1.0-derived, 2.0.0 | `hl7.fhir.us.cql#2.0.0` package |
| FHIRHelpers, FHIRCommon | 4.0.1, 2.0.0 | `hl7.fhir.uv.cql#2.0.0` package |
| CQMCommon | 5.2.000 | CMS QMD IG (cqframework/cms-qmd) convenience copy |
| CQMConcepts | 0.5.000 | CMS QMD IG convenience copy; the templates use 0.4.000, which isn't available here |
| SupplementalDataElements | 6.1.000 | Local port of `input/cql/SupplementalDataElements.cql` to 0.5.0; replace with the MADiE version |

The packages must be in the FHIR package cache (`~/.fhir/packages`). Download them from
`https://packages.fhir.org/fhir.onc.us-quality-core/0.5.0` and `https://packages.fhir.org/hl7.fhir.us.cql/2.0.0`
if they're missing. After changing packages or `ig.ini`, reload the VS Code window.

## Value sets

`input/vocabulary/valueset/` holds copies of the repo's VSAC expansions the draft uses, plus six **draft** GDMT
value sets (`2.16.840.1.113762.1.4.1248.469`-`.475`, version `20261123`) built from the codes on the tabs of
*HF Value Set Directory_USQC_Draft for Smile.xlsx*. They aren't VSAC expansions; replace them when VSAC publishes.

The language server reads value sets from the **workspace folder's** `input/vocabulary/valueset`, so these are
only used when `drafts/` is opened as its own workspace.

## Contents

- `input/cql/HFPharmacologicOptimizationFHIR.cql`: Heart Failure: Pharmacologic Optimization (Hospitalist), draft.
  Open Decision Log items are marked `TODO D-xx`.
