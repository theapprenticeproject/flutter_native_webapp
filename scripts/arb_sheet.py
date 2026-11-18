#!/usr/bin/env python3
"""Translation sheet for the app text (lib/l10n/*.arb). Standard library only.

  python3 scripts/arb_sheet.py export texts.xlsx   # app_en.arb (+ saved translations) -> sheet
  python3 scripts/arb_sheet.py import texts.xlsx   # sheet -> app_hi/kn/mr/pa.arb
  python3 scripts/arb_sheet.py selftest

A translator fills the language columns. A text left empty stays English in the
app. A text whose {placeholders} differ from English is rejected and reported.
"""
import json, os, re, sys, tempfile, zipfile
from xml.sax.saxutils import escape
import xml.etree.ElementTree as ET

M = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'

L10N = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')
LANGS = [('hi', 'Hindi'), ('kn', 'Kannada'), ('mr', 'Marathi'), ('pa', 'Punjabi')]
HEAD = ['key', 'Where', 'English', 'Notes'] + [n for _, n in LANGS]
WHERE = {'home': 'Home page', 'me': 'Me page', 'project': 'Me page (projects)',
         'gallery': 'Gallery', 'class': 'Activity (cards)', 'chat': 'Activity (TAP Buddy messages)',
         'toast': 'Activity (quiz answer pop-up)', 'settings': 'Settings', 'profile': 'Profile picker',
         'profiles': 'Profile picker', 'welcome': 'Welcome', 'splash': 'Start screen',
         'error': 'Error messages', 'link': 'Opening the link', 'open': 'Opening the link', 'buttons': 'Button', 'toast': 'Activity (quiz answer pop-up)',
         'nav': 'Bottom bar', 'switch': 'Me page and Settings', 'button': 'Button', 'header': 'Page header', 'loading': 'Loading'}
README = [
    'How to fill this sheet',
    'Write the translation in your language column. Leave a cell empty to keep the English text.',
    'Keep words in curly brackets exactly as they are, for example {name}, {points}, {n}. They are replaced by the app.',
    'Keep emoji and line breaks. TAP and TAP Buddy stay as they are.',
    'Buttons are short on purpose. Keep the translation short too.',
    'Some texts change order in other languages. Move the {words} to where they fit your sentence.',
    'Do not change the key and English columns. Save the file as .xlsx.',
]

def load(name):
    p = os.path.join(L10N, f'app_{name}.arb')
    return json.load(open(p, encoding='utf-8')) if os.path.exists(p) else {}

def placeholders(text):
    return sorted(set(re.findall(r'\{(\w+)\}', text)))

def where(key):
    word = re.match(r'[a-z]+', key).group(0)
    return WHERE.get(word, '')

def note(key, en, meta):
    parts = []
    ph = placeholders(en)
    if ph: parts.append('Keep: ' + ', '.join('{%s}' % p for p in ph))
    if '\n' in en: parts.append('Has a line break: keep it')
    d = (meta.get('@' + key) or {}).get('description')
    if d: parts.append(d)
    return '. '.join(parts)

# ---- minimal .xlsx writer and reader ---------------------------------------
def col(n):  # 0 -> A
    s = ''
    n += 1
    while n: n, r = divmod(n - 1, 26); s = chr(65 + r) + s
    return s

def sheet_xml(rows, widths):
    out = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><cols>']
    out += [f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i, w in enumerate(widths)]
    out.append('</cols><sheetData>')
    for r, row in enumerate(rows, 1):
        out.append(f'<row r="{r}">')
        for c, v in enumerate(row):
            if v == '' or v is None: continue
            s = ' s="1"'
            out.append(f'<c r="{col(c)}{r}" t="inlineStr"{s}><is><t xml:space="preserve">{escape(str(v))}</t></is></c>')
        out.append('</row>')
    out.append('</sheetData></worksheet>')
    return ''.join(out)

def write_xlsx(path, texts, readme):
    ns = 'http://schemas.openxmlformats.org/'
    files = {
        '[Content_Types].xml': '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>',
        '_rels/.rels': f'<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="{ns}package/2006/relationships"><Relationship Id="rId1" Type="{ns}officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
        'xl/workbook.xml': f'<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="{ns}spreadsheetml/2006/main" xmlns:r="{ns}officeDocument/2006/relationships"><sheets><sheet name="Texts" sheetId="1" r:id="rId1"/><sheet name="Read me" sheetId="2" r:id="rId2"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels': f'<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="{ns}package/2006/relationships"><Relationship Id="rId1" Type="{ns}officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="{ns}officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/><Relationship Id="rId3" Type="{ns}officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
        'xl/styles.xml': f'<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="{ns}spreadsheetml/2006/main"><fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf></cellXfs></styleSheet>',
        'xl/worksheets/sheet1.xml': sheet_xml(texts, [28, 22, 45, 30, 45, 45, 45, 45]),
        'xl/worksheets/sheet2.xml': sheet_xml([[r] for r in readme], [110]),
    }
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        for n, c in files.items(): z.writestr(n, c)

def read_xlsx(path):
    """Rows of the first sheet as lists of strings (inline or shared strings)."""
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        shared = []
        if 'xl/sharedStrings.xml' in names:
            root = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for si in root.iter(M + 'si'):
                shared.append(''.join(t.text or '' for t in si.iter(M + 't')))
        sheet = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = []
    for row in sheet.iter(M + 'row'):
        cells = {}
        for c in row.iter(M + 'c'):
            letters = re.match(r'[A-Z]+', c.get('r')).group(0)
            idx = 0
            for ch in letters: idx = idx * 26 + ord(ch) - 64
            idx -= 1
            kind = c.get('t')
            if kind == 's': v = shared[int(c.find(M + 'v').text)]
            elif kind == 'inlineStr': v = ''.join(t.text or '' for t in c.iter(M + 't'))
            else:
                v_el = c.find(M + 'v'); v = v_el.text if v_el is not None else ''
            cells[idx] = v or ''
        rows.append([cells.get(i, '') for i in range(max(cells) + 1)] if cells else [])
    return rows

# ---- commands --------------------------------------------------------------
def export(path):
    en = load('en')
    keys = [k for k in en if not k.startswith('@')]
    saved = {code: load(code) for code, _ in LANGS}
    rows = [HEAD]
    for k in keys:
        rows.append([k, where(k), en[k], note(k, en[k], en)] + [saved[c].get(k, '') for c, _ in LANGS])
    write_xlsx(path, rows, README)
    print(f'{len(keys)} texts written to {path}')

def convert(rows):
    """Sheet rows -> ({code: {key: text}}, [problems])."""
    en = load('en')
    head = rows[0]
    problems, result = [], {}
    for code, name in LANGS:
        if name not in head: continue
        ci = head.index(name)
        out = {}
        for n, row in enumerate(rows[1:], 2):
            key = row[0] if row else ''
            text = row[ci] if len(row) > ci else ''
            if not text.strip(): continue
            if key not in en or key.startswith('@'):
                problems.append(f'row {n}: unknown key {key!r}'); continue
            if placeholders(text) != placeholders(en[key]):
                problems.append(f'{name} row {n} {key}: placeholders {placeholders(text)} should be {placeholders(en[key])}')
                continue
            out[key] = text
        result[code] = out
    return result, problems

def import_(path):
    result, problems = convert(read_xlsx(path))
    en = load('en')
    order = [k for k in en if not k.startswith('@') and k in en]
    for code, texts in result.items():
        arb = {'@@locale': code}
        arb.update({k: texts[k] for k in order if k in texts})
        with open(os.path.join(L10N, f'app_{code}.arb'), 'w', encoding='utf-8') as f:
            json.dump(arb, f, indent=2, ensure_ascii=False); f.write('\n')
        print(f'{code}: {len(texts)} of {len(order)} texts translated')
    for p in problems: print('PROBLEM:', p)
    return 1 if problems else 0

def selftest():
    rows = [HEAD, ['navHome', 'Bottom bar', 'Home', '', 'होम', '', '', ''],
            ['classCongratsName', '', 'Congratulations {name}!!!', '', 'बधाई {naam}!', '', '', ''],
            ['chatWonTitle', '', 'a & b <c> "d"\nline 2', '', 'x', '', '', '']]
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 't.xlsx')
        write_xlsx(p, rows, README)
        back = read_xlsx(p)
    assert [r[:5] + [''] * (5 - len(r[:5])) for r in back] == [r[:5] for r in rows], back
    ok, problems = convert(rows)
    assert ok['hi']['navHome'] == 'होम'
    assert 'classCongratsName' not in ok['hi'] and len(problems) == 1, problems
    print('selftest ok')

if __name__ == '__main__':
    cmd, *arg = sys.argv[1:] or ['']
    if cmd == 'export' and arg: export(arg[0])
    elif cmd == 'import' and arg: sys.exit(import_(arg[0]))
    elif cmd == 'selftest': selftest()
    else: print(__doc__); sys.exit(2)
