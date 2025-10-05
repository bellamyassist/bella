import os, re

def guess_requirements(project_dir):
    pkgs = set()
    skip = {'os','sys','json','re','subprocess','typing','pathlib','asyncio','datetime'}
    for root, _, files in os.walk(project_dir):
        for f in files:
            if f.endswith('.py'):
                p = os.path.join(root, f)
                try:
                    txt = open(p, encoding='utf-8').read()
                except:
                    continue
                for m in re.findall(r'^\s*(?:from|import)\s+([a-zA-Z0-9_\.]+)', txt, flags=re.M):
                    top = m.split('.')[0]
                    if top and top not in skip:
                        pkgs.add(top)
    return sorted(pkgs)
