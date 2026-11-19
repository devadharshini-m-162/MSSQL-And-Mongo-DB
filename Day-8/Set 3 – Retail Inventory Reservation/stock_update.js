use("RetailInventoryMongoDB");

db.products.updateOne(
    { productId: "SKU-1001", stock: { $gte: 2 } },
    { $inc: { stock: -2 } }
);

db.products.find({ productId: "SKU-1001" });
