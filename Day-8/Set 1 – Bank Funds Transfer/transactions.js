use("BankTransferMongoDB");

const session = db.getMongo().startSession();
const bankDb = session.getDatabase("BankTransferMongoDB");

session.startTransaction();
try {
    const debit = bankDb.accounts.updateOne(
        {
            accountId: "A-101",
            status: "ACTIVE",
            balanceCents: { $gte: NumberLong("12500") }
        },
        { $inc: { balanceCents: NumberLong("-12500") } },
        { session: session }
    );

    if (debit.modifiedCount !== 1) {
        throw new Error("Source account is inactive or has insufficient funds.");
    }

    const credit = bankDb.accounts.updateOne(
        { accountId: "A-202", status: "ACTIVE" },
        { $inc: { balanceCents: NumberLong("12500") } },
        { session: session }
    );

    if (credit.modifiedCount !== 1) {
        throw new Error("Destination account is inactive or does not exist.");
    }

    session.commitTransaction();
} catch (error) {
    session.abortTransaction();
    throw error;
} finally {
    session.endSession();
}
