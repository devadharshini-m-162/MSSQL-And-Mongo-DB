use("LogisticsDB");

// Shipments with delivery events.
db.shipments.aggregate([
    {
        $lookup: {
            from: "deliveryEvents",
            localField: "shipmentId",
            foreignField: "shipmentId",
            as: "deliveryEvents"
        }
    },
    { $sort: { shipmentId: 1 } }
]);

// Customers with their shipments.
db.customers.aggregate([
    {
        $lookup: {
            from: "shipments",
            localField: "customerId",
            foreignField: "customerId",
            as: "shipments"
        }
    },
    { $project: { customerName: 1, shipments: 1 } }
]);

// Carriers with delay statistics.
db.shipments.aggregate([
    {
        $lookup: {
            from: "carriers",
            localField: "carrierId",
            foreignField: "carrierId",
            as: "carrier"
        }
    },
    { $unwind: "$carrier" },
    {
        $set: {
            delayDays: {
                $cond: [
                    { $and: [
                        { $ne: ["$actualDeliveryDate", null] },
                        { $ne: ["$expectedDeliveryDate", null] }
                    ] },
                    { $divide: [
                        { $subtract: ["$actualDeliveryDate", "$expectedDeliveryDate"] },
                        86400000
                    ] },
                    null
                ]
            }
        }
    },
    {
        $group: {
            _id: "$carrier.carrierId",
            carrierName: { $first: "$carrier.carrierName" },
            averageDelayDays: { $avg: "$delayDays" }
        }
    },
    { $sort: { averageDelayDays: -1 } }
]);
