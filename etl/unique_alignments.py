from __future__ import unicode_literals
import io
  

if __name__ == "__main__":

    INFILE = '../data/alignments_new/ncsl_align_text_nosplit.csv'
    OUTFILE = '../data/ncsl/ncsl_unique_align.csv'

    #INFILE = sys.argv[1]
    #OUTFILE = sys.argv[2]
    
    outline = '{count},{text}\n'

    ualign = {}

    with io.open(INFILE, 'r', encoding='utf-8') as infile:


        for line in infile:
            text = line.strip('\n').split(',')[2]
            ualign[text] = ualign.get(text, 0) + 1
        
        
    with io.open(OUTFILE, 'w', encoding='utf-8') as outfile:

        outfile.write(outline.format(text='text', count='count'))

        for e in ualign:
            outfile.write(outline.format(text=e, count=ualign[e]))
