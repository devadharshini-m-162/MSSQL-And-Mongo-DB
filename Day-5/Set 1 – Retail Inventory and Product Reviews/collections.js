
use RetailInventoryMongoDB

// Create reviews collection with schema validation
db.createCollection("reviews", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: [
                "reviewId", "sku", "customerId",
                "rating", "reviewText", "createdAt"
            ],
            properties: {
                reviewId: { bsonType: "string" },
                sku: { bsonType: "string" },
                customerId: { bsonType: "string" },
                rating: {
                    bsonType: "int",
                    minimum: 1,
                    maximum: 5
                },
                reviewText: { bsonType: "string" },
                createdAt: { bsonType: "date" },
                verifiedPurchase: { bsonType: "bool" }
            }
        }
    }
});

// Insert sample reviews
db.reviews.insertMany([
    {
        reviewId: "R001", sku: "P101", customerId: "C001",
        rating: NumberInt(5),
        reviewText: "Excellent laptop performance",
        createdAt: ISODate("2026-11-15"),
        verifiedPurchase: true
    },
    {
        reviewId: "R002", sku: "P102", customerId: "C002",
        rating: NumberInt(4),
        reviewText: "Good wireless mouse",
        createdAt: ISODate("2026-11-15"),
        verifiedPurchase: true
    },
    {
        reviewId: "R003", sku: "P103", customerId: "C003",
        rating: NumberInt(3),
        reviewText: "Comfortable but expensive",
        createdAt: ISODate("2026-11-16"),
        verifiedPurchase: false
    },
    {
        reviewId: "R004", sku: "P104", customerId: "C004",
        rating: NumberInt(5),
        reviewText: "Very useful desk lamp",
        createdAt: ISODate("2026-11-16"),
        verifiedPurchase: true
    },
    {
        reviewId: "R005", sku: "P105", customerId: "C005",
        rating: NumberInt(2),
        reviewText: "Not satisfied with quality",
        createdAt: ISODate("2026-11-17"),
        verifiedPurchase: true
    }
]);

// Retrieve all reviews
db.reviews.find();

// Retrieve review for a particular SKU
db.reviews.find({ sku: "P101" });

// Update a review
db.reviews.updateOne(
    { reviewId: "R003" },
    {
        $set: {
            rating: NumberInt(4),
            reviewText: "Comfortable and good quality"
        }
    }
);

// Delete a review
db.reviews.deleteOne({ reviewId: "R005" });

// Display remaining reviews
db.reviews.find();
