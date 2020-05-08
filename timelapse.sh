#!/usr/bin/env bash

declare -A argExpected
argExpected['lat']="latitude; Latitude of current position. If omitted geolocation will be attempted"
argExpected['lon']="longitude; Longitude of current position. If omitted geolocation will be attempted"
argExpected['d|directory']="saveLocation=.; Directory to store images in"
argExpected['f|nameFormat']="nameFormat=%Y-%m-%d.jpg; Format of image file names. Uses standard date formatting"
argExpected['h|help']="showHelp; Show this help message"
argExpected['r|retries']="maxRetries=6; Maximum number of times to retry fetching solar noon date"

source ./libs/argument-parser.sh

argPassed 'showHelp' && { echo "$(argList)"; exit 0; }


[[ -d "$(argValue "saveLocation")" ]] || { echo "$(argValue "saveLocation") is not a directory"; exit 10; }
[[ -w "$(argValue "saveLocation")" ]] || { echo "$(argValue "saveLocation") is not writeable"; exit 11; }

echo "> Images will be saved to: $(argValue "saveLocation")/$(date "+$(argValue "nameFormat")")"

POS_LAT="$(argValue "latitude")"
POS_LON="$(argValue "longitude")"

if [[ "${POS_LAT}${POS_LON}" = "" ]]; then
    echo "> No position given, attempting geolocation..."
    LOCATION_DATA="$(curl -s "http://ip-api.com/json/?fields=status,lat,lon")"

    if [[ "$(jq -r .status <<< "$LOCATION_DATA")" != "success" ]]; then
        echo "! Unable to do geolocation"

        exit 20;
    fi

    POS_LAT="$(jq .lat <<< "$LOCATION_DATA")"
    POS_LON="$(jq .long <<< "$LOCATION_DATA")"
fi

NEXT_NOON_DAY="$(date --iso-8601)"
TIME_DATA_FETCH_RETRIES=0

while :; do
    echo "> Fetching solar noon data for ${NEXT_NOON_DAY}..."
    TIME_DATA="$(curl -s "https://api.sunrise-sunset.org/json?lat=${POS_LAT}&lng=${POS_LON}&formatted=0&date=${NEXT_NOON_DAY}")"

    if [[ "$(jq -r .status <<< "$TIME_DATA" 2> /dev/null)" != "OK" ]]; then
        echo "! Unable to get time data, response was: ${TIME_DATA}"

        [[ $TIME_DATA_FETCH_RETRIES -ge "$(argValue "maxRetries")" ]] && { echo "! Max retries exceeded"; exit 30; }

        ((TIME_DATA_FETCH_RETRIES++))

        RETRY_TIME="$(( 4 ** $TIME_DATA_FETCH_RETRIES ))"

        echo "! Retrying in ${RETRY_TIME} seconds..."
        sleep ${RETRY_TIME}
        continue;
    fi

    TIME_DATA_FETCH_RETRIES=0

    SOLAR_NOON_DATE="$(jq -r .results.solar_noon <<< "$TIME_DATA")"
    SOLAR_NOON_EPOCH="$(date -d "${SOLAR_NOON_DATE}" +%s)"

    echo "> Solar noon for ${NEXT_NOON_DAY} is at $(date -d "${SOLAR_NOON_DATE}" +"%H:%M:%S (%Z)"). Sleeping until then..."

    while :; do
        SOLAR_NOON_SECONDS_FROM_NOW="$(( ${SOLAR_NOON_EPOCH} - $(date +%s) ))"

        if [[ $SOLAR_NOON_SECONDS_FROM_NOW -lt 0 ]]; then
            NEXT_NOON_DAY="$(date -d "$NEXT_NOON_DAY + 1 day" --iso-8601)";
            echo "! We missed it! Trying ${NEXT_NOON_DAY}"
            continue 2;
        fi

        [[ $SOLAR_NOON_SECONDS_FROM_NOW -gt 0 ]] && sleep $(( $SOLAR_NOON_SECONDS_FROM_NOW / 2 )) || break;
    done

    echo "> Taking picture..."
    raspistill --rotation 180 -o "$(argValue "saveLocation")/$(date -d "${SOLAR_NOON_DATE}" "+$(argValue nameFormat)")"

    NEXT_NOON_DAY="$(date -d "$NEXT_NOON_DAY + 1 day" --iso-8601)";
done