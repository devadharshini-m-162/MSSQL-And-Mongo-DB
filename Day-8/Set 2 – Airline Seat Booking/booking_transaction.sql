IF OBJECT_ID('dbo.Day8Seats', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Day8Seats
    (
        FlightId varchar(10) NOT NULL,
        SeatNo varchar(5) NOT NULL,
        SeatStatus varchar(12) NOT NULL,
        CONSTRAINT PK_Day8Seats PRIMARY KEY (FlightId, SeatNo),
        CONSTRAINT CK_Day8Seats_Status CHECK (SeatStatus IN ('AVAILABLE', 'BOOKED'))
    );
END;

IF OBJECT_ID('dbo.Day8Bookings', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Day8Bookings
    (
        BookingId bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FlightId varchar(10) NOT NULL,
        SeatNo varchar(5) NOT NULL,
        PassengerId varchar(20) NOT NULL,
        Fare decimal(10,2) NOT NULL,
        BookedAt datetime2(0) NOT NULL CONSTRAINT DF_Day8Bookings_BookedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_Day8Bookings_FlightSeat UNIQUE (FlightId, SeatNo)
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Day8Seats WHERE FlightId = 'HX101' AND SeatNo = '12A')
    INSERT INTO dbo.Day8Seats (FlightId, SeatNo, SeatStatus) VALUES ('HX101', '12A', 'AVAILABLE');

DECLARE @FlightId varchar(10) = 'HX101',
        @SeatNo varchar(5) = '12A',
        @PassengerId varchar(20) = 'P-1001',
        @Fare decimal(10,2) = 249.99;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Lock the seat row while checking and changing its state.
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Day8Seats WITH (UPDLOCK, HOLDLOCK)
        WHERE FlightId = @FlightId AND SeatNo = @SeatNo AND SeatStatus = 'AVAILABLE'
    )
    BEGIN
        THROW 52001, 'Seat is unavailable or does not exist.', 1;
    END;

    UPDATE dbo.Day8Seats
    SET SeatStatus = 'BOOKED'
    WHERE FlightId = @FlightId AND SeatNo = @SeatNo AND SeatStatus = 'AVAILABLE';
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 52002, 'Seat reservation lost a concurrent update.', 1;
    END;

    INSERT INTO dbo.Day8Bookings (FlightId, SeatNo, PassengerId, Fare)
    VALUES (@FlightId, @SeatNo, @PassengerId, @Fare);

    COMMIT TRANSACTION;
    SELECT 'BOOKED' AS Outcome, @FlightId AS FlightId, @SeatNo AS SeatNo, @PassengerId AS PassengerId;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    SELECT 'NOT BOOKED' AS Outcome, ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;

/*
Two-session race demonstration:
1. Reset the sample seat before each test:
   UPDATE dbo.Day8Seats SET SeatStatus='AVAILABLE'
   WHERE FlightId='HX101' AND SeatNo='12A';
   DELETE dbo.Day8Bookings WHERE FlightId='HX101' AND SeatNo='12A';
2. In Session A run the applicable block below. While it waits, run Session B
   with the same block and PassengerId='P-B'. Session A uses PassengerId='P-A'.
3. Check that only one booking is present:
   SELECT * FROM dbo.Day8Bookings WHERE FlightId='HX101' AND SeatNo='12A';

READ COMMITTED — run this batch in each session, replacing the passenger ID:

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRY
    BEGIN TRANSACTION;
    SELECT SeatStatus FROM dbo.Day8Seats
    WHERE FlightId='HX101' AND SeatNo='12A';
    WAITFOR DELAY '00:00:10';
    UPDATE dbo.Day8Seats SET SeatStatus='BOOKED'
    WHERE FlightId='HX101' AND SeatNo='12A' AND SeatStatus='AVAILABLE';
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 52101, 'Seat already booked.', 1;
    END;
    INSERT dbo.Day8Bookings(FlightId,SeatNo,PassengerId,Fare)
    VALUES('HX101','12A','P-A',200.00);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE() AS BookingOutcome;
END CATCH;

SERIALIZABLE — reset the seat and bookings, then run in each session:

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.Day8Seats WITH (UPDLOCK, HOLDLOCK)
        WHERE FlightId='HX101' AND SeatNo='12A' AND SeatStatus='AVAILABLE'
    )
    BEGIN
        THROW 52102, 'Seat already booked.', 1;
    END;
    WAITFOR DELAY '00:00:10';
    UPDATE dbo.Day8Seats SET SeatStatus='BOOKED'
    WHERE FlightId='HX101' AND SeatNo='12A' AND SeatStatus='AVAILABLE';
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 52103, 'Seat already booked.', 1;
    END;
    INSERT dbo.Day8Bookings(FlightId,SeatNo,PassengerId,Fare)
    VALUES('HX101','12A','P-A',200.00);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE() AS BookingOutcome;
END CATCH;

The conditional update and UNIQUE constraint are correctness guards in either
mode. READ COMMITTED allows both initial reads to observe AVAILABLE; the second
conditional update waits and then affects zero rows. SERIALIZABLE with
UPDLOCK/HOLDLOCK blocks the second session at the protected read until the first
commits, after which it observes the unavailable seat.
*/
