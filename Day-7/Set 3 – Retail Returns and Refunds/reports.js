use("RetailReturnsDB");

// Returns combined with refund documents.
db.returns.aggregate([
    {
        $lookup: {
            from: "refunds",
            localField: "returnId",
            foreignField: "returnId",
            as: "refund"
        }
    },
    { $sort: { returnId: 1 } }
]);

// Customers combined with their returns.
db.customers.aggregate([
    {
        $lookup: {
            from: "returns",
            localField: "customerId",
            foreignField: "customerId",
            as: "returns"
        }
    },
    { $project: { customerName: 1, returns: 1 } }
]);

// Returns combined with feedback.
db.returns.aggregate([
    {
        $lookup: {
            from: "feedback",
            localField: "returnId",
            foreignField: "returnId",
            as: "feedback"
        }
    },
    {
        $project: {
            returnId: 1,
            productId: 1,
            customerId: 1,
            feedback: 1
        }
    }
]);
