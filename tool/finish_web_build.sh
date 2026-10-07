#!/usr/bin/env bash
# Prepares build/web (after `flutter build web --no-web-resources-cdn`) for
# GitHub Pages; used by .github/workflows/deploy-web.yml. Usage:
#   tool/finish_web_build.sh <build-id> [build/web]
#
# - A relative base, so the same bundle works at the custom domain and the
#   older github.io address (routes are hash-based).
# - build.json carries the build id: an open or installed app sees a newer
#   build and offers to reload (lib/core/update). The id also goes into the
#   script addresses, so a reload can't keep running a cached older copy.
# - The offline copy (web/sw.js) gets this build's id, the engine revision and
#   the list of asset files to keep.
set -euo pipefail
BUILD_ID="$1"
WEB="${2:-build/web}"

sed -i 's#<base href="/">#<base href="./">#' "$WEB/index.html"
grep -q '<base href="./">' "$WEB/index.html"

printf '{"build":"%s"}\n' "$BUILD_ID" > "$WEB/build.json"
for f in flutter_bootstrap.js install_prompt.js offline.js; do
  sed -i "s#src=\"$f\"#src=\"$f?v=$BUILD_ID\"#" "$WEB/index.html"
  grep -q "src=\"$f?v=$BUILD_ID\"" "$WEB/index.html"
done
sed -i "s#\"mainJsPath\":\"main.dart.js\"#\"mainJsPath\":\"main.dart.js?v=$BUILD_ID\"#" "$WEB/flutter_bootstrap.js"
grep -q "main.dart.js?v=$BUILD_ID" "$WEB/flutter_bootstrap.js"

# The engine must come from this site (built with --no-web-resources-cdn).
grep -q '"useLocalCanvasKit":true' "$WEB/flutter_bootstrap.js"
ENGINE=$(grep -o '"engineRevision":"[0-9a-f]*"' "$WEB/flutter_bootstrap.js" | cut -d'"' -f4)
[ -n "$ENGINE" ]
ASSETS=$(cd "$WEB" && find assets -type f ! -name NOTICES | sort)
python3 - "$WEB/sw.js" "$BUILD_ID" "$ENGINE" "$ASSETS" <<'PY'
import json, sys
path, build, engine, assets = sys.argv[1:5]
s = open(path).read()
for old, new in [
    ("const BUILD = 'dev';", f"const BUILD = '{build}';"),
    ("const ENGINE = 'dev';", f"const ENGINE = '{engine}';"),
    ("const ASSETS = [];", "const ASSETS = " + json.dumps([a for a in assets.split("\n") if a]) + ";"),
]:
    assert s.count(old) == 1, old
    s = s.replace(old, new)
open(path, "w").write(s)
PY
grep -q "const BUILD = '$BUILD_ID';" "$WEB/sw.js"
grep -q 'const ASSETS = \["assets/' "$WEB/sw.js"
echo "web build $BUILD_ID ready (engine $ENGINE)"
