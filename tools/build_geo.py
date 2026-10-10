import io
import json
import os
import urllib.request
import zipfile

BASE = "https://download.geonames.org/export/dump/"
OUT = "assets/geo"
TMP = "/tmp/geo"

CODES = """SA AE QA KW BH OM YE IQ SY LB JO PS EG SD LY TN DZ MA MR SO DJ KM
TR IR PK AF BD ID MY BN MV SN ML NE TD NG GM GN SL BF CI GH ET ER KE TZ UG
AZ KZ UZ TM TJ KG AL XK BA LK IN CN
DE FR GB ES IT NL BE CH AT SE NO DK FI IE PT GR PL CZ HU RO BG RS HR SI SK
UA RU LU IS MK ME MD BY LT LV EE CY MT
US CA AU NZ ZA BR AR MX JP KR SG TH PH VN MM""".split()

# الدول الكبيرة جداً: نكتفي بالأماكن التي سكانها 3000 فأكثر
BIG = set("""IN CN US RU BR MX JP KR PH VN TH MM DE FR GB IT ES PL UA AR CA AU
ID BD NG PK TR IR ZA KZ ET KE TZ UG GH CI""".split())
BIG_MIN_POP = 3000


def download(name):
    os.makedirs(TMP, exist_ok=True)
    path = os.path.join(TMP, name)
    if not os.path.exists(path):
        print("downloading", name, flush=True)
        urllib.request.urlretrieve(BASE + name, path)
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    wanted = set(CODES)

    # 1) الولايات والمحافظات
    admin = {}
    with open(download("admin1CodesASCII.txt"), encoding="utf-8") as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) < 4:
                continue
            cc, _, code = p[0].partition(".")
            if cc in wanted:
                admin.setdefault(cc, {})[code] = [p[1], p[3]]

    # 2) الأماكن
    places = {}
    ids = set()
    with zipfile.ZipFile(download("cities500.zip")) as z:
        with z.open("cities500.txt") as raw:
            for line in io.TextIOWrapper(raw, encoding="utf-8"):
                p = line.rstrip("\n").split("\t")
                if len(p) < 18:
                    continue
                cc = p[8]
                if cc not in wanted:
                    continue
                try:
                    pop = int(p[14] or 0)
                except ValueError:
                    pop = 0
                if cc in BIG and pop < BIG_MIN_POP:
                    continue
                gid = p[0]
                places.setdefault(cc, []).append(
                    [gid, p[1], round(float(p[4]), 4), round(float(p[5]), 4),
                     p[10], pop, p[17]]
                )
                ids.add(gid)
    for cc in admin:
        for code in admin[cc]:
            ids.add(admin[cc][code][1])
    print("places:", sum(len(v) for v in places.values()), flush=True)

    # 3) الأسماء العربية
    best = {}
    with zipfile.ZipFile(download("alternateNamesV2.zip")) as z:
        name = next(n for n in z.namelist()
                    if n.startswith("alternateNamesV2") and n.endswith(".txt"))
        with z.open(name) as raw:
            for line in io.TextIOWrapper(raw, encoding="utf-8"):
                p = line.rstrip("\n").split("\t")
                if len(p) < 8 or p[2] != "ar":
                    continue
                gid = p[1]
                if gid not in ids or p[7] == "1" or not p[3]:
                    continue
                score = (0 if p[4] == "1" else 1,
                         1 if p[6] == "1" else 0,
                         len(p[3]))
                cur = best.get(gid)
                if cur is None or score < cur[0]:
                    best[gid] = (score, p[3])

    def ar_name(gid):
        v = best.get(gid)
        return v[1] if v else ""

    # 4) كتابة الملفات
    done = []
    for cc in sorted(wanted):
        lst = places.get(cc)
        if not lst:
            continue
        zones = []
        zidx = {}
        rows = []
        for gid, latin, lat, lng, a1, pop, tzn in lst:
            if tzn not in zidx:
                zidx[tzn] = len(zones)
                zones.append(tzn)
            rows.append([ar_name(gid), latin, lat, lng, a1, pop, zidx[tzn]])
        used = set(r[4] for r in rows)
        adm = {}
        for code, v in admin.get(cc, {}).items():
            if code in used:
                adm[code] = [ar_name(v[1]), v[0]]
        data = {"z": zones, "a": adm, "p": rows}
        with open(os.path.join(OUT, cc + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        done.append(cc)

    with open(os.path.join(OUT, "index.json"), "w", encoding="utf-8") as f:
        json.dump(done, f)
    print("done:", len(done), "countries", flush=True)


main()
