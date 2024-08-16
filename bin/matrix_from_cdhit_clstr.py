from collections import defaultdict
import sys

def main():

    cluster_dict = defaultdict()
    samples_name = []

    with open(sys.argv[1], "r", encoding="utf-8") as clstr_in:
        for line in clstr_in:
            if line.startswith(">"):
                entry_name = line.split()[0].split('>')[1]+'_'+line.split()[1].lower()
                cluster_dict[entry_name] = []
                current_cluster = entry_name.lower()
            else:
                sample_id = (line.split()[2].split('|')[0])[1:]
                cluster_dict[entry_name].append(sample_id)
                if sample_id not in samples_name:
                    samples_name.append(sample_id)

    colnames = ["cluster_id"] + sorted(samples_name)
    print("\t".join(colnames))

    for entry in cluster_dict:
        line_start = str(entry).lower()
        line_content = ""
        line_total = 0
        for name in samples_name:
            if name in cluster_dict[entry]:
                line_content = line_content + "\t" + str(cluster_dict[entry].count(name))
                line_total += 1
            else:
                line_content += '\t0'
        line = line_start + line_content
        print(line)

if __name__ == "__main__":
    main()