#!/usr/bin/env python3
"""批次檢查repo所有package.mk裡PKG_URL的外部來源存活狀態。

目的：GitHub Actions雲端runner的IP(資料中心網段)常被部分小型鏡像站的WAF/
防護機制擋掉，即使從一般網路(如開發用VM)測試完全正常，雲端建置卻404/403
(dialog/wsdd2/usb-modeswitch都踩過這個坑)。這支腳本設計成在GitHub Actions
runner本身執行，才能真實反映雲端建置實際會遇到的網路狀況，不要在別的網路
環境(VM/本機)執行後就當作結果準確。

只做靜態文字比對+簡單${VAR}替換(不執行/source整個package.mk，因為很多
package.mk依賴build-time才會設定的變數如${ARCH}/${DEVICE}/${OPENGLES}，
貿然執行有風險且容易產生誤判)。能解析出完整URL的才檢查，解析不出來的
(還殘留未替換的${...})另外列出，不當作死link處理，避免誤報。
"""
import concurrent.futures
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else ".")

VAR_RE = re.compile(r'^(PKG_NAME|PKG_VERSION|PKG_SITE|PKG_URL|PKG_GIT_CLONE_BRANCH)="([^"]*)"', re.M)
PLACEHOLDER_RE = re.compile(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}')


def resolve_url(pkgmk_text):
    """從單一package.mk文字裡抓PKG_URL並做簡單變數替換，回傳(url_or_none, unresolved_bool)"""
    vars_found = {}
    for m in VAR_RE.finditer(pkgmk_text):
        k, v = m.group(1), m.group(2)
        vars_found.setdefault(k, v)

    url = vars_found.get("PKG_URL", "")
    if not url:
        return None, False

    for _ in range(10):
        def sub(m):
            key = m.group(1)
            return vars_found.get(key, m.group(0))
        new_url = PLACEHOLDER_RE.sub(sub, url)
        if new_url == url:
            break
        url = new_url

    unresolved = bool(PLACEHOLDER_RE.search(url))
    return url, unresolved


def check_url(url):
    """用curl做HEAD請求(失敗則GET重試一次)，回傳(ok, detail)"""
    try:
        r = subprocess.run(
            ["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}", "-L",
             "--max-time", "15", "--retry", "1", "-I", url],
            capture_output=True, text=True, timeout=20,
        )
        code = r.stdout.strip()
        if code.startswith("2") or code.startswith("3"):
            return True, code
    except Exception:
        pass

    try:
        r = subprocess.run(
            ["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}", "-L",
             "--max-time", "20", "--retry", "1", "--range", "0-1", url],
            capture_output=True, text=True, timeout=25,
        )
        code = r.stdout.strip()
        if code.startswith("2") or code.startswith("3"):
            return True, code
        return False, code or "no-response"
    except subprocess.TimeoutExpired:
        return False, "timeout"
    except Exception as e:
        return False, f"error:{e}"


def main():
    pkgmk_files = sorted(REPO_ROOT.glob("**/package.mk"))
    print(f"找到 {len(pkgmk_files)} 個 package.mk", file=sys.stderr)

    entries = []
    unresolved_entries = []
    skip_no_url = 0

    for f in pkgmk_files:
        try:
            text = f.read_text(errors="ignore")
        except Exception:
            continue
        url, unresolved = resolve_url(text)
        if not url:
            skip_no_url += 1
            continue
        if unresolved:
            unresolved_entries.append((str(f.relative_to(REPO_ROOT)), url))
            continue
        if not url.startswith(("http://", "https://")):
            continue
        entries.append((str(f.relative_to(REPO_ROOT)), url))

    print(f"可靜態解析的URL: {len(entries)}；含未解析變數(略過不查): {len(unresolved_entries)}；無PKG_URL: {skip_no_url}", file=sys.stderr)

    url_to_paths = {}
    for path, url in entries:
        url_to_paths.setdefault(url, []).append(path)

    unique_urls = list(url_to_paths.keys())
    print(f"去重後待檢查URL數: {len(unique_urls)}", file=sys.stderr)

    dead = []
    ok_count = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
        futs = {ex.submit(check_url, u): u for u in unique_urls}
        done = 0
        for fut in concurrent.futures.as_completed(futs):
            u = futs[fut]
            ok, detail = fut.result()
            done += 1
            if done % 50 == 0:
                print(f"  進度 {done}/{len(unique_urls)}", file=sys.stderr)
            if ok:
                ok_count += 1
            else:
                dead.append((u, detail, url_to_paths[u]))

    print(f"\n=== 結果：{ok_count} 正常，{len(dead)} 疑似失效 ===\n")
    for url, detail, paths in sorted(dead, key=lambda x: x[2][0]):
        print(f"[{detail}] {url}")
        for p in paths:
            print(f"    -> {p}")
        print()

    if unresolved_entries:
        print(f"\n=== 另外 {len(unresolved_entries)} 個含未解析變數，未檢查(僅供參考) ===\n")
        for p, u in unresolved_entries:
            print(f"{p}: {u}")

    # 有失效項目時讓workflow顯示為失敗，方便一眼看出需要處理
    if dead:
        sys.exit(1)


if __name__ == "__main__":
    main()
