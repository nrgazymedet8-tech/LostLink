USE LostLink;
GO

/* =========================================================
   LOSTLINK ДЕРЕКТЕР ?ОРЫ
   ========================================================= */


/* =========================================================
   1. USERS — ПАЙДАЛАНУШЫЛАР
   ========================================================= */

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


/* =========================================================
   2. LOSTITEMS — ЖО?АЛ?АН ЗАТТАР
   ========================================================= */

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


/* =========================================================
   3. FOUNDITEMS — ТАБЫЛ?АН ЗАТТАР
   ========================================================= */

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


/* =========================================================
   4. LOCATIONS — ОРЫНДАР
   ========================================================= */

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


/* =========================================================
   5. PREDICTIONS — PREDICTIVE SEARCH Н?ТИЖЕЛЕРІ
   ========================================================= */

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


/* =========================================================
   6. MATCHES — AI MATCHING
   ========================================================= */

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


/* =========================================================
   7. NOTIFICATIONS — ХАБАРЛАМАЛАР
   ========================================================= */

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


/* =========================================================
   8. VERIFICATIONS — SECRET PROOF
   ========================================================= */

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


/* =========================================================
   9. RETURNRECORDS — ЗАТТЫ ?АЙТАРУ
   ========================================================= */

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


/* =========================================================
   10. DIGITAL WITNESS ХАБАРЛАМАЛАРЫ
   ========================================================= */

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


/* =========================================================
   ТЕСТ ?ШІН ДЕРЕКТЕР ЕНГІЗУ — INSERT
   ========================================================= */

INSERT INTO Users
(FullName, Email, PasswordHash, Phone, Role)
VALUES
(N'Медет Н?р?азы', N'medet@lostlink.kz', N'password123',
 N'+77070000001', N'OWNER'),

(N'Аян Серік', N'ayan@lostlink.kz', N'password123',
 N'+77070000002', N'FINDER'),

(N'Данияр Ас?ар', N'daniyar@lostlink.kz', N'password123',
 N'+77070000003', N'WITNESS'),

(N'Айбек Марат', N'aibek@lostlink.kz', N'password123',
 N'+77070000004', N'MODERATOR'),

(N'Администратор', N'admin@lostlink.kz', N'admin123',
 N'+77070000005', N'ADMIN');
GO


/* Жо?ал?ан зат */

INSERT INTO LostItems
(UserId, Name, Category, Color, Description,
 LostDate, SecretProof)
VALUES
(
    1,
    N'?ара рюкзак',
    N'С?мке',
    N'?ара',
    N'Ішінде д?птер ж?не зарядта?ыш бар',
    GETDATE(),
    N'Ішкі ?алтасында к?к брелок бар'
);
GO


/* Табыл?ан зат */

INSERT INTO FoundItems
(UserId, Name, Category, Color, Description, FoundDate)
VALUES
(
    2,
    N'?ара рюкзак',
    N'С?мке',
    N'?ара',
    N'?ара т?сті рюкзак табылды',
    GETDATE()
);
GO


/* Жо?ал?ан орын */

INSERT INTO Locations
(LostItemId, LocationName, Latitude, Longitude,
 EventDateTime, LocationType)
VALUES
(
    1,
    N'?аз?У аума?ы',
    43.224100,
    76.921600,
    GETDATE(),
    N'LOST'
);
GO


/* Табыл?ан орын */

INSERT INTO Locations
(FoundItemId, LocationName, Latitude, Longitude,
 EventDateTime, LocationType)
VALUES
(
    1,
    N'?аз?У кітапханасы',
    43.225000,
    76.922000,
    GETDATE(),
    N'FOUND'
);
GO


/* Predictive Search н?тижесі */

INSERT INTO Predictions
(LostItemId, LocationName, Probability)
VALUES
(1, N'?аз?У кітапханасы', 85.00),
(1, N'?аз?У бас ?имараты', 70.00),
(1, N'Студенттер ?алашы?ы', 55.00);
GO


/* AI Matching н?тижесі */

INSERT INTO Matches
(LostItemId, FoundItemId, SimilarityScore, Status)
VALUES
(1, 1, 87.50, N'MATCHED');
GO


/* Хабарлама */

INSERT INTO Notifications
(UserId, MatchId, Message, NotificationType)
VALUES
(
    1,
    1,
    N'Сізді? жо?ал?ан заты?ыз?а ??сас зат табылды.',
    N'MATCH_FOUND'
);
GO


/* Secret Proof */

INSERT INTO Verifications
(MatchId, UserId, Answer, Status, VerifiedAt)
VALUES
(
    1,
    1,
    N'Ішкі ?алтасында к?к брелок бар',
    N'VERIFIED',
    GETDATE()
);
GO


/* QR-код */

INSERT INTO ReturnRecords
(VerificationId, QRCode, Status)
VALUES
(
    1,
    N'LOSTLINK-RETURN-001',
    N'WAITING'
);
GO


/* Digital Witness хабарламасы */

INSERT INTO WitnessAlerts
(LostItemId, UserId, Message)
VALUES
(
    1,
    3,
    N'Осы айма?та ?ара рюкзак жо?ал?ан. К?рген болса?ыз, ж?йеде белгіле?із.'
);
GO


/* =========================================================
   SELECT — КЕСТЕЛЕРДІ ТЕКСЕРУ
   ========================================================= */

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


/* =========================================================
   UPDATE МЫСАЛЫ
   ========================================================= */

UPDATE LostItems
SET Description = N'?ара рюкзак, ішінде д?птер, зарядта?ыш ж?не к?к брелок бар'
WHERE LostItemId = 1;
GO


/* =========================================================
   DELETE МЫСАЛЫ
   Уа?ытша хабарлама ?осып, кейін ?шіреміз
   ========================================================= */

INSERT INTO Notifications
(UserId, Message, NotificationType)
VALUES
(
    1,
    N'Уа?ытша тест хабарламасы',
    N'TEST'
);
GO

DELETE FROM Notifications
WHERE NotificationType = N'TEST';
GO


/* =========================================================
   СО??Ы Н?ТИЖЕЛЕРДІ К?РУ
   ========================================================= */

USE LostLink;
GO

/* =========================================================
   1. USERS
   Қазір 5 жол бар → тағы 5 пайдаланушы қосамыз
   ========================================================= */

INSERT INTO Users
(FullName, Email, PasswordHash, Phone, Role)
VALUES
(N'Алихан Ермек', N'alikhan@lostlink.kz', N'password123',
 N'+77070000006', N'OWNER'),

(N'Нұрбек Асан', N'nurbek@lostlink.kz', N'password123',
 N'+77070000007', N'FINDER'),

(N'Аружан Болат', N'aruzhan@lostlink.kz', N'password123',
 N'+77070000008', N'WITNESS'),

(N'Мирас Жандос', N'miras@lostlink.kz', N'password123',
 N'+77070000009', N'EMPLOYEE'),

(N'Аналитик', N'analyst@lostlink.kz', N'password123',
 N'+77070000010', N'ANALYST');
GO


/* =========================================================
   2. LOSTITEMS
   1 бар → тағы 9 жоғалған зат
   ========================================================= */

INSERT INTO LostItems
(UserId, Name, Category, Color, Description, LostDate, SecretProof)
VALUES
(1, N'Ақ құлаққап', N'Электроника', N'Ақ',
 N'Сымсыз құлаққап', DATEADD(DAY,-1,GETDATE()),
 N'Қорабында M әрпі жазылған'),

(6, N'Қоңыр әмиян', N'Әмиян', N'Қоңыр',
 N'Былғары әмиян', DATEADD(DAY,-2,GETDATE()),
 N'Ішінде студенттік билет бар'),

(1, N'Көк телефон', N'Электроника', N'Көк',
 N'Смартфон қара қаппен', DATEADD(DAY,-3,GETDATE()),
 N'Экран фонында тау суреті бар'),

(6, N'Кілттер жинағы', N'Кілт', N'Күміс',
 N'Үш кілттен тұратын жинақ', DATEADD(DAY,-4,GETDATE()),
 N'Қызыл брелок тағылған'),

(1, N'Сұр күртеше', N'Киім', N'Сұр',
 N'Жеңіл сұр күртеше', DATEADD(DAY,-5,GETDATE()),
 N'Ішкі қалтасында белгі бар'),

(6, N'Қара сағат', N'Аксессуар', N'Қара',
 N'Қол сағаты', DATEADD(DAY,-6,GETDATE()),
 N'Артында 2025 деген жазу бар'),

(1, N'Студенттік билет', N'Құжат', N'Көк',
 N'ҚазҰУ студенттік билеті', DATEADD(DAY,-7,GETDATE()),
 N'Факультет IT деп жазылған'),

(6, N'Қызыл қолшатыр', N'Аксессуар', N'Қызыл',
 N'Жиналмалы қолшатыр', DATEADD(DAY,-8,GETDATE()),
 N'Сабағында ақ белгі бар'),

(1, N'Ноутбук сөмкесі', N'Сөмке', N'Қара',
 N'Ноутбукке арналған сөмке', DATEADD(DAY,-9,GETDATE()),
 N'Ішінде USB кабель бар');
GO


/* =========================================================
   3. FOUNDITEMS
   1 бар → тағы 9 табылған зат
   ========================================================= */

INSERT INTO FoundItems
(UserId, Name, Category, Color, Description, FoundDate)
VALUES
(2, N'Ақ құлаққап', N'Электроника', N'Ақ',
 N'Ақ сымсыз құлаққап табылды', DATEADD(HOUR,-5,GETDATE())),

(7, N'Қоңыр әмиян', N'Әмиян', N'Қоңыр',
 N'Қоңыр былғары әмиян табылды', DATEADD(HOUR,-8,GETDATE())),

(2, N'Көк телефон', N'Электроника', N'Көк',
 N'Көк телефон табылды', DATEADD(DAY,-1,GETDATE())),

(7, N'Кілттер жинағы', N'Кілт', N'Күміс',
 N'Бірнеше кілт табылды', DATEADD(DAY,-2,GETDATE())),

(2, N'Сұр күртеше', N'Киім', N'Сұр',
 N'Сұр күртеше табылды', DATEADD(DAY,-3,GETDATE())),

(7, N'Қара сағат', N'Аксессуар', N'Қара',
 N'Қара қол сағаты табылды', DATEADD(DAY,-4,GETDATE())),

(2, N'Студенттік билет', N'Құжат', N'Көк',
 N'Студенттік билет табылды', DATEADD(DAY,-5,GETDATE())),

(7, N'Қызыл қолшатыр', N'Аксессуар', N'Қызыл',
 N'Қызыл қолшатыр табылды', DATEADD(DAY,-6,GETDATE())),

(2, N'Ноутбук сөмкесі', N'Сөмке', N'Қара',
 N'Қара ноутбук сөмкесі табылды', DATEADD(DAY,-7,GETDATE()));
GO


/* =========================================================
   4. LOCATIONS
   2 бар → тағы 8 орын
   ========================================================= */

INSERT INTO Locations
(LostItemId, FoundItemId, LocationName,
 Latitude, Longitude, EventDateTime, LocationType)
VALUES
(2, NULL, N'ҚазҰУ IT факультеті',
 43.224500, 76.921800, GETDATE(), N'LOST'),

(NULL, 2, N'ҚазҰУ кітапханасы',
 43.225000, 76.922000, GETDATE(), N'FOUND'),

(3, NULL, N'Студенттер қалашығы',
 43.226000, 76.920000, GETDATE(), N'LOST'),

(NULL, 3, N'ҚазҰУ спорт кешені',
 43.223500, 76.919500, GETDATE(), N'FOUND'),

(4, NULL, N'ҚазҰУ бас ғимараты',
 43.224800, 76.922500, GETDATE(), N'LOST'),

(NULL, 4, N'ҚазҰУ асханасы',
 43.225500, 76.921000, GETDATE(), N'FOUND'),

(5, NULL, N'Фараби даңғылы',
 43.222500, 76.918000, GETDATE(), N'LOST'),

(NULL, 5, N'Автобус аялдамасы',
 43.223000, 76.917500, GETDATE(), N'FOUND');
GO


/* =========================================================
   5. PREDICTIONS
   3 бар → тағы 7 нәтиже
   ========================================================= */

INSERT INTO Predictions
(LostItemId, LocationName, Probability)
VALUES
(2, N'ҚазҰУ кітапханасы', 82.00),
(3, N'Студенттер қалашығы', 78.50),
(4, N'ҚазҰУ бас ғимараты', 75.00),
(5, N'ҚазҰУ асханасы', 69.50),
(6, N'Спорт кешені', 65.00),
(7, N'Автобус аялдамасы', 61.50),
(8, N'IT факультеті', 58.00);
GO


/* =========================================================
   6. MATCHES
   1 бар → тағы 9 AI сәйкестік
   ========================================================= */

INSERT INTO Matches
(LostItemId, FoundItemId, SimilarityScore, Status)
VALUES
(2, 2, 94.50, N'MATCHED'),
(3, 3, 91.00, N'MATCHED'),
(4, 4, 88.50, N'MATCHED'),
(5, 5, 84.00, N'MATCHED'),
(6, 6, 79.50, N'PENDING'),
(7, 7, 96.00, N'VERIFIED'),
(8, 8, 72.50, N'PENDING'),
(9, 9, 45.00, N'REJECTED'),
(10, 10, 89.00, N'MATCHED');
GO


/* =========================================================
   7. NOTIFICATIONS
   Негізгі хабарлама 1 бар → тағы 9
   ========================================================= */

INSERT INTO Notifications
(UserId, MatchId, Message, NotificationType, IsRead)
VALUES
(1, 2, N'Ақ құлаққапқа ұқсас зат табылды.', N'MATCH_FOUND', 0),
(6, 3, N'Әмияныңызға ұқсас зат табылды.', N'MATCH_FOUND', 1),
(1, 4, N'Телефоныңызға ұқсас зат табылды.', N'MATCH_FOUND', 0),
(6, 5, N'Кілттер жинағына сәйкестік табылды.', N'MATCH_FOUND', 0),
(1, 6, N'Сұр күртешеге ұқсас зат табылды.', N'MATCH_FOUND', 1),
(6, 7, N'Қара сағат бойынша сәйкестік бар.', N'MATCH_FOUND', 0),
(1, 8, N'Студенттік билет табылды.', N'MATCH_FOUND', 1),
(6, 9, N'Қолшатырға ұқсас зат тіркелді.', N'MATCH_FOUND', 0),
(1, 10, N'Ноутбук сөмкесіне сәйкестік табылды.', N'MATCH_FOUND', 0);
GO


/* =========================================================
   8. VERIFICATIONS
   1 бар → тағы 9 Secret Proof тексеруі
   ========================================================= */

INSERT INTO Verifications
(MatchId, UserId, Answer, Status, VerifiedAt)
VALUES
(2, 1, N'Қорабында M әрпі бар', N'VERIFIED', GETDATE()),
(3, 6, N'Ішінде студенттік билет бар', N'VERIFIED', GETDATE()),
(4, 1, N'Экран фонында тау суреті бар', N'VERIFIED', GETDATE()),
(5, 6, N'Қызыл брелок бар', N'VERIFIED', GETDATE()),
(6, 1, N'Ішкі қалтасында белгі бар', N'PENDING', NULL),
(7, 6, N'Артында 2025 жазуы бар', N'VERIFIED', GETDATE()),
(8, 1, N'IT факультеті', N'VERIFIED', GETDATE()),
(9, 6, N'Қате белгі', N'REJECTED', GETDATE()),
(10, 1, N'Ішінде USB кабель бар', N'VERIFIED', GETDATE());
GO


/* =========================================================
   9. RETURNRECORDS
   1 бар → тағы 9
   ========================================================= */

INSERT INTO ReturnRecords
(VerificationId, QRCode, ReturnDate, Status)
VALUES
(2, N'LOSTLINK-RETURN-002', GETDATE(), N'COMPLETED'),
(3, N'LOSTLINK-RETURN-003', GETDATE(), N'COMPLETED'),
(4, N'LOSTLINK-RETURN-004', GETDATE(), N'COMPLETED'),
(5, N'LOSTLINK-RETURN-005', NULL, N'WAITING'),
(6, N'LOSTLINK-RETURN-006', NULL, N'WAITING'),
(7, N'LOSTLINK-RETURN-007', GETDATE(), N'COMPLETED'),
(8, N'LOSTLINK-RETURN-008', GETDATE(), N'COMPLETED'),
(9, N'LOSTLINK-RETURN-009', NULL, N'CANCELLED'),
(10, N'LOSTLINK-RETURN-010', NULL, N'WAITING');
GO


/* =========================================================
   10. WITNESSALERTS
   1 бар → тағы 9 Digital Witness хабарламасы
   ========================================================= */

INSERT INTO WitnessAlerts
(LostItemId, UserId, Message, IsViewed)
VALUES
(2, 3, N'Осы аймақта ақ құлаққап жоғалған.', 0),
(3, 8, N'Қоңыр әмиян жоғалған. Көрдіңіз бе?', 1),
(4, 3, N'Көк телефон ізделуде.', 0),
(5, 8, N'Кілттер жинағы жоғалған.', 0),
(6, 3, N'Сұр күртеше жоғалған.', 1),
(7, 8, N'Қара қол сағаты ізделуде.', 0),
(8, 3, N'Студенттік билет жоғалған.', 1),
(9, 8, N'Қызыл қолшатыр ізделуде.', 0),
(10, 3, N'Қара ноутбук сөмкесі жоғалған.', 0);
GO


/* =========================================================
   БАРЛЫҚ КЕСТЕЛЕРДІ ТЕКСЕРУ
   ========================================================= */

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
