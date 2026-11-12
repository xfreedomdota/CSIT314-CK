-- CK Interior Design Platform - Test Data queries for User Stories #1-#48
-- How to use: phpMyAdmin > interior_design > SQL tab > paste ONE story's query > Go > screenshot the result.
-- Run each query BEFORE doing that story's test case. For stories that change data,
-- run the same query again AFTER the test for a before/after pair.
-- Every generated account's password is Test123!

-- =====================================================================
-- USER ADMIN (#1-#12)
-- =====================================================================

-- #1 User Admin login: admin01 (Active) for valid/wrong password, admin02 (Suspended)
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username IN ('admin01', 'admin02');

-- #2 User Admin logout: the account that logs out
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username = 'admin01';

-- #3 Create user profile: ID99 does not exist yet (before), ID03 already exists (duplicate test)
-- Run again after the test: ID99 should appear
SELECT username, name, type, status
FROM userprofile
WHERE username IN ('ID99', 'ID03');

-- #4 View user profile
SELECT username, name, type, status
FROM userprofile
WHERE username = 'ID03';

-- #5 Update user profile (before/after: name changes)
SELECT username, name, type, status
FROM userprofile
WHERE username = 'ID03';

-- #6 Suspend user profile (before/after: status Active -> Suspended)
SELECT username, name, type, status
FROM userprofile
WHERE username = 'ID05';

-- #7 Search user profiles by filter: expected results for type "User Admin"
SELECT username, name, type, status
FROM userprofile
WHERE type = 'User Admin';

-- #8 Create user account: ID99 has no account yet (before), run again after
SELECT userId, username, email, status
FROM useraccount
WHERE username = 'ID99';

-- #9 View user account
SELECT userId, username, email, status
FROM useraccount
WHERE username = 'ID03';

-- #10 Update user account (before/after: email changes)
SELECT userId, username, email, status
FROM useraccount
WHERE username = 'ID06';

-- #11 Suspend user account: ID06 Active (to suspend), ID04 already Suspended
SELECT userId, username, email, status
FROM useraccount
WHERE username IN ('ID06', 'ID04');

-- #12 Search user accounts: expected results for keyword "admin"
SELECT userId, username, email, status
FROM useraccount
WHERE username LIKE '%admin%' OR email LIKE '%admin%';

-- =====================================================================
-- INTERIOR DESIGNER - LOGIN AND COMPANY (#13-#19)
-- =====================================================================

-- #13 Interior Designer login: ID01 (Active), ID02 (Suspended)
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username IN ('ID01', 'ID02');

-- #14 Interior Designer logout
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username = 'ID01';

-- #15 Register company: ID99 has no company yet (before), ID01 already has one (duplicate test)
SELECT a.username, c.companyID, c.companyName, c.regNum
FROM useraccount a LEFT JOIN company c ON c.designerID = a.userId
WHERE a.username IN ('ID99', 'ID01');

-- #16 View company information
SELECT c.companyID, c.companyName, c.regNum, c.description, c.address, a.username
FROM company c JOIN useraccount a ON a.userId = c.designerID
WHERE a.username = 'ID01';

-- #17 Update company information (before/after: address changes)
SELECT c.companyID, c.companyName, c.regNum, c.address, a.username
FROM company c JOIN useraccount a ON a.userId = c.designerID
WHERE a.username = 'ID01';

-- #18 Delete company information (before/after: ID99's company disappears)
SELECT c.companyID, c.companyName, c.regNum, a.username
FROM company c JOIN useraccount a ON a.userId = c.designerID
WHERE a.username = 'ID99';

-- #19 Search company information: expected results for keyword "Sim"
SELECT companyID, companyName, regNum, address
FROM company
WHERE companyName LIKE '%Sim%';

-- =====================================================================
-- CUSTOMER (#20-#26)
-- =====================================================================

-- #20 Customer login: Customer01 (Active), Customer02 (Suspended)
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username IN ('Customer01', 'Customer02');

-- #21 Customer logout
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username = 'Customer01';

-- #22 Search IDPs: expected results for keyword "Cafe" in category "Hospitality"
SELECT projectID, title, category, status
FROM idp
WHERE (title LIKE '%Cafe%' OR description LIKE '%Cafe%') AND category = 'Hospitality';

-- #23 View an IDP (before/after: view count goes up by 1)
SELECT i.projectID, i.title, i.category, i.status,
       (SELECT COUNT(*) FROM project_views v WHERE v.projectID = i.projectID) AS view_count
FROM idp i
WHERE i.title = 'Warm Terrace House 2';

-- #24 Save IDP to shortlist (before/after: the project appears in Customer01's shortlist)
SELECT s.shortlistID, a.username, i.title
FROM shortlist s
JOIN useraccount a ON a.userId = s.customerID
JOIN idp i ON i.projectID = s.projectID
WHERE a.username = 'Customer01' AND i.title = 'Warm Terrace House 2';

-- #25 Search shortlist: expected results for keyword "Cafe"
SELECT i.projectID, i.title, i.category
FROM shortlist s
JOIN useraccount a ON a.userId = s.customerID
JOIN idp i ON i.projectID = s.projectID
WHERE a.username = 'Customer01' AND i.title LIKE '%Cafe%';

-- #26 View shortlisted IDPs: everything Customer01 has saved
SELECT i.projectID, i.title, i.category, i.status
FROM shortlist s
JOIN useraccount a ON a.userId = s.customerID
JOIN idp i ON i.projectID = s.projectID
WHERE a.username = 'Customer01'
ORDER BY i.projectID;

-- =====================================================================
-- INTERIOR DESIGNER - PROJECTS AND ANALYTICS (#27-#38)
-- =====================================================================

-- #27 Create current IDP (before/after: "Modern Kitchen Revamp" appears)
SELECT i.projectID, i.title, i.category, i.status, i.progress, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Current';

-- #28 View current IDPs
SELECT i.projectID, i.title, i.category, i.status, i.progress, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Current';

-- #29 Update current IDP (before/after: progress 72 -> 80)
SELECT i.projectID, i.title, i.status, i.progress, i.stage
FROM idp i
WHERE i.title = 'Family Clinic 1';

-- #30 Delete current IDP (before/after: "Modern Kitchen Revamp" disappears)
SELECT i.projectID, i.title, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Current';

-- #31 Search current IDPs: expected results for keyword "Clinic" with status "Planning"
SELECT i.projectID, i.title, i.status, i.progress
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Current'
  AND i.title LIKE '%Clinic%' AND i.status = 'Planning';

-- #32 Add past IDP (before/after: "Classic Bungalow Makeover" appears)
SELECT i.projectID, i.title, i.category, i.status, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Past';

-- #33 View past IDPs
SELECT i.projectID, i.title, i.category, i.status, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Past';

-- #34 Update past IDP (before/after: description changes)
SELECT i.projectID, i.title, i.description, i.stage
FROM idp i
WHERE i.title = 'Modern Condo 4';

-- #35 Delete past IDP (before/after: "Classic Bungalow Makeover" disappears)
SELECT i.projectID, i.title, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Past';

-- #36 Search past IDPs: expected results for style "Retro"
SELECT i.projectID, i.title, i.category, i.stage
FROM idp i JOIN useraccount a ON a.userId = i.designerID
WHERE a.username = 'ID01' AND i.stage = 'Past' AND i.category = 'Retro';

-- #37 Number of views per IDP (most viewed first)
SELECT i.projectID, i.title, COUNT(v.viewID) AS view_count
FROM idp i
JOIN useraccount a ON a.userId = i.designerID
LEFT JOIN project_views v ON v.projectID = i.projectID
WHERE a.username = 'ID01'
GROUP BY i.projectID, i.title
ORDER BY view_count DESC;

-- #38 Number of times each IDP was shortlisted (most shortlisted first)
SELECT i.projectID, i.title, COUNT(s.shortlistID) AS shortlist_count
FROM idp i
JOIN useraccount a ON a.userId = i.designerID
LEFT JOIN shortlist s ON s.projectID = i.projectID
WHERE a.username = 'ID01'
GROUP BY i.projectID, i.title
ORDER BY shortlist_count DESC;

-- =====================================================================
-- PLATFORM MANAGER (#39-#48)
-- =====================================================================

-- #39 Platform Manager login: PM01 (Active), PM02 (Suspended)
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username IN ('PM01', 'PM02');

-- #40 Platform Manager logout
SELECT a.userId, a.username, p.name, p.type, a.status
FROM useraccount a JOIN userprofile p ON p.username = a.username
WHERE a.username = 'PM01';

-- #41 Create IDP category: "Art Nouveau" does not exist yet (before), "Japandi" already exists (duplicate test)
SELECT categoryID, categoryName, description
FROM category
WHERE categoryName IN ('Art Nouveau', 'Japandi');

-- #42 View IDP category
SELECT categoryID, categoryName, description
FROM category
WHERE categoryName = 'Japandi';

-- #43 Update IDP category (before/after: description changes; "Minimalist" shows the name already taken)
SELECT categoryID, categoryName, description
FROM category
WHERE categoryName IN ('Japandi', 'Minimalist');

-- #44 Delete IDP category: Industrial is unused (can delete), Minimalist is in use (cannot delete)
SELECT c.categoryID, c.categoryName,
       (SELECT COUNT(*) FROM idp i WHERE i.category = c.categoryName) AS projects_using_it
FROM category c
WHERE c.categoryName IN ('Industrial', 'Minimalist');

-- #45 Search IDP categories: expected results for keyword "Kitchen"
SELECT categoryID, categoryName, description
FROM category
WHERE categoryName LIKE '%Kitchen%';

-- #46 Daily report: activity in the last 24 hours (compare with the generated report)
SELECT
  (SELECT COUNT(*) FROM project_views WHERE viewedAt >= NOW() - INTERVAL 1 DAY) AS views,
  (SELECT COUNT(*) FROM shortlist     WHERE createdAt >= NOW() - INTERVAL 1 DAY) AS shortlists,
  (SELECT COUNT(*) FROM idp           WHERE createdAt >= NOW() - INTERVAL 1 DAY) AS new_projects;

-- #47 Weekly report: activity in the last 7 days
SELECT
  (SELECT COUNT(*) FROM project_views WHERE viewedAt >= NOW() - INTERVAL 7 DAY) AS views,
  (SELECT COUNT(*) FROM shortlist     WHERE createdAt >= NOW() - INTERVAL 7 DAY) AS shortlists,
  (SELECT COUNT(*) FROM idp           WHERE createdAt >= NOW() - INTERVAL 7 DAY) AS new_projects;

-- #48 Monthly report: activity in the last 30 days
SELECT
  (SELECT COUNT(*) FROM project_views WHERE viewedAt >= NOW() - INTERVAL 30 DAY) AS views,
  (SELECT COUNT(*) FROM shortlist     WHERE createdAt >= NOW() - INTERVAL 30 DAY) AS shortlists,
  (SELECT COUNT(*) FROM idp           WHERE createdAt >= NOW() - INTERVAL 30 DAY) AS new_projects;
