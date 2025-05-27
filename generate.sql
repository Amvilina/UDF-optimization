-- Очистка таблиц и сброс идентификаторов
DELETE FROM WorkItem;
DELETE FROM Works;
DELETE FROM Analiz;
DELETE FROM Employee;
DELETE FROM WorkStatus;

DBCC CHECKIDENT ('WorkItem', RESEED, 0);
DBCC CHECKIDENT ('Works', RESEED, 0);
DBCC CHECKIDENT ('Analiz', RESEED, 0);
DBCC CHECKIDENT ('Employee', RESEED, 0);
DBCC CHECKIDENT ('WorkStatus', RESEED, 0);

-- Заполнение сотрудников
WITH NumRange AS (
    SELECT number FROM master.dbo.spt_values WHERE type = 'P' AND number BETWEEN 1 AND 100
)
INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, Archived, IS_Role)
SELECT
    CONCAT('medic_', number),
    CONCAT('Имя_', number),
    CONCAT('П.', number),
    CONCAT('Фам_', number),
    CONCAT('medic_', number, '@mail.test'),
    'Терапевт',
    SYSDATETIME(),
    0,
    0
FROM NumRange;

-- Заполнение анализов
WITH Range200 AS (
    SELECT number FROM master.dbo.spt_values WHERE type = 'P' AND number BETWEEN 1 AND 200
)
INSERT INTO Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Text_Norm, Price)
SELECT
    0,
    1,
    CONCAT('AN', number),
    CONCAT('Исследование №', number),
    'Референс',
    ROUND(RAND(CHECKSUM(NEWID()) + number) * 950 + 50, 2)
FROM Range200;

-- Заполнение статусов
INSERT INTO WorkStatus (StatusName)
VALUES ('Новый'), ('Обрабатывается'), ('Завершён'), ('Выслан'), ('Удалён');

-- Генерация 50 000 записей в Works
WITH Numbers AS (
    SELECT TOP 50000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS idx
    FROM master.dbo.spt_values AS A
    CROSS JOIN master.dbo.spt_values AS B
),
Emps AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Id_Employee) AS rn, Id_Employee FROM Employee
),
Stats AS (
    SELECT ROW_NUMBER() OVER (ORDER BY StatusID) AS rn, StatusID FROM WorkStatus
)
INSERT INTO Works (IS_Complit, CREATE_Date, Id_Employee, FIO, StatusId)
SELECT
    idx % 2,
    DATEADD(DAY, -idx % 365, SYSDATETIME()),
    e.Id_Employee,
    CONCAT('Клиент_', idx),
    s.StatusID
FROM Numbers n
JOIN Emps e ON e.rn = 1 + (n.idx % (SELECT COUNT(*) FROM Emps))
JOIN Stats s ON s.rn = 1 + (n.idx % (SELECT COUNT(*) FROM Stats));

-- Генерация 150 000 записей в WorkItem
WITH AnalItems AS (
    SELECT ROW_NUMBER() OVER (ORDER BY ID_ANALIZ) AS rn, ID_ANALIZ FROM Analiz
),
AllEmps AS (
    SELECT ROW_NUMBER() OVER (ORDER BY Id_Employee) AS rn, Id_Employee FROM Employee
),
BigRange AS (
    SELECT TOP 150000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM master.dbo.spt_values a
    CROSS JOIN master.dbo.spt_values b
)
INSERT INTO WorkItem (Is_Complit, ID_ANALIZ, Id_Work, Id_Employee, Is_Print)
SELECT
    n.n % 2,
    a.ID_ANALIZ,
    w.Id_Work,
    e.Id_Employee,
    1
FROM BigRange n
JOIN Works w ON w.Id_Work = 1 + (n.n % 50000)
JOIN AnalItems a ON a.rn = 1 + (n.n % (SELECT COUNT(*) FROM AnalItems))
JOIN AllEmps e ON e.rn = 1 + (n.n % (SELECT COUNT(*) FROM AllEmps));