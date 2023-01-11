#!/bin/bash
# Copyright (C) 2021-2023 Luca Gasperini
#
# This file is part of Twitch Data Script
#
# Twitch Data Script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# Twitch Data Script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Twitch Data Script.  If not, see <http://www.gnu.org/licenses/>.

dir=$1
user=$2
csv=$3

dir_revenue="${dir}/twitch-payouts/all_revenues"

total=0

resolve_api="https://api.ivr.fi/twitch/resolve"

LC_NUMERIC="C"

if [ -n "${csv}" ]; then
    if >> ${csv} ; then
        echo "month;revenue" > "${csv}"
    else
        printf "CANNOT WRITE INTO ${csv}\n"
        unset csv
    fi
fi

if [[ $user =~ ^[0-9]+$ ]] ; then #if an id
    name=$(curl -s ${resolve_api}/${user}?id=true | jq -r '.displayName')
    id=${user}
else #if a user name
    name=${user}
    id=$(curl -s ${resolve_api}/${user}| jq -r '.id')
fi

printf "SEARCHING \"${name}\" ID:${id}\n"

for dir_year in ${dir_revenue}/*; do
    for dir_month in ${dir_year}/*; do
        dir_list=(${dir_month}/*)
        dir_table=${dir_list[-1]}
        gzip="${dir_table}/all_revenues.csv.gz"
        if [ -f "$gzip" ]; then
            revenue=$(zcat "$gzip" | awk -F "\"*,\"*" -v id="${id}" '$1 == id { sum = $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11; } END { print sum; }')
            month=$(basename "${dir_month}")
            year=$(basename "${dir_year}")
        fi
        if [ -n "${revenue}" ]; then
            if [ -n "${csv}" ]; then
                echo "${year}/${month};${revenue}" >> $csv
            else
                printf "${year}/${month} ${revenue}$\n"
                total=$(awk "BEGIN{ printf \"%.2f\", $total + $revenue }")
            fi
        fi
    done
done

if ! [ -n "${csv}" ]; then
    printf "TOTAL $total$\n"
fi
