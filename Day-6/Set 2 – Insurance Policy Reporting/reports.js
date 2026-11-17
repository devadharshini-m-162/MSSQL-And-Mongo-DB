use("InsuranceClaimsMongoDB");

// 1. Claims per status.
db.claimsNotes.aggregate([
    { $match: { status: { $exists: true } } },
    { $group: { _id: "$status", claimCount: { $sum: 1 } } },
    { $sort: { claimCount: -1, _id: 1 } }
]);

// 2. Average settlement time in days.
db.claimsNotes.aggregate([
    { $match: { settledAt: { $type: "date" }, filedAt: { $type: "date" } } },
    {
        $group: {
            _id: null,
            averageSettlementDays: {
                $avg: { $dateDiff: { startDate: "$filedAt", endDate: "$settledAt", unit: "day" } }
            }
        }
    },
    { $project: { _id: 0, averageSettlementDays: 1 } }
]);

// 3. Top three damage categories.
db.claimsNotes.aggregate([
    { $match: { damageCategory: { $type: "string" } } },
    { $group: { _id: "$damageCategory", claimCount: { $sum: 1 } } },
    { $sort: { claimCount: -1, _id: 1 } },
    { $limit: 3 }
]);
