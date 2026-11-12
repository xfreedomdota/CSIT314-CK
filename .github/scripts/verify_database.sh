#!/usr/bin/env bash
# Checks that the schema + test data imported correctly into MySQL and match what the report expects.
set -u
export MYSQL_PWD="${DB_PASS:-}"   # password via env var, so no warning text mixes into results
MYSQL="mysql -h ${DB_HOST:-127.0.0.1} -u ${DB_USER:-root} -N -B ${DB_NAME:-interior_design}"
PASS=0; FAIL=0
expect() { # description  sql  expected
  local got; got=$($MYSQL -e "$2" 2>&1)
  if [ "$got" = "$3" ]; then PASS=$((PASS+1)); echo "  PASS  $1 = $got"
  else FAIL=$((FAIL+1)); echo "  FAIL  $1: expected '$3', got '$got'"; fi
}

echo "== 100 records for each data type"
expect "Interior designers"  "SELECT COUNT(*) FROM userprofile WHERE type='Interior Designer'" 100
expect "Companies"           "SELECT COUNT(*) FROM company"        100
expect "Categories"          "SELECT COUNT(*) FROM category"       100
expect "Projects (IDP)"      "SELECT COUNT(*) FROM idp"            100
expect "Shortlists"          "SELECT COUNT(*) FROM shortlist"      100
expect "Project views"       "SELECT COUNT(*) FROM project_views"  100
expect "User accounts"       "SELECT COUNT(*) FROM useraccount"    111

echo "== Business rules"
expect "One company per designer"   "SELECT COUNT(*) FROM (SELECT designerID FROM company GROUP BY designerID HAVING COUNT(*)>1) d" 0
expect "Every account has a profile" "SELECT COUNT(*) FROM useraccount a LEFT JOIN userprofile p ON p.username=a.username WHERE p.username IS NULL" 0
expect "Progress between 0 and 100" "SELECT COUNT(*) FROM idp WHERE progress<0 OR progress>100" 0
expect "No duplicate shortlists"    "SELECT COUNT(*) FROM (SELECT customerID,projectID FROM shortlist GROUP BY customerID,projectID HAVING COUNT(*)>1) d" 0

echo "== Accounts used in the report's test cases"
for u in admin01 ID01 Customer01 PM01; do expect "$u is Active"    "SELECT status FROM useraccount WHERE username='$u'" Active; done
for u in admin02 ID02 Customer02 PM02; do expect "$u is Suspended" "SELECT status FROM useraccount WHERE username='$u'" Suspended; done

echo "== The 48 test data queries in the report all run"
if $MYSQL < Database/test_data_queries.sql > /dev/null; then PASS=$((PASS+1)); echo "  PASS  test_data_queries.sql ran without errors"
else FAIL=$((FAIL+1)); echo "  FAIL  test_data_queries.sql has an error"; fi

echo; echo "Database check: $PASS passed, $FAIL failed"
[ -n "${GITHUB_STEP_SUMMARY:-}" ] && echo "### Database check: $PASS passed, $FAIL failed" >> "$GITHUB_STEP_SUMMARY"
[ "$FAIL" -eq 0 ]
