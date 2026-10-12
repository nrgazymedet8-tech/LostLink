USE LostLink;
GO


CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20),
    Role NVARCHAR(30) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT CK_Users_Role CHECK (
        Role IN (
            'OWNER',
            'FINDER',
            'WITNESS',
            'MODERATOR',
            'EMPLOYEE',
            'ADMIN',
            'ANALYST'
        )
    )
);
GO


CREATE TABLE LostItems (
    LostItemId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Color NVARCHAR(50),
    Description NVARCHAR(500),
    Photo NVARCHAR(255),
    LostDate DATETIME NOT NULL,
    SecretProof NVARCHAR(255),
    Status NVARCHAR(30) DEFAULT 'LOST',
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_LostItems_Users
        FOREIGN KEY (UserId)
        REFERENCES Users(UserId),

    CONSTRAINT CK_LostItems_Status
        CHECK (Status IN ('LOST', 'MATCHED', 'RETURNED', 'CLOSED'))
);
GO


CREATE TABLE FoundItems (
    FoundItemId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Color NVARCHAR(50),
    Description NVARCHAR(500),
    Photo NVARCHAR(255),
    FoundDate DATETIME NOT NULL,
    Status NVARCHAR(30) DEFAULT 'FOUND',
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_FoundItems_Users
        FOREIGN KEY (UserId)
        REFERENCES Users(UserId),

    CONSTRAINT CK_FoundItems_Status
        CHECK (Status IN ('FOUND', 'MATCHED', 'RETURNED', 'CLOSED'))
);
GO

CREATE TABLE Locations (
    LocationId INT IDENTITY(1,1) PRIMARY KEY,
    LostItemId INT NULL,
    FoundItemId INT NULL,
    LocationName NVARCHAR(150) NOT NULL,
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),
    EventDateTime DATETIME,
    LocationType NVARCHAR(20) NOT NULL,

    CONSTRAINT FK_Locations_LostItems
        FOREIGN KEY (LostItemId)
        REFERENCES LostItems(LostItemId),

    CONSTRAINT FK_Locations_FoundItems
        FOREIGN KEY (FoundItemId)
        REFERENCES FoundItems(FoundItemId),

    CONSTRAINT CK_Locations_Type
        CHECK (LocationType IN ('LOST', 'FOUND'))
);
GO

CREATE TABLE Predictions (
    PredictionId INT IDENTITY(1,1) PRIMARY KEY,
    LostItemId INT NOT NULL,
    LocationName NVARCHAR(150) NOT NULL,
    Probability DECIMAL(5,2) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Predictions_LostItems
        FOREIGN KEY (LostItemId)
        REFERENCES LostItems(LostItemId),

    CONSTRAINT CK_Predictions_Probability
        CHECK (Probability >= 0 AND Probability <= 100)
);
GO

CREATE TABLE Matches (
    MatchId INT IDENTITY(1,1) PRIMARY KEY,
    LostItemId INT NOT NULL,
    FoundItemId INT NOT NULL,
    SimilarityScore DECIMAL(5,2) NOT NULL,
    Status NVARCHAR(30) DEFAULT 'PENDING',
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Matches_LostItems
        FOREIGN KEY (LostItemId)
        REFERENCES LostItems(LostItemId),

    CONSTRAINT FK_Matches_FoundItems
        FOREIGN KEY (FoundItemId)
        REFERENCES FoundItems(FoundItemId),

    CONSTRAINT CK_Matches_Score
        CHECK (SimilarityScore >= 0 AND SimilarityScore <= 100),

    CONSTRAINT CK_Matches_Status
        CHECK (Status IN ('PENDING', 'MATCHED', 'REJECTED', 'VERIFIED'))
);
GO

CREATE TABLE Notifications (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    MatchId INT NULL,
    Message NVARCHAR(500) NOT NULL,
    NotificationType NVARCHAR(50),
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Notifications_Users
        FOREIGN KEY (UserId)
        REFERENCES Users(UserId),

    CONSTRAINT FK_Notifications_Matches
        FOREIGN KEY (MatchId)
        REFERENCES Matches(MatchId)
);
GO

CREATE TABLE Verifications (
    VerificationId INT IDENTITY(1,1) PRIMARY KEY,
    MatchId INT NOT NULL,
    UserId INT NOT NULL,
    Answer NVARCHAR(255) NOT NULL,
    Status NVARCHAR(30) DEFAULT 'PENDING',
    VerifiedAt DATETIME NULL,

    CONSTRAINT FK_Verifications_Matches
        FOREIGN KEY (MatchId)
        REFERENCES Matches(MatchId),

    CONSTRAINT FK_Verifications_Users
        FOREIGN KEY (UserId)
        REFERENCES Users(UserId),

    CONSTRAINT CK_Verifications_Status
        CHECK (Status IN ('PENDING', 'VERIFIED', 'REJECTED'))
);
GO

CREATE TABLE ReturnRecords (
    ReturnId INT IDENTITY(1,1) PRIMARY KEY,
    VerificationId INT NOT NULL,
    QRCode NVARCHAR(255) NOT NULL UNIQUE,
    ReturnDate DATETIME NULL,
    Status NVARCHAR(30) DEFAULT 'WAITING',

    CONSTRAINT FK_ReturnRecords_Verifications
        FOREIGN KEY (VerificationId)
        REFERENCES Verifications(VerificationId),

    CONSTRAINT CK_ReturnRecords_Status
        CHECK (Status IN ('WAITING', 'COMPLETED', 'CANCELLED'))
);
GO


CREATE TABLE WitnessAlerts (
    AlertId INT IDENTITY(1,1) PRIMARY KEY,
    LostItemId INT NOT NULL,
    UserId INT NOT NULL,
    Message NVARCHAR(500) NOT NULL,
    IsViewed BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_WitnessAlerts_LostItems
        FOREIGN KEY (LostItemId)
        REFERENCES LostItems(LostItemId),

    CONSTRAINT FK_WitnessAlerts_Users
        FOREIGN KEY (UserId)
        REFERENCES Users(UserId)
);
GO



INSERT INTO Users
(FullName, Email, PasswordHash, Phone, Role)
VALUES
(N'����� �?�?���', N'medet@lostlink.kz', N'password123',
 N'+77070000001', N'OWNER'),

(N'��� ����', N'ayan@lostlink.kz', N'password123',
 N'+77070000002', N'FINDER'),

(N'������ ��?��', N'daniyar@lostlink.kz', N'password123',
 N'+77070000003', N'WITNESS'),

(N'����� �����', N'aibek@lostlink.kz', N'password123',
 N'+77070000004', N'MODERATOR'),

(N'�������������', N'admin@lostlink.kz', N'admin123',
 N'+77070000005', N'ADMIN');
GO


INSERT INTO LostItems
(UserId, Name, Category, Color, Description,
 LostDate, SecretProof)
VALUES
(
    1,
    N'?��� ������',
    N'�?���',
    N'?���',
    N'������ �?���� �?�� �������?�� ���',
    GETDATE(),
    N'��� ?��������� �?� ������ ���'
);
GO


INSERT INTO FoundItems
(UserId, Name, Category, Color, Description, FoundDate)
VALUES
(
    2,
    N'?��� ������',
    N'�?���',
    N'?���',
    N'?��� �?�� ������ �������',
    GETDATE()
);
GO


INSERT INTO Locations
(LostItemId, LocationName, Latitude, Longitude,
 EventDateTime, LocationType)
VALUES
(
    1,
    N'?��?� ����?�',
    43.224100,
    76.921600,
    GETDATE(),
    N'LOST'
);
GO



INSERT INTO Locations
(FoundItemId, LocationName, Latitude, Longitude,
 EventDateTime, LocationType)
VALUES
(
    1,
    N'?��?� ����������',
    43.225000,
    76.922000,
    GETDATE(),
    N'FOUND'
);
GO


INSERT INTO Predictions
(LostItemId, LocationName, Probability)
VALUES
(1, N'?��?� ����������', 85.00),
(1, N'?��?� ��� ?�������', 70.00),
(1, N'���������� ?�����?�', 55.00);
GO


INSERT INTO Matches
(LostItemId, FoundItemId, SimilarityScore, Status)
VALUES
(1, 1, 87.50, N'MATCHED');
GO


INSERT INTO Notifications
(UserId, MatchId, Message, NotificationType)
VALUES
(
    1,
    1,
    N'ѳ��? ��?��?�� ����?��?� ??��� ��� �������.',
    N'MATCH_FOUND'
);
GO


INSERT INTO Verifications
(MatchId, UserId, Answer, Status, VerifiedAt)
VALUES
(
    1,
    1,
    N'��� ?��������� �?� ������ ���',
    N'VERIFIED',
    GETDATE()
);
GO


INSERT INTO ReturnRecords
(VerificationId, QRCode, Status)
VALUES
(
    1,
    N'LOSTLINK-RETURN-001',
    N'WAITING'
);
GO


INSERT INTO WitnessAlerts
(LostItemId, UserId, Message)
VALUES
(
    1,
    3,
    N'��� ����?�� ?��� ������ ��?��?��. �?���� �����?��, �?���� ������?��.'
);
GO


SELECT * FROM Users;
SELECT * FROM LostItems;
SELECT * FROM FoundItems;
SELECT * FROM Locations;
SELECT * FROM Predictions;
SELECT * FROM Matches;
SELECT * FROM Notifications;
SELECT * FROM Verifications;
SELECT * FROM ReturnRecords;
SELECT * FROM WitnessAlerts;
GO



UPDATE LostItems
SET Description = N'?��� ������, ������ �?����, �������?�� �?�� �?� ������ ���'
WHERE LostItemId = 1;
GO



INSERT INTO Notifications
(UserId, Message, NotificationType)
VALUES
(
    1,
    N'��?���� ���� �����������',
    N'TEST'
);
GO

DELETE FROM Notifications
WHERE NotificationType = N'TEST';
GO


SELECT * FROM Users;
SELECT * FROM LostItems;
SELECT * FROM FoundItems;
SELECT * FROM Matches;
SELECT * FROM Verifications;
SELECT * FROM ReturnRecords;
GO

пкпк
