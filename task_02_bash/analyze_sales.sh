#!/bin/bash
export LC_NUMERIC=C

# проверка аргументов
if [ $# -ne 1 ]; then
    echo "нужно указать файл аргументом"
    exit 1
fi

fail_prodazh="$1"

# проверка файла
if [ ! -f "$fail_prodazh" ]; then
    echo "файл не найден"
    exit 1
fi

# инициализация
obshaya_summa=0

declare -A viruchka_po_dnyam
declare -A kolvo_tovara
declare -A summa_po_tovaru

while read -r data den_nedeli tovar cena kolvo; do
    if [[ -z "$data" ]]; then continue; fi

    prodazha=$(echo "$cena * $kolvo" | bc)
    obshaya_summa=$(echo "$obshaya_summa + $prodazha" | bc)

    # агрегируем по дням
    klyuch_den="$data $den_nedeli"
    tekuschaya_viruchka=${viruchka_po_dnyam["$klyuch_den"]:-0}
    viruchka_po_dnyam["$klyuch_den"]=$(echo "$tekuschaya_viruchka + $prodazha" | bc)

    # агрегируем по товарам
    tekuschee_kolvo=${kolvo_tovara["$tovar"]:-0}
    kolvo_tovara["$tovar"]=$(echo "$tekuschee_kolvo + $kolvo" | bc)

    tekuschaya_summa=${summa_po_tovaru["$tovar"]:-0}
    summa_po_tovaru["$tovar"]=$(echo "$tekuschaya_summa + $prodazha" | bc)

done < "$fail_prodazh"

echo "Общая сумма продаж: $obshaya_summa"

# ищем день с макс выручкой
max_viruchka=0
top_den=""

for den in "${!viruchka_po_dnyam[@]}"; do
    tekuschaya=${viruchka_po_dnyam[$den]}
    if (( $(echo "$tekuschaya > $max_viruchka" | bc -l) )); then
        max_viruchka=$tekuschaya
        top_den=$den
    fi
done

# ищем самый популяр товар
max_kolvo=0
pop_tovar=""

for tovar in "${!kolvo_tovara[@]}"; do
    tekuschee_kolvo=${kolvo_tovara[$tovar]}
    if (( $(echo "$tekuschee_kolvo > $max_kolvo" | bc -l) )); then
        max_kolvo=$tekuschee_kolvo
        pop_tovar=$tovar
    fi
done

# достаем сумму по популярному товару для вывода
if [ -n "$pop_tovar" ]; then
    summa_pop_tovara=${summa_po_tovaru[$pop_tovar]}
else
    top_den="нет данных"
    max_viruchka=0
    pop_tovar="нет данных"
    max_kolvo=0
    summa_pop_tovara=0
fi

echo "День с наибольшей выручкой: $top_den (сумма продаж: $max_viruchka)"
echo "Популярный товар: $pop_tovar (количество проданных единиц: $max_kolvo, сумма продаж: $summa_pop_tovara)"
