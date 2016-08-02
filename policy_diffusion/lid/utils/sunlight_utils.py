import os
import re
import string
import tempfile
import importlib
import subprocess



PUNCTUATION = re.compile('[%s]' % re.escape(string.punctuation))


def convert_pdf(filename, type='xml'):
    commands = {'text': ['pdftotext', '-layout', filename, '-'],
            'text-nolayout': ['pdftotext', filename, '-'],
            'xml': ['pdftohtml', '-xml', '-stdout', filename],
            'html': ['pdftohtml', '-stdout', filename]}
    try:
        pipe = subprocess.Popen(commands[type], stdout=subprocess.PIPE,
                close_fds=True).stdout
    except OSError as e:
        raise EnvironmentError("error running %s, missing executable? [%s]" %
                ' '.join(commands[type]), e)
        data = pipe.read()
    pipe.close()
    return data


def pdfdata_to_text(data):
    with tempfile.NamedTemporaryFile(delete=True) as tmpf:
        tmpf.write(data)
        tmpf.flush()
        return convert_pdf(tmpf.name, 'text')


def worddata_to_text(data):
    desc, txtfile = tempfile.mkstemp(prefix='tmp-worddata-', suffix='.txt')
    try:
        with tempfile.NamedTemporaryFile(delete=True) as tmpf:
            tmpf.write(data)
            tmpf.flush()
            subprocess.check_call(['timeout', '10', 'abiword',
                '--to=%s' % txtfile, tmpf.name])
            f = open(txtfile)
            text = f.read()
            tmpf.close()
            f.close()
    finally:
        os.remove(txtfile)
        os.close(desc)
    return text.decode('utf8')


def text_after_line_numbers(lines):
    text = []
    for line in lines.splitlines():
        # real bill text starts with an optional space, line number
        # more spaces, then real text
        match = re.match('\s*\d+\s+(.*)', line)
        if match:
            text.append(match.group(1))

    # return all real bill text joined w/ newlines
    return '\n'.join(text).decode('utf-8', 'ignore')


def plaintext(abbr, doc, doc_bytes):
    # use module to pull text out of the bytes
    module = importlib.import_module(abbr)
    text = module.extract_text(doc, doc_bytes)

    if not text:
        return

    if isinstance(text, unicode):
        text = text.encode('ascii', 'ignore')
    else:
        text = text.decode('utf8', 'ignore').encode('ascii', 'ignore')
    text = text.replace(u'\xa0', u' ')  # nbsp -> sp
    text = PUNCTUATION.sub(' ', text)   # strip punctuation
    text = re.sub('\s+', ' ', text)     # collapse spaces
    return text


