use("AirlineBookingMongoDB");

const session = db.getMongo().startSession();
const bookingDb = session.getDatabase("AirlineBookingMongoDB");

session.startTransaction();
try {
    const seat = bookingDb.seats.updateOne(
        { flightId: "HX101", seatNo: "12A", status: "AVAILABLE" },
        { $set: { status: "BOOKED" } },
        { session: session }
    );

    if (seat.modifiedCount !== 1) {
        throw new Error("Seat is unavailable.");
    }

    bookingDb.bookings.insertOne(
        {
            flightId: "HX101",
            seatNo: "12A",
            passengerId: "P-1001",
            fare: 249.99
        },
        { session: session }
    );

    session.commitTransaction();
} catch (error) {
    session.abortTransaction();
    throw error;
} finally {
    session.endSession();
}
