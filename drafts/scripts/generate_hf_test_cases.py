"""Generate pass/fail test cases for each population of HFPharmacologicOptimizationFHIR.

Usage: python3 drafts/scripts/generate_hf_test_cases.py [<drafts-dir>]   (default: drafts/)
Ids are uuid5 values derived from each case slug, so re-running overwrites the same folders.
Writes <drafts-dir>/input/tests/measure/HFPharmacologicOptimizationFHIR/<patient-id>/ and
<drafts-dir>/input/tests/config.json.
"""
import json
import os
import sys
import uuid

LIB = "HFPharmacologicOptimizationFHIR"
USQC = "http://fhir.org/guides/onc/us-quality-core/StructureDefinition/us-quality-core-"
SCT = "http://snomed.info/sct"
RX = "http://www.nlm.nih.gov/research/umls/rxnorm"
NS = uuid.UUID("6f0b1d2e-4a3c-4f5e-9b8a-000000000000")

ADMIT = "2028-03-01T08:00:00Z"
DISCHARGE = "2028-03-05T12:00:00Z"
ORDER_TIME = "2028-03-05T10:00:00Z"

MEDS = {
    "raas": ("1656340", "sacubitril 24 MG / valsartan 26 MG Oral Tablet"),
    "bb": ("854905", "bisoprolol fumarate 5 MG Oral Tablet"),
    "mra": ("104230", "spironolactone 1 MG/ML Oral Suspension"),
    "sglt2": ("1488569", "dapagliflozin 10 MG Oral Tablet"),
    "mra-tab": ("313096", "spironolactone 25 MG Oral Tablet"),
}


def uid(*parts):
    return str(uuid.uuid5(NS, "/".join(parts)))


def ref(rtype, rid):
    return {"reference": f"{rtype}/{rid}"}


def cc(system, code, display=None):
    c = {"system": system, "code": code}
    if display:
        c["display"] = display
    return {"coding": [c]}


class Case:
    def __init__(self, slug, title, description, expected, birth_date="1960-05-01"):
        self.slug = slug
        self.title = title
        self.description = description
        self.expected = expected  # dict population-code -> count
        self.pid = uid(slug, "patient")
        self.enc_id = uid(self.slug, "encounter")
        self.prac_id = uid(self.slug, "practitioner")
        self.resources = []
        self.add({
            "resourceType": "Patient", "id": self.pid,
            "meta": {"profile": [USQC + "patient"]},
            "identifier": [{"system": "http://example.org/hf-draft-test", "value": slug}],
            "name": [{"family": "HFPharma", "given": [title]}],
            "gender": "female", "birthDate": birth_date,
        })
        self.add({
            "resourceType": "Practitioner", "id": self.prac_id,
            "meta": {"profile": [USQC + "practitioner"]},
            "identifier": [{"system": "http://hl7.org/fhir/sid/us-npi", "value": "1234567893"}],
            "name": [{"family": "Hospitalist", "given": ["Test"]}],
        })
        self.add({
            "resourceType": "Encounter", "id": self.enc_id,
            "meta": {"profile": [USQC + "encounter"]},
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP",
                      "display": "inpatient encounter"},
            "type": [cc(SCT, "32485007", "Hospital admission (procedure)")],
            "subject": ref("Patient", self.pid),
            "period": {"start": ADMIT, "end": DISCHARGE},
        })

    def add(self, r):
        self.resources.append(r)
        return self

    def hf_diagnosis(self):
        return self.add({
            "resourceType": "Condition", "id": uid(self.slug, "hf-dx"),
            "meta": {"profile": [USQC + "condition-encounter-diagnosis"]},
            "clinicalStatus": cc("http://terminology.hl7.org/CodeSystem/condition-clinical", "active"),
            "verificationStatus": cc("http://terminology.hl7.org/CodeSystem/condition-ver-status", "confirmed"),
            "category": [cc("http://terminology.hl7.org/CodeSystem/condition-category", "encounter-diagnosis")],
            "code": cc(SCT, "10091002", "High output heart failure (disorder)"),
            "subject": ref("Patient", self.pid),
            "encounter": ref("Encounter", self.enc_id),
            "onsetDateTime": "2028-03-01T09:00:00Z",
        })

    def ejection_fraction(self, value, when="2028-03-02T10:00:00Z"):
        return self.add({
            "resourceType": "Observation", "id": uid(self.slug, "ef", when),
            "meta": {"profile": [USQC + "observation-clinical-result"]},
            "status": "final",
            "category": [cc("http://terminology.hl7.org/CodeSystem/observation-category", "imaging")],
            "code": cc("http://loinc.org", "10230-1", "Left ventricular Ejection fraction"),
            "subject": ref("Patient", self.pid),
            "effectiveDateTime": when,
            "valueQuantity": {"value": value, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"},
        })

    def lvsd_problem(self):
        return self.add({
            "resourceType": "Condition", "id": uid(self.slug, "lvsd"),
            "meta": {"profile": [USQC + "condition-problems-health-concerns"]},
            "clinicalStatus": cc("http://terminology.hl7.org/CodeSystem/condition-clinical", "active"),
            "verificationStatus": cc("http://terminology.hl7.org/CodeSystem/condition-ver-status", "confirmed"),
            "category": [cc("http://terminology.hl7.org/CodeSystem/condition-category", "problem-list-item")],
            "code": cc(SCT, "981000124106", "Moderate left ventricular systolic dysfunction (disorder)"),
            "subject": ref("Patient", self.pid),
            "onsetDateTime": "2027-09-15T09:00:00Z",
            "recordedDate": "2027-09-15T09:00:00Z",
        })

    def lvad_placement(self, when):
        return self.add({
            "resourceType": "Procedure", "id": uid(self.slug, "lvad"),
            "meta": {"profile": [USQC + "procedure"]},
            "status": "completed",
            "code": cc(SCT, "232967006", "Implantation of left cardiac ventricular assist device (procedure)"),
            "subject": ref("Patient", self.pid),
            "performedPeriod": {"start": when, "end": when},
        })

    def discharge_meds(self, *classes):
        for k in classes:
            code, display = MEDS[k]
            self.add({
                "resourceType": "MedicationRequest", "id": uid(self.slug, "med", k),
                "meta": {"profile": [USQC + "medicationrequest"]},
                "status": "active", "intent": "order",
                "category": [cc("http://terminology.hl7.org/CodeSystem/medicationrequest-category", "discharge")],
                "medicationCodeableConcept": cc(RX, code, display),
                "subject": ref("Patient", self.pid),
                "encounter": ref("Encounter", self.enc_id),
                "authoredOn": ORDER_TIME,
                "requester": ref("Practitioner", self.prac_id),
            })
        return self

    def home_med(self, k, start, days):
        """Active community (home) order, 1 tablet daily, `days` supply from `start`, no refills."""
        code, display = MEDS[k]
        return self.add({
            "resourceType": "MedicationRequest", "id": uid(self.slug, "home-med", k),
            "meta": {"profile": [USQC + "medicationrequest"]},
            "status": "active", "intent": "order",
            "category": [cc("http://terminology.hl7.org/CodeSystem/medicationrequest-category", "community")],
            "medicationCodeableConcept": cc(RX, code, display),
            "subject": ref("Patient", self.pid),
            "authoredOn": start,
            "requester": ref("Practitioner", self.prac_id),
            "dosageInstruction": [{
                "timing": {"repeat": {"frequency": 1, "period": 1, "periodUnit": "d"}},
                "doseAndRate": [{"doseQuantity": {"value": 1, "unit": "tablet",
                                                  "system": "http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm",
                                                  "code": "TAB"}}],
            }],
            "dispenseRequest": {
                "numberOfRepeatsAllowed": 0,
                "quantity": {"value": days, "unit": "tablet",
                             "system": "http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm", "code": "TAB"},
                "expectedSupplyDuration": {"value": days, "unit": "days", "system": "http://unitsofmeasure.org",
                                           "code": "d"},
            },
        })

    def not_requested(self, k, reason=("183932001", "Procedure contraindicated (situation)")):
        code, display = MEDS[k]
        return self.add({
            "resourceType": "MedicationRequest", "id": uid(self.slug, "not-requested", k),
            "meta": {"profile": [USQC + "medicationnotrequested"]},
            "status": "completed", "intent": "order", "doNotPerform": True,
            "category": [cc("http://terminology.hl7.org/CodeSystem/medicationrequest-category", "discharge")],
            "medicationCodeableConcept": cc(RX, code, display),
            "subject": ref("Patient", self.pid),
            "encounter": ref("Encounter", self.enc_id),
            "authoredOn": ORDER_TIME,
            "requester": ref("Practitioner", self.prac_id),
            "reasonCode": [cc(SCT, *reason)],
        })

    def measure_report(self):
        pops = [
            ("initial-population", "Initial Population", "InitialPopulation_1"),
            ("denominator", "Denominator", "Denominator_1"),
            ("denominator-exclusion", "Denominator Exclusion", "DenominatorExclusion_1"),
            ("numerator", "Numerator", "Numerator_1"),
            ("denominator-exception", "Denominator Exception", "DenominatorException_1"),
        ]
        e = self.expected
        denom = e["denominator"] - e["denominator-exclusion"] - e["denominator-exception"]
        score = (e["numerator"] / denom) if denom > 0 else 0.0
        params_id = f"{self.pid}-parameters"
        mr_id = uid(self.slug, "measurereport")
        return {
            "resourceType": "MeasureReport", "id": mr_id,
            "meta": {"profile": ["http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/test-case-cqfm"]},
            "contained": [{"resourceType": "Parameters", "id": params_id,
                           "parameter": [{"name": "subject", "valueString": self.pid}]}],
            "extension": [
                {"url": "http://hl7.org/fhir/StructureDefinition/cqf-inputParameters",
                 "valueReference": {"reference": f"#{params_id}"}},
                {"url": "http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-testCaseDescription",
                 "valueMarkdown": f"{self.title}: {self.description}"},
            ],
            "modifierExtension": [{"url": "http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-isTestCase",
                                   "valueBoolean": True}],
            "status": "complete", "type": "individual",
            "measure": f"https://madie.cms.gov/Measure/{LIB}",
            "period": {"start": "2028-01-01", "end": "2028-12-31"},
            "group": [{
                "id": "Group_1",
                "population": [{
                    "id": pid,
                    "code": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/measure-population",
                                         "code": code, "display": disp}]},
                    "count": e[code],
                } for code, disp, pid in pops],
                "measureScore": {"value": score},
            }],
            "evaluatedResource": [ref(r["resourceType"], r["id"]) for r in self.resources],
        }

    def write(self, root):
        d = os.path.join(root, self.pid)
        os.makedirs(d, exist_ok=True)
        for r in self.resources + [self.measure_report()]:
            with open(os.path.join(d, f"{r['resourceType']}-{r['id']}.json"), "w") as f:
                json.dump(r, f, indent=2)
                f.write("\n")
        return d


def exp(ip=0, denom=0, denex=0, numer=0, denexcep=0):
    return {"initial-population": ip, "denominator": denom, "denominator-exclusion": denex,
            "numerator": numer, "denominator-exception": denexcep}


IN_DENOM = exp(1, 1)

CASES = [
    Case("ip-pass", "IPPass", "Age 67, inpatient discharge in MP, HF encounter diagnosis, LVEF 30%. "
         "No GDMT at discharge.", IN_DENOM).hf_diagnosis().ejection_fraction(30),
    Case("ip-fail", "IPFail", "Same as IPPass but the only LVEF is 50% and no coded LVSD: "
         "no current reduced ejection fraction.", exp()).hf_diagnosis().ejection_fraction(50),
    Case("denom-pass", "DenomPass", "No LVEF result; qualifies through a confirmed moderate LVSD problem "
         "recorded before admission (D-04 alternate path).", IN_DENOM).hf_diagnosis().lvsd_problem(),
    Case("denom-fail", "DenomFail", "Patient is 17 on the discharge date (D-02); otherwise qualifies.",
         exp(), birth_date="2010-06-01").hf_diagnosis().ejection_fraction(30),
    Case("denex-pass", "DenexPass", "In denominator; completed LVAD placement in 2027, before discharge.",
         exp(1, 1, denex=1)).hf_diagnosis().ejection_fraction(30).lvad_placement("2027-06-01T10:00:00Z"),
    Case("denex-fail", "DenexFail", "In denominator; LVAD placement on 2028-06-01, after discharge "
         "from the episode (D-08), so no exclusion.",
         IN_DENOM).hf_diagnosis().ejection_fraction(30).lvad_placement("2028-06-01T10:00:00Z"),
    Case("numer-pass", "NumerPass", "In denominator; ARNI, beta blocker, MRA and SGLT2i all ordered at discharge.",
         exp(1, 1, numer=1)).hf_diagnosis().ejection_fraction(30).discharge_meds("raas", "bb", "mra", "sglt2"),
    Case("numer-fail", "NumerFail", "In denominator; ARNI, beta blocker and MRA at discharge, SGLT2i missing "
         "with no reason documented.", IN_DENOM).hf_diagnosis().ejection_fraction(30)
         .discharge_meds("raas", "bb", "mra"),
    Case("denexcep-pass", "DenexcepPass", "In denominator; ARNI, beta blocker and SGLT2i at discharge; MRA not "
         "ordered with a medical reason (procedure contraindicated).", exp(1, 1, denexcep=1)).hf_diagnosis()
         .ejection_fraction(30).discharge_meds("raas", "bb", "sglt2").not_requested("mra"),
    Case("denexcep-fail", "DenexcepFail", "In denominator; ARNI and beta blocker at discharge; MRA not ordered "
         "with a medical reason, but SGLT2i also missing with no reason (D-07: every missing category needs "
         "its own reason).", IN_DENOM).hf_diagnosis().ejection_fraction(30)
         .discharge_meds("raas", "bb").not_requested("mra"),
    Case("continued-pass", "ContinuedPass", "In denominator; ARNI, beta blocker and SGLT2i ordered at discharge; "
         "MRA continued from an active home order with a 30-day supply from 2028-02-20, which covers the "
         "2028-03-05 discharge.", exp(1, 1, numer=1)).hf_diagnosis().ejection_fraction(30)
         .discharge_meds("raas", "bb", "sglt2").home_med("mra-tab", "2028-02-20T09:00:00Z", 30),
    Case("continued-fail", "ContinuedFail", "Same as ContinuedPass but the active home MRA order's 30-day supply "
         "started 2027-12-01 and ran out 2027-12-30, before admission: not continued at discharge.",
         IN_DENOM).hf_diagnosis().ejection_fraction(30)
         .discharge_meds("raas", "bb", "sglt2").home_med("mra-tab", "2027-12-01T09:00:00Z", 30),
]


def main():
    drafts = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    root = os.path.join(drafts, "input", "tests", "measure", LIB)
    for c in CASES:
        print(c.slug, c.write(root))
    cfg = {
        "testCasesToExclude": [],
        "resultFormat": "individual",
        "flatResultsInSubfolder": False,
        "parameters": [{"name": "Measurement Period", "type": "Interval<DateTime>",
                        "value": "Interval[@2028-01-01T00:00:00.000Z, @2029-01-01T00:00:00.000Z)"}],
    }
    with open(os.path.join(drafts, "input", "tests", "config.json"), "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
