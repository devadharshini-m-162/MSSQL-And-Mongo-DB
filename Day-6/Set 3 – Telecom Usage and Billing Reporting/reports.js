use("TelecomUsageMongoDB");

// 1. Hourly usage.
db.usageEvents.aggregate([
    { $match: { eventTime: { $type: "date" }, usageMB: { $type: "number" } } },
    {
        $group: {
            _id: {
                year: { $year: "$eventTime" },
                month: { $month: "$eventTime" },
                day: { $dayOfMonth: "$eventTime" },
                hour: { $hour: "$eventTime" }
            },
            totalUsageMB: { $sum: "$usageMB" }
        }
    },
    { $sort: { "_id.year": 1, "_id.month": 1, "_id.day": 1, "_id.hour": 1 } }
]);

// 2. Average session length.
db.usageEvents.aggregate([
    { $match: { sessionLengthMinutes: { $type: "number" } } },
    {
        $group: {
            _id: null,
            averageSessionLengthMinutes: { $avg: "$sessionLengthMinutes" }
        }
    },
    { $project: { _id: 0, averageSessionLengthMinutes: 1 } }
]);

// 3. Busiest cell tower.
db.usageEvents.aggregate([
    { $match: { cellTowerId: { $exists: true } } },
    {
        $group: {
            _id: "$cellTowerId",
            eventCount: { $sum: 1 },
            totalUsageMB: { $sum: "$usageMB" }
        }
    },
    { $sort: { eventCount: -1, totalUsageMB: -1, _id: 1 } }
]);
