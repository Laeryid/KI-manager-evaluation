import os
import sys

print("[PATCH] Applying OpenRouter stability and pacing patches to Pi...")

patch_count_retry = 0
patch_count_pacing = 0

for root, dirs, files in os.walk("/usr/local/lib/node_modules/@earendil-works/"):
    for f in files:
        if f.endswith(".js"):
            p = os.path.join(root, f)
            try:
                with open(p, "r", encoding="utf-8") as fp:
                    content = fp.read()
                
                modified = False
                
                # 1. Patch retry pattern to recognize 'provider finish_reason' from OpenRouter
                target_retry = '"provider.?returned.?(?:an.?)?error"'
                if target_retry in content and '"provider.?finish_reason"' not in content:
                    content = content.replace(
                        target_retry,
                        '"provider.?returned.?(?:an.?)?error","provider.?finish_reason"'
                    )
                    modified = True
                    patch_count_retry += 1
                    print(f"  -> Patched retry pattern in: {p}")
                
                # 2. Add 0.5s rate-limit pacing before API calls to OpenRouter
                target_pacing = "const { data: openaiStream, response } = await retryProviderRequest("
                if target_pacing in content and "setTimeout(r, 500)" not in content:
                    content = content.replace(
                        target_pacing,
                        "await new Promise(r => setTimeout(r, 500));\n            " + target_pacing
                    )
                    modified = True
                    patch_count_pacing += 1
                    print(f"  -> Patched API pacing in: {p}")
                
                if modified:
                    with open(p, "w", encoding="utf-8") as fp:
                        fp.write(content)
            except Exception as e:
                print(f"  WARNING: Could not process {p}: {e}")

print(f"[PATCH] Complete. Retry patches applied: {patch_count_retry}, Pacing patches applied: {patch_count_pacing}")
if patch_count_retry == 0:
    print("ERROR: Failed to apply retry patch to any file!", file=sys.stderr)
    sys.exit(1)
