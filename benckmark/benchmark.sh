fio --output-format=json --output=read-4M.json read-4M.fio
fio --output-format=json --output=write-4M.json write-4M.fio

fio --output-format=json --output=random-read-4k.json random-read-4k.fio
fio --output-format=json --output=random-write-4k.json random-write-4k.fio