// 1. Select database
use("HospitalClinicalNotesDB");

// 2. Create collection with JSON Schema validation
db.createCollection("clinicalNotes", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: [
                "noteId",
                "patientId",
                "visitId",
                "diagnosis",
                "createdAt"
            ],
            properties: {
                noteId: {
                    bsonType: "string"
                },
                patientId: {
                    bsonType: "int"
                },
                visitId: {
                    bsonType: "int"
                },
                diagnosis: {
                    bsonType: "string"
                },
                createdAt: {
                    bsonType: "date"
                },

                // Shape 1: General clinical notes
                symptoms: {
                    bsonType: "array",
                    items: {
                        bsonType: "string"
                    }
                },
                clinicalFindings: {
                    bsonType: "string"
                },
                treatmentPlan: {
                    bsonType: "string"
                },

                // Shape 2: Detailed clinical notes
                vitalSigns: {
                    bsonType: "object",
                    properties: {
                        temperature: {
                            bsonType: ["double", "int"]
                        },
                        bloodPressure: {
                            bsonType: "string"
                        },
                        heartRate: {
                            bsonType: "int"
                        },
                        oxygenLevel: {
                            bsonType: "int"
                        }
                    }
                },
                labResults: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        properties: {
                            testName: {
                                bsonType: "string"
                            },
                            result: {
                                bsonType: "string"
                            }
                        }
                    }
                },
                followUp: {
                    bsonType: "string"
                }
            }
        }
    },
    validationLevel: "strict",
    validationAction: "error"
});

// 3. Insert clinical notes with two different document shapes
db.clinicalNotes.insertMany([
    // Shape 1: General clinical note
    {
        noteId: "N001",
        patientId: 1,
        visitId: 1,
        diagnosis: "Hypertension",
        createdAt: ISODate("2026-11-01T09:00:00Z"),
        symptoms: [
            "Headache",
            "Dizziness"
        ],
        clinicalFindings: "Blood pressure found to be elevated",
        treatmentPlan: "Prescribed Amlodipine 5mg"
    },
    {
        noteId: "N002",
        patientId: 2,
        visitId: 2,
        diagnosis: "Chest Pain",
        createdAt: ISODate("2026-11-03T10:30:00Z"),
        symptoms: [
            "Chest discomfort",
            "Shortness of breath"
        ],
        clinicalFindings: "Patient requires cardiac evaluation",
        treatmentPlan: "ECG recommended"
    },
    {
        noteId: "N003",
        patientId: 3,
        visitId: 3,
        diagnosis: "Migraine",
        createdAt: ISODate("2026-11-05T11:00:00Z"),
        symptoms: [
            "Severe headache",
            "Sensitivity to light"
        ],
        clinicalFindings: "Recurring migraine symptoms reported",
        treatmentPlan: "Pain relief medication and rest"
    },

    // Shape 2: Detailed clinical note with vital signs and lab results
    {
        noteId: "N004",
        patientId: 4,
        visitId: 4,
        diagnosis: "Headache",
        createdAt: ISODate("2026-10-10T08:45:00Z"),
        vitalSigns: {
            temperature: 37.2,
            bloodPressure: "120/80",
            heartRate: 78,
            oxygenLevel: 98
        },
        labResults: [
            {
                testName: "Blood Sugar",
                result: "Normal"
            },
            {
                testName: "Hemoglobin",
                result: "13.5 g/dL"
            }
        ],
        followUp: "Review after one week"
    },
    {
        noteId: "N005",
        patientId: 5,
        visitId: 5,
        diagnosis: "Knee Pain",
        createdAt: ISODate("2026-10-12T09:30:00Z"),
        vitalSigns: {
            temperature: 36.8,
            bloodPressure: "118/78",
            heartRate: 82,
            oxygenLevel: 99
        },
        labResults: [
            {
                testName: "X-Ray",
                result: "Mild joint inflammation"
            }
        ],
        followUp: "Physiotherapy review after two weeks"
    },
    {
        noteId: "N006",
        patientId: 6,
        visitId: 6,
        diagnosis: "Joint Pain",
        createdAt: ISODate("2026-09-15T12:00:00Z"),
        vitalSigns: {
            temperature: 37.0,
            bloodPressure: "122/82",
            heartRate: 80,
            oxygenLevel: 97
        },
        labResults: [
            {
                testName: "Vitamin D",
                result: "Below normal range"
            }
        ],
        followUp: "Continue supplements and review after one month"
    }
]);

// 4. Display all clinical notes
db.clinicalNotes.find();

// 5. Query clinical notes by diagnosis
db.clinicalNotes.find({
    diagnosis: "Hypertension"
});

// 6. Query all notes containing a diagnosis with 'Pain'
db.clinicalNotes.find({
    diagnosis: {
        $regex: "Pain",
        $options: "i"
    }
});

// 7. Verify document count
print("Total clinical notes:");
print(db.clinicalNotes.countDocuments());

// 8. Display collection information
db.getCollectionInfos({
    name: "clinicalNotes"
});