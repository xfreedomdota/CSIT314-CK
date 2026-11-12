#!/usr/bin/env bash
# Smoke test: runs the real web app against the test database and checks that
#  - the public pages load,
#  - each role can log in (valid), is refused with a wrong password, and suspended accounts are refused,
#  - every Boundary page opens for each role without a PHP error.
set -u
BASE="${BASE_URL:-http://127.0.0.1:8000}"
PASS=0; FAIL=0
JAR_DIR=$(mktemp -d)

ok()   { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }
has_php_error() { grep -qE "Fatal error|Parse error|Uncaught|Warning:|Notice:|Deprecated:" "$1"; }

# GET a page, check status code and that no PHP error text appears
check_page() { # name url expected_codes(regex) [cookiejar]
  local name=$1 url=$2 want=$3 jar=${4:-}
  local body; body=$(mktemp)
  local code; code=$(curl -s -o "$body" -w '%{http_code}' ${jar:+-b "$jar"} "$BASE/$url")
  if [[ "$code" =~ ^($want)$ ]] && ! has_php_error "$body"; then ok "$name ($code)"; else
    bad "$name (HTTP $code)"; grep -m3 -E "Fatal error|Parse error|Uncaught|Warning:|Notice:|Deprecated:" "$body" | sed 's/<[^>]*>//g' | cut -c1-200; fi
  rm -f "$body"
}

# POST the login form; returns HTTP code and redirect target
login() { # username password jar
  curl -s -o /dev/null -c "$3" -b "$3" -w '%{http_code} %{redirect_url}' \
       --data-urlencode "username=$1" --data-urlencode "password=$2" \
       "$BASE/Boundary/13_20_39_LoginPage.php"
}

echo "== Public pages"
check_page "Entry page index.html"   "index.html"                    "200"
check_page "Home page"               "Boundary/home.html"            "200"
check_page "Login page"              "Boundary/13_20_39_LoginPage.php" "200"
check_page "Dashboard without login redirects" "Boundary/Dashboard.php" "302"

echo "== Login checks (User Stories #1, #13, #20, #39)"
for pair in "admin01:admin02:Daniel" "ID01:ID02:Kumar" "Customer01:Customer02:Qi" "PM01:PM02:Tom"; do
  IFS=: read -r active suspended first <<<"$pair"
  jar="$JAR_DIR/$active.txt"

  r=$(login "$active" "Test123!" "$jar")
  if [[ "$r" == 302*Dashboard.php ]]; then ok "$active valid login -> Dashboard"; else bad "$active valid login (got: $r)"; fi

  body=$(curl -s -b "$jar" "$BASE/Boundary/Dashboard.php")
  if grep -q "Welcome back, $first" <<<"$body"; then ok "$active sees 'Welcome back, $first'"; else bad "$active dashboard greeting"; fi

  r=$(login "$active" "wrongpass" "$JAR_DIR/wrong.txt")
  if [[ "$r" == 200* ]]; then ok "$active wrong password refused"; else bad "$active wrong password (got: $r)"; fi
  rm -f "$JAR_DIR/wrong.txt"

  r=$(login "$suspended" "Test123!" "$JAR_DIR/susp.txt")
  if [[ "$r" == 200* ]]; then ok "$suspended (Suspended) refused"; else bad "$suspended suspended login (got: $r)"; fi
  rm -f "$JAR_DIR/susp.txt"
done

echo "== Every Boundary page opens without PHP errors, for every role"
for active in admin01 ID01 Customer01 PM01; do
  jar="$JAR_DIR/$active.txt"
  for f in Boundary/[0-9]*Page.php Boundary/Dashboard.php Boundary/StoryIndex.php; do
    case "$f" in *LogOut*|*LoginPage.php) continue ;; esac   # logout ends the session, login redirects when signed in
    check_page "$active -> $(basename "$f")" "$f" "200|302" "$jar"
  done
done

echo "== Logout (User Stories #2, #14, #21, #40)"
for active in admin01 ID01 Customer01 PM01; do
  jar="$JAR_DIR/$active.txt"
  page="Boundary/14_21_40_LogOutPage.php"; [ "$active" = admin01 ] && page="Boundary/02_UserLogOutPage.php"
  curl -s -o /dev/null -b "$jar" -c "$jar" -X POST "$BASE/$page"   # confirm the logout form
  code=$(curl -s -o /dev/null -w '%{http_code}' -b "$jar" "$BASE/Boundary/Dashboard.php")
  if [ "$code" = 302 ]; then ok "$active logged out, dashboard now redirects to login"; else bad "$active logout (dashboard HTTP $code)"; fi
done

echo
echo "Smoke test: $PASS passed, $FAIL failed"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "### Smoke test: $PASS passed, $FAIL failed" >> "$GITHUB_STEP_SUMMARY"
fi
[ "$FAIL" -eq 0 ]
