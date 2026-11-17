
use("RetailSalesMongoDB");

// 1. Month-wise sales.
db.orders.aggregate([
    { $unwind: "$items" },
    {
        $group: {
            _id: {
                year: { $year: "$orderDate" },
                month: { $month: "$orderDate" }
            },
            sales: {
                $sum: { $multiply: ["$items.quantity", "$items.unitPrice"] }
            }
        }
    },
    { $sort: { "_id.year": 1, "_id.month": 1 } }
]);

// 2. Top products by revenue.
db.orders.aggregate([
    { $unwind: "$items" },
    {
        $group: {
            _id: "$items.productId",
            productName: { $first: "$items.productName" },
            revenue: {
                $sum: { $multiply: ["$items.quantity", "$items.unitPrice"] }
            }
        }
    },
    { $sort: { revenue: -1, productName: 1 } },
    { $limit: 5 }
]);

// 3. Average basket value by city.
db.orders.aggregate([
    {
        $set: {
            orderTotal: {
                $sum: {
                    $map: {
                        input: "$items",
                        as: "item",
                        in: { $multiply: ["$$item.quantity", "$$item.unitPrice"] }
                    }
                }
            }
        }
    },
    {
        $group: {
            _id: "$customerCity",
            averageBasketValue: { $avg: "$orderTotal" }
        }
    },
    { $sort: { _id: 1 } }
]);
