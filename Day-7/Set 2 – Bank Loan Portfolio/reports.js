use("BankLoanDB");

// Loans combined with customer documents.
db.loans.aggregate([
    {
        $lookup: {
            from: "customers",
            localField: "customerId",
            foreignField: "customerId",
            as: "customer"
        }
    },
    { $unwind: "$customer" }
]);

// Loans with all repayments.
db.loans.aggregate([
    {
        $lookup: {
            from: "repayments",
            localField: "loanId",
            foreignField: "loanId",
            as: "repayments"
        }
    }
]);

// Last repayment for each loan.
db.loans.aggregate([
    {
        $lookup: {
            from: "repayments",
            let: { loanId: "$loanId" },
            pipeline: [
                { $match: { $expr: { $eq: ["$loanId", "$$loanId"] } } },
                { $sort: { paymentDate: -1 } },
                { $limit: 1 }
            ],
            as: "lastRepayment"
        }
    }
]);
