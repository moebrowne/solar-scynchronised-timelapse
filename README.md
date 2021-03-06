# Solar Synchronised Timelapse

A simple script that takes a picture every day at solar noon.

- It uses `raspistill` to actually take the picture but any command can be used.
- It outputs files named using an ISO-8601 date: `YYYY-MM-DD.jpg` (use `--nameFormat` to customise this).


# Example

```
./timelapse.sh --lat 19.717586 --lon -155.547864
```


# Arguments

```
-d --directory
    Directory to store images in (default: '.')

--lat
    Latitude of current position. If omitted geolocation will be attempted

-r --retries
    Maximum number of times to retry fetching solar noon date (default: '6')

--lon
    Longitude of current position. If omitted geolocation will be attempted

-h --help
    Show this help message

-f --nameFormat
    Format of image file names. Uses standard date formatting (default: '%Y-%m-%d.jpg')
```

# Exit Codes

```
10  Image storage directory is not a directory
11  Image storage directory is not writable
20  Unable to do geolocation
30  Solar noon fetch retry count exceeded
```

# SystemD Service

It's a good idea to run this as a service so if the script is killed for any reason it is restarted and can be set to start on boot.

To do both these things simply copy the included `solarTimelapse.service` file to `/etc/systemd/system/solarTimelapse.service` and run:

```
systemctl start solarTimelapse
systemctl enable solartTimelapse
```

*Note this service is assuming you have cloned the code to `/home/pi/solar-scynchronised-timelapse`*

# 3rd Parties

- Uses [sunrise-sunset.org](https://sunrise-sunset.org) to fetch the solar noon time
- Uses [ip-api.com](https://ip-api.com/) to do IP based geolocation. *This will be skipped if `--lat` and `--lon` are passed*