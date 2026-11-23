/*
@description: DRAFT. Heart Failure: Pharmacologic Optimization (Hospitalist).
Percentage of qualifying inpatient hospitalization episodes among patients aged 18 years and older
with heart failure and a current left ventricular ejection fraction (LVEF) <= 40% in which all four
indicated categories of guideline-directed medical therapy (GDMT) are prescribed or continued at
discharge.
@comment: Episode-based (population basis Encounter): every population criterion returns the
qualifying inpatient Encounters. Structure, header and conventions follow CMS0135 and CMS0144
v1.0.002. Open items from the HF Implementation Guide and Decision Log are marked `TODO D-xx`;
where the log has a recommendation, the draft follows it.
*/
library HFPharmacologicOptimizationFHIR version '0.0.001'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include hl7.fhir.us.cql.USCoreCommon version '2.0.0' called USCoreCommon
include hl7.fhir.us.cql.USCoreElements version '2.0.0' called USCoreElements

include CQMCommon version '5.2.000' called CQMCommon
include CQMConcepts version '0.5.000' called CQMConcepts
include fhir.onc."us-quality-core".USQualityCoreCommon version '0.5.0' called USQualityCoreCommon
include SupplementalDataElements version '6.1.000' called SDE

codesystem "SNOMEDCT": 'http://snomed.info/sct'

// Denominator
valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'
valueset "Heart Failure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.376'
valueset "Moderate or Severe LVSD": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1090'
valueset "Moderate or Severe": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1092'
valueset "Ejection Fraction": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1134'

// Denominator Exclusions
valueset "Heart Transplant": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1178.33'
valueset "Heart Transplant Complications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1178.56'
valueset "Left Ventricular Assist Device Placement": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1178.61'
valueset "Left Ventricular Assist Device Complications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1178.58'

// Denominator Exceptions
valueset "Medical Reason": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1007'
valueset "Patient Reason": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1008'

// Numerator (GDMT)
valueset "Angiotensin Converting Enzyme Inhibitor": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.469'
valueset "Angiotensin II Receptor Blocker": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.470'
valueset "Angiotensin Receptor Neprilysin Inhibitor": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.472'
valueset "Beta Blocker": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.473'
valueset "Mineralocorticoid Receptor Antagonist": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.474'
valueset "Sodium Glucose Cotransporter 2 Inhibitor for Heart Failure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.475'

code "Left ventricular systolic dysfunction (disorder)": '134401001' from "SNOMEDCT" display 'Left ventricular systolic dysfunction (disorder)'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2028-01-01T00:00:00.000Z, @2029-01-01T00:00:00.000Z)

context Patient

/*
 * Population criteria
 */

define "Initial Population":
  "Heart Failure Inpatient Encounter with Current Reduced Ejection Fraction"

define "Denominator":
  "Initial Population"

define "Denominator Exclusions":
  "Denominator" QualifyingEncounter
    where QualifyingEncounter.hasHeartTransplantBeforeDischarge ( )
      or QualifyingEncounter.hasHeartTransplantComplicationsBeforeDischarge ( )
      or QualifyingEncounter.hasLeftVentricularAssistDeviceBeforeDischarge ( )
      or QualifyingEncounter.hasLeftVentricularAssistDeviceComplicationsBeforeDischarge ( )

define "Numerator":
  "Denominator" QualifyingEncounter
    where QualifyingEncounter.hasAllFourGDMTCategoriesAtDischarge ( )

// TODO D-07 (recommended): an exception applies only when the numerator is not met AND every
// missing GDMT category has its own medical or patient reason. A reason recorded against one
// category does not cover another, and a reason not tied to a category (no medication class)
// does not count.
// TODO D-10: exceptions are limited to "Medical Reason" and "Patient Reason" for now; the
// condition-based exceptions from CMS0135/CMS0144 (allergy, pregnancy, bradycardia, ...) and
// MRA/SGLT2i contraindications are not included.
define "Denominator Exceptions":
  "Denominator" QualifyingEncounter
    where not QualifyingEncounter.hasAllFourGDMTCategoriesAtDischarge ( )
      and QualifyingEncounter.isRAASInhibitorAddressedAtDischarge ( )
      and QualifyingEncounter.isBetaBlockerAddressedAtDischarge ( )
      and QualifyingEncounter.isMRAAddressedAtDischarge ( )
      and QualifyingEncounter.isSGLT2InhibitorAddressedAtDischarge ( )

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

/*
 * Denominator
 */

// TODO D-02 (recommended): age is 18 or older on the discharge date. The narrative spec says
// "at the start of the measurement period"; use start of "Measurement Period" if AIR keeps that.
define "Inpatient Encounter with Discharge During Measurement Period":
  [USQualityCore.Encounter: "Encounter Inpatient"] InpatientEncounter
    where InpatientEncounter.status = 'finished'
      and InpatientEncounter.period ends during day of "Measurement Period"
      and AgeInYearsAt(date from end of InpatientEncounter.period) >= 18

define "Heart Failure Inpatient Encounter with Current Reduced Ejection Fraction":
  "Inpatient Encounter with Discharge During Measurement Period" InpatientEncounter
    where InpatientEncounter.hasHeartFailureDiagnosis ( )
      and ( InpatientEncounter.hasCurrentEjectionFractionAtOrBelow40Percent ( )
          or InpatientEncounter.hasModerateOrSevereLVSD ( )
      )

/*
@description: Returns true if heart failure is associated with the given hospitalization
@comment: TODO D-05: "hospitalization for HF" is undecided (principal only / principal or secondary /
any encounter diagnosis / condition active during the stay / present on admission). The draft
accepts any of: an encounter diagnosis linked to the encounter, a reason for visit, or a verified
problem-list item whose prevalence period overlaps the hospitalization.
*/
define fluent function hasHeartFailureDiagnosis(encounter USQualityCore.Encounter):
  encounter.reasonCode in "Heart Failure"
    or exists ( [USQualityCore.ConditionEncounterDiagnosis: "Heart Failure"] HeartFailureDiagnosis
        where HeartFailureDiagnosis.encounter.references(encounter)
          and HeartFailureDiagnosis.isVerified ( )
    )
    or exists ( [USQualityCore.ConditionProblemsHealthConcerns: "Heart Failure"] HeartFailureProblem
        where HeartFailureProblem.prevalencePeriod ( ) overlaps day of encounter.hospitalization ( )
          and HeartFailureProblem.isVerified ( )
    )

/*
@description: Returns the most recent final ejection fraction result on or before discharge from the given hospitalization
@comment: TODO D-03: no lookback limit is applied yet. CMS0135/CMS0144 accept any prior LVEF <= 40% with
no lookback; this draft uses the MOST RECENT result instead, so a later recovered LVEF disqualifies the
episode (per the "current LVEF" wording). Add `and ... starts X months or less before end of encounter.period`
once AIR decides the window.
*/
define fluent function mostRecentEjectionFraction(encounter USQualityCore.Encounter):
  Last(
    [USQualityCore.ObservationClinicalResult: "Ejection Fraction"] EjectionFraction
      where EjectionFraction.status in { 'final', 'amended', 'corrected' }
        and EjectionFraction.effective.toInterval ( ) starts on or before end of encounter.period
      sort by start of effective.toInterval ( )
  )

define fluent function hasCurrentEjectionFractionAtOrBelow40Percent(encounter USQualityCore.Encounter):
  ( encounter.mostRecentEjectionFraction ( ) ).value as Quantity <= 40 '%'

/*
@description: Returns true if moderate or severe left ventricular systolic dysfunction is documented on or before discharge
@comment: TODO D-04 (recommended): coded moderate/severe LVSD is accepted as an alternative to LVEF <= 40%,
as in CMS0135. Either a code from "Moderate or Severe LVSD", or the general LVSD code with a severity
from "Moderate or Severe". The lookback window is open; align it with D-03.
*/
define fluent function hasModerateOrSevereLVSD(encounter USQualityCore.Encounter):
  exists ( [USQualityCore.ConditionProblemsHealthConcerns] LVSDProblem
      where ( LVSDProblem.code in "Moderate or Severe LVSD"
          or ( LVSDProblem.code ~ "Left ventricular systolic dysfunction (disorder)"
              and LVSDProblem.severity in "Moderate or Severe"
          )
      )
        and LVSDProblem.isVerified ( )
        and Coalesce(start of LVSDProblem.prevalencePeriod ( ), LVSDProblem.recordedDate) on or before end of encounter.period
  )
    or exists ( [USQualityCore.ConditionEncounterDiagnosis] LVSDDiagnosis
        where ( LVSDDiagnosis.code in "Moderate or Severe LVSD"
            or ( LVSDDiagnosis.code ~ "Left ventricular systolic dysfunction (disorder)"
                and LVSDDiagnosis.severity in "Moderate or Severe"
            )
        )
          and LVSDDiagnosis.isVerified ( )
          and Coalesce(start of LVSDDiagnosis.prevalencePeriod ( ), LVSDDiagnosis.recordedDate) on or before end of encounter.period
    )

/*
 * Denominator Exclusions
 * TODO D-08 (recommended): history must be on or before discharge from the episode, so a later
 * transplant/LVAD in the measurement period does not exclude an earlier discharge.
 * TODO D-09 (recommended): transplant and LVAD complications are included as proxies for history.
 */

define fluent function hasHeartTransplantBeforeDischarge(encounter USQualityCore.Encounter):
  exists ( [USQualityCore.Procedure: "Heart Transplant"] HeartTransplant
      where HeartTransplant.status = 'completed'
        and HeartTransplant.performed.toInterval ( ) starts on or before end of encounter.period
  )

define fluent function hasLeftVentricularAssistDeviceBeforeDischarge(encounter USQualityCore.Encounter):
  exists ( [USQualityCore.Procedure: "Left Ventricular Assist Device Placement"] LVADPlacement
      where LVADPlacement.status = 'completed'
        and LVADPlacement.performed.toInterval ( ) starts on or before end of encounter.period
  )

define fluent function hasHeartTransplantComplicationsBeforeDischarge(encounter USQualityCore.Encounter):
  exists ( [USQualityCore.ConditionProblemsHealthConcerns: "Heart Transplant Complications"] TransplantComplication
      where TransplantComplication.isVerified ( )
        and Coalesce(start of TransplantComplication.prevalencePeriod ( ), TransplantComplication.recordedDate) on or before end of encounter.period
  )
    or exists ( [USQualityCore.ConditionEncounterDiagnosis: "Heart Transplant Complications"] TransplantComplicationDiagnosis
        where TransplantComplicationDiagnosis.isVerified ( )
          and Coalesce(start of TransplantComplicationDiagnosis.prevalencePeriod ( ), TransplantComplicationDiagnosis.recordedDate) on or before end of encounter.period
    )

define fluent function hasLeftVentricularAssistDeviceComplicationsBeforeDischarge(encounter USQualityCore.Encounter):
  exists ( [USQualityCore.ConditionProblemsHealthConcerns: "Left Ventricular Assist Device Complications"] LVADComplication
      where LVADComplication.isVerified ( )
        and Coalesce(start of LVADComplication.prevalencePeriod ( ), LVADComplication.recordedDate) on or before end of encounter.period
  )
    or exists ( [USQualityCore.ConditionEncounterDiagnosis: "Left Ventricular Assist Device Complications"] LVADComplicationDiagnosis
        where LVADComplicationDiagnosis.isVerified ( )
          and Coalesce(start of LVADComplicationDiagnosis.prevalencePeriod ( ), LVADComplicationDiagnosis.recordedDate) on or before end of encounter.period
    )

/*
 * Numerator: GDMT prescribed or continued at discharge
 */

// Known engine issue I-26 (defect-tracking/known-issues.md) applies to these retrieves: a
// terminology-filtered MedicationRequest retrieve throws when medication is a Reference(Medication).
define "RAAS Inhibitor Medication Request":
  [USQualityCore.MedicationRequest: medication in "Angiotensin Converting Enzyme Inhibitor"]
    union [USQualityCore.MedicationRequest: medication in "Angiotensin II Receptor Blocker"]
    union [USQualityCore.MedicationRequest: medication in "Angiotensin Receptor Neprilysin Inhibitor"]

define "Beta Blocker Medication Request":
  [USQualityCore.MedicationRequest: medication in "Beta Blocker"]

define "MRA Medication Request":
  [USQualityCore.MedicationRequest: medication in "Mineralocorticoid Receptor Antagonist"]

define "SGLT2 Inhibitor Medication Request":
  [USQualityCore.MedicationRequest: medication in "Sodium Glucose Cotransporter 2 Inhibitor for Heart Failure"]

/*
@description: Returns true if any of the given medication requests is prescribed or continued at discharge from the given hospitalization
@comment: TODO D-06 (recommended: "status active at discharge, or authored during the episode"). The draft counts:
- prescribed at discharge: an order with a discharge or community category, authored during the hospitalization; or
- continued: an active community (home) medication order authored on or before discharge.
Medication reconciliation representation and encounter linkage (Implementation Guide row 24) are still open.
*/
define fluent function isPrescribedOrContinuedAtDischarge(medications List<USQualityCore.MedicationRequest>, encounter USQualityCore.Encounter):
  exists ( medications Medication
      where Medication.intent in { 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order' }
        and (
          ( ( Medication.isDischarge ( ) or Medication.isCommunity ( ) )
              and Medication.status in { 'active', 'completed' }
              and Medication.authoredOn during day of encounter.hospitalization ( )
          )
            or ( Medication.isCommunity ( )
                and Medication.status = 'active'
                and Medication.authoredOn on or before day of end of encounter.period
            )
        )
  )

define fluent function hasRAASInhibitorAtDischarge(encounter USQualityCore.Encounter):
  "RAAS Inhibitor Medication Request".isPrescribedOrContinuedAtDischarge(encounter)

define fluent function hasBetaBlockerAtDischarge(encounter USQualityCore.Encounter):
  "Beta Blocker Medication Request".isPrescribedOrContinuedAtDischarge(encounter)

define fluent function hasMRAAtDischarge(encounter USQualityCore.Encounter):
  "MRA Medication Request".isPrescribedOrContinuedAtDischarge(encounter)

define fluent function hasSGLT2InhibitorAtDischarge(encounter USQualityCore.Encounter):
  "SGLT2 Inhibitor Medication Request".isPrescribedOrContinuedAtDischarge(encounter)

define fluent function hasAllFourGDMTCategoriesAtDischarge(encounter USQualityCore.Encounter):
  encounter.hasRAASInhibitorAtDischarge ( )
    and encounter.hasBetaBlockerAtDischarge ( )
    and encounter.hasMRAAtDischarge ( )
    and encounter.hasSGLT2InhibitorAtDischarge ( )

/*
 * Denominator Exceptions: a class-specific reason for each missing GDMT category
 */

define "RAAS Inhibitor Not Requested":
  [USQualityCore.MedicationNotRequested: medication in "Angiotensin Converting Enzyme Inhibitor"]
    union [USQualityCore.MedicationNotRequested: medication in "Angiotensin II Receptor Blocker"]
    union [USQualityCore.MedicationNotRequested: medication in "Angiotensin Receptor Neprilysin Inhibitor"]

define "Beta Blocker Not Requested":
  [USQualityCore.MedicationNotRequested: medication in "Beta Blocker"]

define "MRA Not Requested":
  [USQualityCore.MedicationNotRequested: medication in "Mineralocorticoid Receptor Antagonist"]

define "SGLT2 Inhibitor Not Requested":
  [USQualityCore.MedicationNotRequested: medication in "Sodium Glucose Cotransporter 2 Inhibitor for Heart Failure"]

/*
@description: Returns true if any of the given not-requested records documents a medical or patient reason during the given hospitalization
@comment: The medication class is carried by the retrieve (medication in the category's value set), which is
what ties the reason to the missing category.
*/
define fluent function hasMedicalOrPatientReasonDuring(notRequested List<USQualityCore.MedicationNotRequested>, encounter USQualityCore.Encounter):
  exists ( notRequested NotRequested
      where NotRequested.authoredOn during day of encounter.hospitalization ( )
        and ( NotRequested.reasonCode in "Medical Reason"
            or NotRequested.reasonCode in "Patient Reason"
        )
  )

// Each "addressed" check is: the category is present at discharge, or its own reason exists.
define fluent function isRAASInhibitorAddressedAtDischarge(encounter USQualityCore.Encounter):
  encounter.hasRAASInhibitorAtDischarge ( )
    or "RAAS Inhibitor Not Requested".hasMedicalOrPatientReasonDuring(encounter)

define fluent function isBetaBlockerAddressedAtDischarge(encounter USQualityCore.Encounter):
  encounter.hasBetaBlockerAtDischarge ( )
    or "Beta Blocker Not Requested".hasMedicalOrPatientReasonDuring(encounter)

define fluent function isMRAAddressedAtDischarge(encounter USQualityCore.Encounter):
  encounter.hasMRAAtDischarge ( )
    or "MRA Not Requested".hasMedicalOrPatientReasonDuring(encounter)

define fluent function isSGLT2InhibitorAddressedAtDischarge(encounter USQualityCore.Encounter):
  encounter.hasSGLT2InhibitorAtDischarge ( )
    or "SGLT2 Inhibitor Not Requested".hasMedicalOrPatientReasonDuring(encounter)
