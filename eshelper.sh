# How to use
# Step 1: Install library as follow with command: "curl -L -o /usr/bin/jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe"
# Step 2: Run eshelper --help for more information
VERSION=1.0.0
if [ $# -eq 0 ] ;then
printf "Usage: eshelper [--version] [--help] [<agrs>]\n"
      printf "<agrs>:\n
--loop/-l: Total loop to call to elasticsearch\n
--size/-s: Batch size to get for each call"
      exit 0
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --loop*|-l*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      max_loop="${1#*=}"
      ;;
    --size*|-s*)
      if [[ "$1" != *=* ]]; then shift; fi
      size="${1#*=}"
      if [[ $size -gt 10000 || $size -lt 1 ]]
      then 
        printf "size just valid in range 1-10000"
        exit 0
      fi
      ;;
    --version*)
      printf $VERSION
      exit 0
      ;;
    --help|-h)
      printf "Usage: eshelper [--version] [--help] [<agrs>]\n"
      printf "<agrs>:\n
--loop/-l: Total loop to call to elasticsearch\n
--size/-s: Batch size to get for each call"
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument \nplease run eshelper --help for more infomation"
      exit 1
      ;;
  esac
  shift
done
# Loop to call api
for index in $(seq 1 $max_loop)
do
    echo "Call api $index time(s)"
    if [ $index -eq 1 ]
    then
        request_body="{\"size\": $size, \"query\": {\"match\": {\"shipperOrderId\": \"Perf Test\"}}, \"sort\": [{\"_id\": \"asc\"}], \"_source\": false}"
    else
        LASTIDAFTEREACHCALL=($(tail -1 dispatchId.csv))
        request_body="{\"size\": $size, \"query\": {\"match\": {\"shipperOrderId\": \"Perf Test\"}}, \"sort\": [{\"_id\": \"asc\"}], \"_source\": false, \"search_after\": [ \"$LASTIDAFTEREACHCALL\" ]}"
    fi
    echo $request_body
    response_body=`curl -s --request GET "https://vpc-stage-dss-rodent-ecmfwirrwfiajevc557zxnv36u.us-east-1.es.amazonaws.com/_search" -H "Content-Type: application/json" -d "$request_body"`
    # Get all ids
    ids=`echo $response_body | jq -r '.hits.hits[]._id'`
    # Write result to csv file
    for i in "${ids[@]}"
    do
        echo "$i" >> dispatchId.csv
    done
done
# printf "\n"
# read -p "Execute script finished, press any key to close..."