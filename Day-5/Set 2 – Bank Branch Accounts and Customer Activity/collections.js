
// Set 2 - Bank Branch Accounts and Customer Activity
// MongoDB: BankActivityMongoDB

use("BankActivityMongoDB");

// 1. Create a capped collection
db.createCollection("activityLogs", {
    capped: true,
    size: 1048576,
    max: 1000
});

// 2. Insert 20 customer activity log documents
db.activityLogs.insertMany([
    {
        logId: "L001",
        customerId: "C001",
        activityType: "login",
        activityTime: ISODate("2026-11-17T08:00:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L002",
        customerId: "C001",
        activityType: "fund_transfer",
        activityTime: ISODate("2026-11-17T08:15:00Z"),
        details: "Transferred Rs. 5000"
    },
    {
        logId: "L003",
        customerId: "C002",
        activityType: "login",
        activityTime: ISODate("2026-11-17T08:20:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L004",
        customerId: "C001",
        activityType: "logout",
        activityTime: ISODate("2026-11-17T08:30:00Z"),
        details: "Customer logged out"
    },
    {
        logId: "L005",
        customerId: "C003",
        activityType: "login",
        activityTime: ISODate("2026-11-17T08:45:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L006",
        customerId: "C001",
        activityType: "login",
        activityTime: ISODate("2026-11-17T09:00:00Z"),
        details: "Customer logged in from mobile"
    },
    {
        logId: "L007",
        customerId: "C002",
        activityType: "fund_transfer",
        activityTime: ISODate("2026-11-17T09:10:00Z"),
        details: "Transferred Rs. 2000"
    },
    {
        logId: "L008",
        customerId: "C003",
        activityType: "logout",
        activityTime: ISODate("2026-11-17T09:20:00Z"),
        details: "Customer logged out"
    },
    {
        logId: "L009",
        customerId: "C001",
        activityType: "login",
        activityTime: ISODate("2026-11-17T09:30:00Z"),
        details: "Customer logged in from desktop"
    },
    {
        logId: "L010",
        customerId: "C002",
        activityType: "login",
        activityTime: ISODate("2026-11-17T09:45:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L011",
        customerId: "C003",
        activityType: "fund_transfer",
        activityTime: ISODate("2026-11-17T10:00:00Z"),
        details: "Transferred Rs. 10000"
    },
    {
        logId: "L012",
        customerId: "C002",
        activityType: "logout",
        activityTime: ISODate("2026-11-17T10:10:00Z"),
        details: "Customer logged out"
    },
    {
        logId: "L013",
        customerId: "C001",
        activityType: "login",
        activityTime: ISODate("2026-11-17T10:20:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L014",
        customerId: "C003",
        activityType: "login",
        activityTime: ISODate("2026-11-17T10:40:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L015",
        customerId: "C001",
        activityType: "login",
        activityTime: ISODate("2026-11-17T11:00:00Z"),
        details: "Customer logged in from mobile"
    },
    {
        logId: "L016",
        customerId: "C002",
        activityType: "fund_transfer",
        activityTime: ISODate("2026-11-17T11:15:00Z"),
        details: "Transferred Rs. 3000"
    },
    {
        logId: "L017",
        customerId: "C003",
        activityType: "logout",
        activityTime: ISODate("2026-11-17T11:30:00Z"),
        details: "Customer logged out"
    },
    {
        logId: "L018",
        customerId: "C002",
        activityType: "login",
        activityTime: ISODate("2026-11-17T11:45:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L019",
        customerId: "C001",
        activityType: "login",
        activityTime: ISODate("2026-11-17T12:00:00Z"),
        details: "Customer logged in"
    },
    {
        logId: "L020",
        customerId: "C003",
        activityType: "login",
        activityTime: ISODate("2026-11-17T12:10:00Z"),
        details: "Customer logged in"
    }
]);

// 3. Verify document count
print("Total activity logs:");
print(db.activityLogs.countDocuments());

// 4. Display all activity logs
db.activityLogs.find().sort({ logId: 1 });

// 5. Retrieve the last five login events of customer C001
print("Last five login events for customer C001:");

db.activityLogs.find({
    customerId: "C001",
    activityType: "login"
})
.sort({ activityTime: -1 })
.limit(5);

// 6. Verify that the collection is capped
print("Is activityLogs a capped collection?");
print(db.activityLogs.isCapped());

// 7. Display collection information
db.getCollectionInfos({ name: "activityLogs" });
